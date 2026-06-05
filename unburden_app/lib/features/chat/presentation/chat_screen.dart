import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:unburden_app/core/llm_client.dart';
import 'package:unburden_app/features/chat/domain/chat_prompt_builder.dart';
import 'package:unburden_app/features/chat/domain/confirmation_builder.dart';
import 'package:unburden_app/features/chat/domain/list_tool.dart';
import 'package:unburden_app/features/chat/domain/list_tool_prompt_builder.dart';
import 'package:unburden_app/features/where_is_it/data/where_is_it_repository_interface.dart';
import 'package:unburden_app/features/where_is_it/domain/storage_location.dart';

class ChatScreen extends StatefulWidget {
  final LlmClient llm;
  final WhereIsItRepositoryInterface whereIsItRepository;
  final List<ListTool> listTools;

  const ChatScreen({
    super.key,
    required this.llm,
    required this.whereIsItRepository,
    required this.listTools,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_Message> _messages = [];
  final List<Map<String, String>> _history = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _messages.add(_Message(text: "welcome to Unburden. what's up?", isUser: false));
  }

  Future<void> _onSend() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _messages.add(_Message(text: input, isUser: true));
      _loading = true;
    });
    _controller.clear();

    final locations = await widget.whereIsItRepository.getAll();
    final listSections = <String>[];
    for (final tool in widget.listTools) {
      final items = await tool.repository.getAll();
      listSections.add(
        buildListToolPrompt(
          listName: tool.name,
          storedItems: items,
          useWhen: tool.promptDescription,
        ),
      );
    }
    final systemPrompt = buildChatPrompt(
      storedLocationSummaries:
          locations.map((l) => '${l.name}: ${l.contents.join(', ')}').toList(),
      listToolSections: listSections,
    );

    _history.add({'role': 'user', 'content': input});

    final String raw;
    try {
      raw = await widget.llm.complete(systemPrompt, _history);
    } catch (e) {
      _history.removeLast();
      if (!mounted) return;
      setState(() {
        _messages.add(_Message(text: 'Error: $e', isUser: false));
        _loading = false;
      });
      return;
    }

    final cleaned = raw
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _Message(text: "Sorry, I couldn't understand. Please try again.", isUser: false),
        );
        _loading = false;
      });
      return;
    }

    final String message;
    try {
      final action = decoded['action'] as String;
      String result;

      if (action == 'save_locations') {
        final rawLocations = decoded['locations'] as List<dynamic>;
        for (final item in rawLocations) {
          final map = item as Map<String, dynamic>;
          final location = StorageLocation(
            name: map['name'] as String,
            contents: (map['contents'] as List<dynamic>).cast<String>(),
          );
          await widget.whereIsItRepository.add(location);
        }
        result = buildConfirmationMessage(
          rawLocations.map((item) => (item as Map<String, dynamic>)['name'] as String).toList(),
        );
      } else if (action == 'add_to_list') {
        final listName = decoded['list'] as String;
        final items = (decoded['items'] as List<dynamic>).cast<String>();
        final tool = widget.listTools.firstWhere(
          (t) => t.name == listName,
          orElse: () => throw Exception('Unknown list: $listName'),
        );
        await tool.repository.addAll(items);
        result = 'added to $listName: ${items.join(', ')}';
      } else if (action == 'remove_from_list') {
        final listName = decoded['list'] as String;
        final items = (decoded['items'] as List<dynamic>).cast<String>();
        final tool = widget.listTools.firstWhere(
          (t) => t.name == listName,
          orElse: () => throw Exception('Unknown list: $listName'),
        );
        if (items.length == 1 && items.first == 'all') {
          await tool.repository.clear();
          result = 'cleared $listName';
        } else {
          result = 'remove of specific items not yet supported';
        }
      } else {
        result = decoded['message'] as String;
      }
      message = result;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_Message(text: 'Error: $e', isUser: false));
        _loading = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _messages.add(_Message(text: message, isUser: false));
      _history.add({'role': 'assistant', 'content': message});
      _loading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return Align(
                    alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: msg.isUser ? Colors.blue[100] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: msg.isUser ? Text(msg.text) : SelectableText(msg.text),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(child: TextField(controller: _controller)),
                  IconButton(icon: const Icon(Icons.send), onPressed: _loading ? null : _onSend),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class _Message {
  final String text;
  final bool isUser;

  _Message({required this.text, required this.isUser});
}
