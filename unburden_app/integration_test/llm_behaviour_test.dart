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
      final prompt = buildChatPrompt(
        userInput: 'where are my comic books?',
        storedLocationSummaries: ['hallway shelf: tools, umbrella'],
        storedGroceryItems: [],
      );

      final raw = await llm.complete(prompt);
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

      final judgeRaw = await llm.complete(judgePrompt);
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
      final prompt = buildChatPrompt(
        userInput: 'grocery',
        storedLocationSummaries: [],
        storedGroceryItems: ['milk', 'potatoes'],
      );

      final raw = await llm.complete(prompt);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final message = decoded['message']?.toString() ?? '';

      final judgePrompt =
          '''
A personal assistant received the message: "grocery"
The current grocery list contains: milk, potatoes.
The assistant responded with: "$message"

Did the assistant show or mention the current grocery list (milk and/or potatoes)?
Respond with only a JSON object: {"showed_list": true} or {"showed_list": false}
''';

      final judgeRaw = await llm.complete(judgePrompt);
      final judgeResult = jsonDecode(judgeRaw) as Map<String, dynamic>;

      expect(judgeResult['showed_list'], isTrue);
    });

    test('returns clarifying response for gibberish input', () async {
      const apiKey = String.fromEnvironment('UNBURDEN_GROQ_API_KEY');
      if (apiKey.isEmpty) {
        markTestSkipped('UNBURDEN_GROQ_API_KEY not set');
        return;
      }

      final llm = GroqLlmClient(apiKey: apiKey);
      final prompt = buildChatPrompt(
        userInput: 'xzqwpfj',
        storedLocationSummaries: [],
        storedGroceryItems: [],
      );

      final raw = await llm.complete(prompt);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final message = decoded['message']?.toString() ?? '';

      final judgePrompt =
          '''
A personal assistant received a gibberish message it could not understand: "xzqwpfj"
The assistant responded with: "$message"

Did the assistant indicate it did not understand, or ask for clarification, rather than acting as if it understood?
Respond with only a JSON object: {"clarified": true} or {"clarified": false}
''';

      final judgeRaw = await llm.complete(judgePrompt);
      final judgeResult = jsonDecode(judgeRaw) as Map<String, dynamic>;

      expect(judgeResult['clarified'], isTrue);
    });

    test('respects tool rule: show grocery list when user says "grocery"', () async {
      const apiKey = String.fromEnvironment('UNBURDEN_GROQ_API_KEY');
      if (apiKey.isEmpty) {
        markTestSkipped('UNBURDEN_GROQ_API_KEY not set');
        return;
      }

      final llm = GroqLlmClient(apiKey: apiKey);
      final prompt = buildChatPrompt(
        userInput: 'grocery',
        storedLocationSummaries: [],
        storedGroceryItems: ['milk', 'potatoes'],
        toolRules: {
          'grocery': ['when I say "grocery", always show my current list'],
        },
      );

      final raw = await llm.complete(prompt);
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

      final judgeRaw = await llm.complete(judgePrompt);
      final judgeResult = jsonDecode(judgeRaw) as Map<String, dynamic>;

      expect(judgeResult['showed_list'], isTrue);
    });
  });
}
