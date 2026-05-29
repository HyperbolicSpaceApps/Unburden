import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:unburden_app/core/llm_client.dart';
import 'package:unburden_app/features/space_manager/data/space_repository_interface.dart';
import 'package:unburden_app/features/space_manager/domain/storage_location.dart';

class ChatScreen extends StatefulWidget {
  final LlmClient llm;
  final SpaceRepositoryInterface repository;

  const ChatScreen({super.key, required this.llm, required this.repository});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final List<_Message> _messages = [];
  bool _loading = false;

  Future<void> _onSend() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _messages.add(_Message(text: input, isUser: true));
      _loading = true;
    });
    _controller.clear();

    final locations = await widget.repository.getAll();
    final context = locations.isEmpty
        ? 'No locations saved yet.'
        : locations.map((l) => '- ${l.name}: ${l.contents.join(', ')}').join('\n');

    final prompt =
        '''
You are a home space assistant. You help the user manage and optimize their storage spaces.

Current stored locations:
$context

User message: "$input"

Respond ONLY with a valid JSON object, no other text:

If the user is describing storage locations to save:
{
  "action": "save_locations",
  "locations": [
    {
      "name": "short location name",
      "width_cm": 0.0,
      "depth_cm": 0.0,
      "height_cm": 0.0,
      "contents": ["item1", "item2"],
      "access_note": "how hard to reach"
    }
  ],
  "message": "your natural confirmation message"
}

If the user is asking a question or having a conversation:
{
  "action": "answer",
  "message": "your natural response"
}
''';

    final raw = await widget.llm.complete(prompt);

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final action = decoded['action'] as String;
    final message = decoded['message'] as String;

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
        await widget.repository.add(location);
      }
    }

    if (!mounted) return;
    setState(() {
      _messages.add(_Message(text: message, isUser: false));
      _loading = false;
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
                      child: Text(msg.text),
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
}

class _Message {
  final String text;
  final bool isUser;

  _Message({required this.text, required this.isUser});
}
