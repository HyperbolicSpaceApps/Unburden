import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:unburden_app/core/groq_llm_client.dart';
import 'package:unburden_app/features/chat/domain/chat_prompt_builder.dart';

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
        storedGroceryItems: [],
      );

      final raw = await llm.complete(systemPrompt, [
        {'role': 'user', 'content': 'where are my comic books?'},
      ]);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final answer = decoded['message'].toString();

      // LLM judge
      final judgePrompt =
          '''
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
        storedGroceryItems: ['milk', 'potatoes'],
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
      final systemPrompt = buildChatPrompt(storedLocationSummaries: [], storedGroceryItems: []);

      final raw = await llm.complete(systemPrompt, [
        {'role': 'user', 'content': 'xzqwpfj'},
      ]);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final message = decoded['message']?.toString() ?? '';

      expect(message, contains("I didn't understand"));
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
        storedGroceryItems: ['milk', 'potatoes'],
        toolRules: {
          'grocery': ['when I say "grocery", always show my current list'],
        },
      );

      final raw = await llm.complete(systemPrompt, [
        {'role': 'user', 'content': 'grocery'},
      ]);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final message = decoded['message']?.toString() ?? '';

      final judgePrompt =
          '''
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

    test('resolves "yes" to add_items when prior turn asked about a grocery item', () async {
      const apiKey = String.fromEnvironment('UNBURDEN_GROQ_API_KEY');
      if (apiKey.isEmpty) {
        markTestSkipped('UNBURDEN_GROQ_API_KEY not set');
        return;
      }

      final llm = GroqLlmClient(apiKey: apiKey);
      final systemPrompt = buildChatPrompt(storedLocationSummaries: [], storedGroceryItems: []);

      final raw2 = await llm.complete(systemPrompt, [
        {'role': 'user', 'content': 'I was thinking about mayo'},
        {
          'role': 'assistant',
          'content': 'I did not understand. Do you want to add "mayo" to grocery list?',
        },
        {'role': 'user', 'content': 'yes'},
      ]);
      final decoded2 = jsonDecode(raw2) as Map<String, dynamic>;

      expect(decoded2['action'], equals('add_items'));
      final items = decoded2['items'] as List<dynamic>;
      expect(items.any((i) => (i['name'] as String).toLowerCase().contains('mayo')), isTrue);
    });
  });
}
