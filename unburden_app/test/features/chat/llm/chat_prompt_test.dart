import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unburden_app/core/capturing_llm_client.dart';
import 'package:unburden_app/features/chat/domain/chat_prompt_builder.dart';
import 'package:unburden_app/features/chat/domain/list_tool.dart';
import 'package:unburden_app/features/chat/domain/list_tool_prompt_builder.dart';
import 'package:unburden_app/features/chat/presentation/chat_screen.dart';
import 'package:unburden_app/features/list/data/fake_list_repository.dart';
import 'package:unburden_app/features/where_is_it/data/fake_where_is_it_repository.dart';

void main() {
  group('Chat Prompt', () {
    test('includes stored locations in context when answering a question', () {
      final prompt = buildChatPrompt(
        storedLocationSummaries: ['hallway shelf: tools, umbrella'],
        listToolSections: [],
      );

      expect(prompt, contains('hallway shelf'));
      expect(prompt, contains('tools'));
      expect(prompt, contains('umbrella'));
    });

    test('includes grocery tool instructions', () {
      final section = buildListToolPrompt(listName: 'grocery', storedItems: []);
      final prompt = buildChatPrompt(
        storedLocationSummaries: [],
        listToolSections: [section],
      );

      expect(prompt, contains('add_to_list'));
      expect(prompt, contains('grocery'));
    });

    test('includes stored grocery items in context', () {
      final section = buildListToolPrompt(
        listName: 'grocery',
        storedItems: ['potatoes', 'milk'],
      );
      final prompt = buildChatPrompt(
        storedLocationSummaries: [],
        listToolSections: [section],
      );

      expect(prompt, contains('potatoes'));
      expect(prompt, contains('milk'));
    });

    test('includes thoughts list instructions', () {
      final section = buildListToolPrompt(listName: 'thoughts', storedItems: []);
      final prompt = buildChatPrompt(
        storedLocationSummaries: [],
        listToolSections: [section],
      );

      expect(prompt, contains('thoughts'));
      expect(prompt, contains('add_to_list'));
    });

    test('fallback instructs LLM to suggest possible actions when intent is ambiguous', () {
      final prompt = buildChatPrompt(
        storedLocationSummaries: [],
        listToolSections: [],
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
      final groceryRepo = FakeListRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            llm: llm,
            whereIsItRepository: FakeWhereIsItRepository(),
            listTools: [ListTool(name: 'grocery', repository: groceryRepo)],
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
