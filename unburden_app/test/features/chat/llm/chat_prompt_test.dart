import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unburden_app/core/capturing_llm_client.dart';
import 'package:unburden_app/features/chat/domain/chat_prompt_builder.dart';
import 'package:unburden_app/features/chat/presentation/chat_screen.dart';
import 'package:unburden_app/features/grocery/data/fake_grocery_repository.dart';
import 'package:unburden_app/features/space_manager/data/fake_space_repository.dart';
import 'package:unburden_app/features/thoughts/data/fake_thought_repository.dart';
import 'package:unburden_app/features/todo/data/fake_todo_repository.dart';

void main() {
  group('Chat Prompt', () {
    test('includes stored locations in context when answering a question', () {
      final prompt = buildChatPrompt(
        storedLocationSummaries: ['hallway shelf: tools, umbrella'],
        storedGroceryItems: [],
        storedTodos: [],
      );

      expect(prompt, contains('hallway shelf'));
      expect(prompt, contains('tools'));
      expect(prompt, contains('umbrella'));
    });

    test('includes grocery tool instructions', () {
      final prompt = buildChatPrompt(storedLocationSummaries: [], storedGroceryItems: [], storedTodos: []);

      expect(prompt, contains('add_to_list'));
      expect(prompt, contains('grocery'));
    });

    test('includes stored grocery items in context', () {
      final prompt = buildChatPrompt(
        storedLocationSummaries: [],
        storedGroceryItems: ['potatoes', 'milk'],
        storedTodos: [],
      );

      expect(prompt, contains('potatoes'));
      expect(prompt, contains('milk'));
    });

    test('includes thoughts tool instructions', () {
      final prompt = buildChatPrompt(storedLocationSummaries: [], storedGroceryItems: [], storedTodos: []);

      expect(prompt, contains('add_thought'));
    });

    test('fallback instructs LLM to suggest possible actions when intent is ambiguous', () {
      final prompt = buildChatPrompt(
        storedLocationSummaries: [],
        storedGroceryItems: ['milk', 'potatoes'],
        storedTodos: [],
      );

      expect(prompt, contains("I didn't understand"));
      expect(prompt, contains('Try:'));
    });

    testWidgets('prompt sent on turn 2 contains prior conversation', (tester) async {
      const turn1Response = '''
{
  "action": "answer",
  "message": "Would you like to add mayo to your grocery list?"
}
''';
      const turn2Response = '''
{
  "action": "add_to_list",
  "list": "grocery",
  "items": ["mayo"]
}
''';

      final llm = CapturingLlmClient(responses: [turn1Response, turn2Response]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            llm: llm,
            spaceRepository: FakeSpaceRepository(),
            groceryRepository: FakeGroceryRepository(),
            thoughtRepository: FakeThoughtRepository(),
            todoRepository: FakeTodoRepository(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'mayo');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'yes');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      final turn2Messages = llm.capturedMessages[1];
      expect(turn2Messages.length, equals(3)); // user:mayo, assistant:clarification, user:yes
      expect(turn2Messages[0], equals({'role': 'user', 'content': 'mayo'}));
      expect(turn2Messages[1]['role'], equals('assistant'));
      expect(turn2Messages[1]['content'], contains('mayo'));
      expect(turn2Messages[2], equals({'role': 'user', 'content': 'yes'}));
    });
  });
}
