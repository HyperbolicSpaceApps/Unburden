import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:unburden_app/core/llm_client.dart';
import 'package:unburden_app/features/chat/domain/chat_prompt_builder.dart';
import 'package:unburden_app/features/chat/domain/confirmation_builder.dart';
import 'package:unburden_app/features/grocery/data/grocery_repository_interface.dart';
import 'package:unburden_app/features/grocery/domain/grocery_item.dart';
import 'package:unburden_app/features/space_manager/data/space_repository_interface.dart';
import 'package:unburden_app/features/space_manager/domain/storage_location.dart';
import 'package:unburden_app/features/thoughts/data/thought_repository_interface.dart';
import 'package:unburden_app/features/thoughts/domain/thought_entry.dart';

class ChatScreen extends StatefulWidget {
  final LlmClient llm;
  final SpaceRepositoryInterface spaceRepository;
  final GroceryRepositoryInterface groceryRepository;
  final ThoughtRepositoryInterface thoughtRepository;

  const ChatScreen({
    super.key,
    required this.llm,
    required this.spaceRepository,
    required this.groceryRepository,
    required this.thoughtRepository,
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

    final locations = await widget.spaceRepository.getAll();
    final groceryItems = await widget.groceryRepository.getAll();
    final systemPrompt = buildChatPrompt(
      storedLocationSummaries: locations.map((l) => '${l.name}: ${l.contents.join(', ')}').toList(),
      storedGroceryItems: groceryItems.map((i) => i.name).toList(),
    );

    _history.add({'role': 'user', 'content': input});

    final String raw;
    try {
      raw = await widget.llm.complete(systemPrompt, _history);
    } catch (e) {
      _history.removeLast(); // don't poison history with failed turns
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
            widthCm: (map['width_cm'] as num?)?.toDouble(),
            depthCm: (map['depth_cm'] as num?)?.toDouble(),
            heightCm: (map['height_cm'] as num?)?.toDouble(),
            contents: (map['contents'] as List<dynamic>).cast<String>(),
            accessNote: map['access_note'] as String? ?? '',
          );
          await widget.spaceRepository.add(location);
        }
        result = buildConfirmationMessage(
          rawLocations.map((item) => (item as Map<String, dynamic>)['name'] as String).toList(),
        );
      } else if (action == 'add_items') {
        final rawItems = decoded['items'] as List<dynamic>;
        for (final item in rawItems) {
          final map = item as Map<String, dynamic>;
          await widget.groceryRepository.add(GroceryItem(name: map['name'] as String));
        }
        final names = rawItems.map((i) => (i as Map<String, dynamic>)['name'] as String).toList();
        result = '${names.join(', ')} added to grocery list';
      } else if (action == 'add_thought') {
        await widget.thoughtRepository.add(ThoughtEntry(text: decoded['text'] as String));
        result = 'thought captured';
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
