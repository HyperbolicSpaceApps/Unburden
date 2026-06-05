import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:unburden_app/core/groq_llm_client.dart';
import 'package:unburden_app/features/chat/domain/chat_prompt_builder.dart';
import 'package:unburden_app/features/chat/domain/list_tool_prompt_builder.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('LLM behaviour tests', () {
    test('acknowledges when a location is not found without inventing an answer', () async {
      const apiKey = String.fromEnvironment('UNBURDEN_GROQ_API_KEY');
      if (apiKey.isEmpty) {
        markTestSkipped('UNBURDEN_GROQ_API_KEY not set');
        return;
      }

      final llm = GroqLlmClient(apiKey: apiKey);
      final systemPrompt = buildChatPrompt(
        storedLocationSummaries: ['hallway shelf: tools, umbrella'],
        listToolSections: [],
      );

      final raw = await llm.complete(systemPrompt, [
        {'role': 'user', 'content': 'where are my comic books?'},
      ]);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final answer = decoded['message'].toString();

      // LLM judge
      final judgePrompt = '''
A home storage assistant was asked: "where are my comic books?"
The only stored locations are: hallway shelf (tools, umbrella).
The assistant answered: "$answer"

Did the assistant invent a location for the comic books that was not in the stored data?
Respond with only a JSON object: {"invented": true} or {"invented": false}
''';

      final judgeRaw = await llm.complete('', [
        {'role': 'user', 'content': judgePrompt},
      ]);
      final judgeResult = jsonDecode(judgeRaw) as Map<String, dynamic>;

      expect(judgeResult['invented'], isFalse);
    });

    test('shows current grocery list when user says "grocery"', () async {
      const apiKey = String.fromEnvironment('UNBURDEN_GROQ_API_KEY');
      if (apiKey.isEmpty) {
        markTestSkipped('UNBURDEN_GROQ_API_KEY not set');
        return;
      }

      final llm = GroqLlmClient(apiKey: apiKey);
      final systemPrompt = buildChatPrompt(
        storedLocationSummaries: [],
        listToolSections: [
          buildListToolPrompt(listName: 'grocery', storedItems: ['milk', 'potatoes']),
        ],
      );

      final raw = await llm.complete(systemPrompt, [
        {'role': 'user', 'content': 'grocery'},
      ]);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final message = decoded['message']?.toString() ?? '';

      expect(message, contains('milk'));
      expect(message, contains('potatoes'));
    });

    test('returns clarifying response for gibberish input', () async {
      const apiKey = String.fromEnvironment('UNBURDEN_GROQ_API_KEY');
      if (apiKey.isEmpty) {
        markTestSkipped('UNBURDEN_GROQ_API_KEY not set');
        return;
      }

      final llm = GroqLlmClient(apiKey: apiKey);
      final systemPrompt = buildChatPrompt(
        storedLocationSummaries: [],
        listToolSections: [],
      );

      final raw = await llm.complete(systemPrompt, [
        {'role': 'user', 'content': 'xzqwpfj'},
      ]);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;

      expect(decoded['action'], anyOf(equals('clarify'), equals('answer')));
      expect(decoded['message'], isNotNull);
    });

    test('respects tool rule: show grocery list when user says "grocery"', () async {
      const apiKey = String.fromEnvironment('UNBURDEN_GROQ_API_KEY');
      if (apiKey.isEmpty) {
        markTestSkipped('UNBURDEN_GROQ_API_KEY not set');
        return;
      }

      final llm = GroqLlmClient(apiKey: apiKey);
      final systemPrompt = buildChatPrompt(
        storedLocationSummaries: [],
        listToolSections: [
          buildListToolPrompt(
            listName: 'grocery',
            storedItems: ['milk', 'potatoes'],
            toolRules: ['when I say "grocery", always show my current list'],
          ),
        ],
      );

      final raw = await llm.complete(systemPrompt, [
        {'role': 'user', 'content': 'grocery'},
      ]);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final message = decoded['message']?.toString() ?? '';

      final judgePrompt = '''
A personal assistant received the message: "grocery"
It had a user-defined rule: "when I say grocery, always show my current list"
The current grocery list contains: milk, potatoes.
The assistant responded with: "$message"

Did the assistant show the current grocery list (mentioning milk and/or potatoes)?
Respond with only a JSON object: {"showed_list": true} or {"showed_list": false}
''';

      final judgeRaw = await llm.complete('', [
        {'role': 'user', 'content': judgePrompt},
      ]);
      final judgeResult = jsonDecode(judgeRaw) as Map<String, dynamic>;

      expect(judgeResult['showed_list'], isTrue);
    });

    test('returns add_to_list action for thoughts input', () async {
      const apiKey = String.fromEnvironment('UNBURDEN_GROQ_API_KEY');
      if (apiKey.isEmpty) {
        markTestSkipped('UNBURDEN_GROQ_API_KEY not set');
        return;
      }

      final llm = GroqLlmClient(apiKey: apiKey);
      final systemPrompt = buildChatPrompt(
        storedLocationSummaries: [],
        listToolSections: [buildListToolPrompt(listName: 'thoughts', storedItems: [])],
      );

      final raw = await llm.complete(systemPrompt, [
        {'role': 'user', 'content': 'I really loved the sunset today'},
      ]);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;

      expect(decoded['action'], equals('add_to_list'));
      expect(decoded['list'], equals('thoughts'));
    });

    test('returns add_to_list action for grocery input', () async {
      const apiKey = String.fromEnvironment('UNBURDEN_GROQ_API_KEY');
      if (apiKey.isEmpty) {
        markTestSkipped('UNBURDEN_GROQ_API_KEY not set');
        return;
      }

      final llm = GroqLlmClient(apiKey: apiKey);
      final systemPrompt = buildChatPrompt(
        storedLocationSummaries: [],
        listToolSections: [buildListToolPrompt(listName: 'grocery', storedItems: [])],
      );

      final raw = await llm.complete(systemPrompt, [
        {'role': 'user', 'content': 'I need to buy milk'},
      ]);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;

      expect(decoded['action'], equals('add_to_list'));
      expect(decoded['list'], equals('grocery'));
      expect((decoded['items'] as List).join(' ').toLowerCase(), contains('milk'));
    });

    test('returns add_to_list action for todo input', () async {
      const apiKey = String.fromEnvironment('UNBURDEN_GROQ_API_KEY');
      if (apiKey.isEmpty) {
        markTestSkipped('UNBURDEN_GROQ_API_KEY not set');
        return;
      }

      final llm = GroqLlmClient(apiKey: apiKey);
      final systemPrompt = buildChatPrompt(
        storedLocationSummaries: [],
        listToolSections: [buildListToolPrompt(listName: 'todo', storedItems: [])],
      );

      final raw = await llm.complete(systemPrompt, [
        {'role': 'user', 'content': 'add to my todo list: call the dentist'},
      ]);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;

      expect(decoded['action'], equals('add_to_list'));
      expect(decoded['list'], equals('todo'));
      expect((decoded['items'] as List).join(' ').toLowerCase(), contains('dentist'));
    });

    test('returns remove_from_list for removal intent', () async {
      const apiKey = String.fromEnvironment('UNBURDEN_GROQ_API_KEY');
      if (apiKey.isEmpty) {
        markTestSkipped('UNBURDEN_GROQ_API_KEY not set');
        return;
      }

      final llm = GroqLlmClient(apiKey: apiKey);
      final systemPrompt = buildChatPrompt(
        storedLocationSummaries: [],
        listToolSections: [
          buildListToolPrompt(listName: 'todo', storedItems: ['béquille peugeot', 'call dentist']),
        ],
      );

      final raw = await llm.complete(systemPrompt, [
        {'role': 'user', 'content': 'remove all from todo'},
      ]);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      expect(decoded['action'], equals('remove_from_list'));
      expect(decoded['list'], equals('todo'));
    });

    test('"to do X" adds X as a single item, does not split on spaces', () async {
      const apiKey = String.fromEnvironment('UNBURDEN_GROQ_API_KEY');
      if (apiKey.isEmpty) {
        markTestSkipped('UNBURDEN_GROQ_API_KEY not set');
        return;
      }

      final llm = GroqLlmClient(apiKey: apiKey);
      final systemPrompt = buildChatPrompt(
        storedLocationSummaries: [],
        listToolSections: [buildListToolPrompt(listName: 'todo', storedItems: [])],
      );

      final raw = await llm.complete(systemPrompt, [
        {'role': 'user', 'content': 'to do béquille peugeot'},
      ]);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;

      expect(decoded['action'], equals('add_to_list'));
      expect(decoded['list'], equals('todo'));
      final items = decoded['items'] as List<dynamic>;
      expect(items.length, equals(1));
      expect(items[0].toString().toLowerCase(), contains('béquille'));
      expect(items[0].toString().toLowerCase(), contains('peugeot'));
    });

    test('resolves "yes" to add_to_list when prior turn asked about a grocery item', () async {
      const apiKey = String.fromEnvironment('UNBURDEN_GROQ_API_KEY');
      if (apiKey.isEmpty) {
        markTestSkipped('UNBURDEN_GROQ_API_KEY not set');
        return;
      }

      final llm = GroqLlmClient(apiKey: apiKey);
      final systemPrompt = buildChatPrompt(
        storedLocationSummaries: [],
        listToolSections: [buildListToolPrompt(listName: 'grocery', storedItems: [])],
      );

      final raw2 = await llm.complete(systemPrompt, [
        {'role': 'user', 'content': 'I was thinking about mayo'},
        {
          'role': 'assistant',
          'content': 'I did not understand. Do you want to add "mayo" to grocery list?',
        },
        {'role': 'user', 'content': 'yes'},
      ]);
      final decoded2 = jsonDecode(raw2) as Map<String, dynamic>;

      expect(decoded2['action'], equals('add_to_list'));
      expect(decoded2['list'], equals('grocery'));
      final items = decoded2['items'] as List<dynamic>;
      expect(items.any((i) => i.toString().toLowerCase().contains('mayo')), isTrue);
    });
  });
}
