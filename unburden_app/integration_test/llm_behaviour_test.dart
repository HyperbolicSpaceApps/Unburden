import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:unburden_app/core/groq_llm_client.dart';
import 'package:unburden_app/features/chat/domain/chat_prompt_builder.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('LLM behaviour tests', () {
    test('splits a shelf with multiple levels into separate locations', () async {
      final apiKey = Platform.environment['UNBURDEN_GROQ_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        markTestSkipped('UNBURDEN_GROQ_API_KEY not set');
        return;
      }

      final llm = GroqLlmClient(apiKey: apiKey);
      final prompt = buildChatPrompt(
        userInput: 'Billy shelf: top level has board games, middle has books, bottom has cables',
        storedLocationSummaries: [],
      );

      final raw = await llm.complete(prompt);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final locations = jsonEncode(decoded['locations']);

      // LLM judge
      final judgePrompt =
          '''
A home storage assistant was asked to save this description:
"Billy shelf: top level has board games, middle has books, bottom has cables"

It produced these locations: $locations

Did it save each physical level as a separate location, resulting in at least 3 distinct locations?
Respond with only a JSON object: {"split_correctly": true} or {"split_correctly": false}
''';

      final judgeRaw = await llm.complete(judgePrompt);
      final judgeResult = jsonDecode(judgeRaw) as Map<String, dynamic>;

      expect(judgeResult['split_correctly'], isTrue);
    });

    test('acknowledges when a location is not found without inventing an answer', () async {
      final apiKey = Platform.environment['UNBURDEN_GROQ_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        markTestSkipped('UNBURDEN_GROQ_API_KEY not set');
        return;
      }

      final llm = GroqLlmClient(apiKey: apiKey);
      final prompt = buildChatPrompt(
        userInput: 'where are my comic books?',
        storedLocationSummaries: ['hallway shelf: tools, umbrella'],
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
  });
}
