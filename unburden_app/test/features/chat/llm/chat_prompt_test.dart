import 'package:flutter_test/flutter_test.dart';
import 'package:unburden_app/features/chat/domain/chat_prompt_builder.dart';

void main() {
  group('Chat Prompt', () {
    test('instructs LLM to split each physical zone into a separate location', () {
      final prompt = buildChatPrompt(
        userInput: 'Billy shelf: top level has board games, middle has books, bottom has cables',
        storedLocationSummaries: [],
      );

      expect(prompt, contains('separate location'));
    });

    test('includes stored locations in context when answering a question', () {
      final prompt = buildChatPrompt(
        userInput: 'where are my comic books?',
        storedLocationSummaries: ['hallway shelf: tools, umbrella'],
      );

      expect(prompt, contains('hallway shelf'));
      expect(prompt, contains('tools'));
      expect(prompt, contains('umbrella'));
    });
  });
}
