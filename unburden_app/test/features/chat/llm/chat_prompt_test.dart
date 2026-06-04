import 'package:flutter_test/flutter_test.dart';
import 'package:unburden_app/features/chat/domain/chat_prompt_builder.dart';

void main() {
  group('Chat Prompt', () {
    // existing tests unchanged
    test('instructs LLM to split each physical zone into a separate location', () {
      final prompt = buildChatPrompt(
        userInput: 'Billy shelf: top level has board games, middle has books, bottom has cables',
        storedLocationSummaries: [],
        storedGroceryItems: [],
      );

      expect(prompt, contains('separate location'));
    });

    test('includes stored locations in context when answering a question', () {
      final prompt = buildChatPrompt(
        userInput: 'where are my comic books?',
        storedLocationSummaries: ['hallway shelf: tools, umbrella'],
        storedGroceryItems: [],
      );

      expect(prompt, contains('hallway shelf'));
      expect(prompt, contains('tools'));
      expect(prompt, contains('umbrella'));
    });

    // new failing tests
    test('includes grocery tool instructions', () {
      final prompt = buildChatPrompt(
        userInput: 'I need potatoes',
        storedLocationSummaries: [],
        storedGroceryItems: [],
      );

      expect(prompt, contains('add_items'));
      expect(prompt, contains('grocery'));
    });

    test('includes stored grocery items in context', () {
      final prompt = buildChatPrompt(
        userInput: 'what do I need to buy?',
        storedLocationSummaries: [],
        storedGroceryItems: ['potatoes', 'milk'],
      );

      expect(prompt, contains('potatoes'));
      expect(prompt, contains('milk'));
    });

    test('includes thoughts tool instructions', () {
      final prompt = buildChatPrompt(
        userInput: 'I like the sunset today',
        storedLocationSummaries: [],
        storedGroceryItems: [],
      );

      expect(prompt, contains('add_thought'));
    });

    test('fallback instructs LLM to suggest possible actions when intent is ambiguous', () {
      final prompt = buildChatPrompt(
        userInput: 'grocery',
        storedLocationSummaries: [],
        storedGroceryItems: ['milk', 'potatoes'],
      );

      expect(prompt, contains("I didn't understand"));
      expect(prompt, contains('Try:'));
    });
  });
}
