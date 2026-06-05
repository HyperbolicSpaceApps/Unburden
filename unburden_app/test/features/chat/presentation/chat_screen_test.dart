import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unburden_app/core/mock_llm_client.dart';
import 'package:unburden_app/core/throwing_llm_client.dart';
import 'package:unburden_app/features/chat/presentation/chat_screen.dart';
import 'package:unburden_app/features/grocery/data/fake_grocery_repository.dart';
import 'package:unburden_app/features/space_manager/data/fake_space_repository.dart';
import 'package:unburden_app/features/thoughts/data/fake_thought_repository.dart';
import 'package:unburden_app/features/todo/data/fake_todo_repository.dart';

void main() {
  group('ChatScreen', () {
    testWidgets('shows a text input and send button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            llm: MockLlmClient(),
            spaceRepository: FakeSpaceRepository(),
            groceryRepository: FakeGroceryRepository(),
            thoughtRepository: FakeThoughtRepository(),
            todoRepository: FakeTodoRepository(),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('user message appears in chat after sending', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            llm: MockLlmClient(),
            spaceRepository: FakeSpaceRepository(),
            groceryRepository: FakeGroceryRepository(),
            thoughtRepository: FakeThoughtRepository(),
            todoRepository: FakeTodoRepository(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets(
      'when LLM returns save intent, location is persisted and confirmation appears in chat',
      (tester) async {
        const mockResponse = '''
{
  "action": "save_locations",
  "locations": [
    {
      "name": "hallway shelf",
      "width_cm": 0.0,
      "depth_cm": 0.0,
      "height_cm": 0.0,
      "contents": ["tools"],
      "access_note": ""
    }
  ]
}
''';

        final repository = FakeSpaceRepository();

        await tester.pumpWidget(
          MaterialApp(
            home: ChatScreen(
              llm: MockLlmClient(fixedResponse: mockResponse),
              spaceRepository: repository,
              groceryRepository: FakeGroceryRepository(),
              thoughtRepository: FakeThoughtRepository(),
              todoRepository: FakeTodoRepository(),
            ),
          ),
        );

        await tester.enterText(
          find.byType(TextField),
          'I have a white shelf in the hallway with tools',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // LLM confirmation appears in chat
        expect(find.textContaining('Saved: hallway shelf'), findsOneWidget);

        // location was actually saved
        final saved = await repository.getAll();
        expect(saved.length, equals(1));
        expect(saved.first.name, equals('hallway shelf'));
        expect(saved.first.contents, contains('tools'));
      },
    );

    testWidgets('when LLM returns answer intent, response appears in chat without saving', (
      tester,
    ) async {
      const mockResponse = '''
{
  "action": "answer",
  "message": "Your tools are on the hallway shelf."
}
''';

      final repository = FakeSpaceRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            llm: MockLlmClient(fixedResponse: mockResponse),
            spaceRepository: repository,
            groceryRepository: FakeGroceryRepository(),
            thoughtRepository: FakeThoughtRepository(),
            todoRepository: FakeTodoRepository(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'where are my tools?');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.text('Your tools are on the hallway shelf.'), findsOneWidget);

      // nothing was saved
      final saved = await repository.getAll();
      expect(saved, isEmpty);
    });

    testWidgets('a shelf with multiple levels is saved as separate locations', (tester) async {
      const mockResponse = '''
{
  "action": "save_locations",
  "locations": [
    {
      "name": "Billy top level",
      "width_cm": null,
      "depth_cm": null,
      "height_cm": null,
      "contents": ["board games"],
      "access_note": ""
    },
    {
      "name": "Billy middle level",
      "width_cm": null,
      "depth_cm": null,
      "height_cm": null,
      "contents": ["books"],
      "access_note": ""
    },
    {
      "name": "Billy bottom level",
      "width_cm": null,
      "depth_cm": null,
      "height_cm": null,
      "contents": ["cables"],
      "access_note": ""
    }
  ],
  "message": "Saved 3 levels."
}
''';

      final repository = FakeSpaceRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            llm: MockLlmClient(fixedResponse: mockResponse),
            spaceRepository: repository,
            groceryRepository: FakeGroceryRepository(),
            thoughtRepository: FakeThoughtRepository(),
            todoRepository: FakeTodoRepository(),
          ),
        ),
      );

      await tester.enterText(
        find.byType(TextField),
        'Billy shelf: top level has board games, middle has books, bottom has cables',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      final saved = await repository.getAll();
      expect(saved.length, equals(3));
    });
    testWidgets('confirmation message after saving lists the actual saved location names', (
      tester,
    ) async {
      const mockResponse = '''
{
  "action": "save_locations",
  "locations": [
    {
      "name": "Billy top level",
      "width_cm": null,
      "depth_cm": null,
      "height_cm": null,
      "contents": ["board games"],
      "access_note": ""
    },
    {
      "name": "Billy middle level",
      "width_cm": null,
      "depth_cm": null,
      "height_cm": null,
      "contents": ["books"],
      "access_note": ""
    }
  ]
}
''';

      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            llm: MockLlmClient(fixedResponse: mockResponse),
            spaceRepository: FakeSpaceRepository(),
            groceryRepository: FakeGroceryRepository(),
            thoughtRepository: FakeThoughtRepository(),
            todoRepository: FakeTodoRepository(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Billy shelf with two levels');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.textContaining('Billy top level'), findsOneWidget);
      expect(find.textContaining('Billy middle level'), findsOneWidget);
    });

    testWidgets('chat scrolls to latest message after sending', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            llm: MockLlmClient(),
            spaceRepository: FakeSpaceRepository(),
            groceryRepository: FakeGroceryRepository(),
            thoughtRepository: FakeThoughtRepository(),
            todoRepository: FakeTodoRepository(),
          ),
        ),
      );

      for (int i = 0; i < 10; i++) {
        await tester.enterText(find.byType(TextField), 'message $i');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();
      }

      // last user message is visible after scroll
      expect(find.text('message 9'), findsOneWidget);
    });

    testWidgets('LLM response is selectable text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            llm: MockLlmClient(),
            spaceRepository: FakeSpaceRepository(),
            groceryRepository: FakeGroceryRepository(),
            thoughtRepository: FakeThoughtRepository(),
            todoRepository: FakeTodoRepository(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.byType(SelectableText), findsAtLeastNWidgets(1));
    });

    testWidgets('shows welcome message on first load before any user input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            llm: MockLlmClient(),
            spaceRepository: FakeSpaceRepository(),
            groceryRepository: FakeGroceryRepository(),
            thoughtRepository: FakeThoughtRepository(),
            todoRepository: FakeTodoRepository(),
          ),
        ),
      );

      expect(find.text("welcome to Unburden. what's up?"), findsOneWidget);
    });

    testWidgets('add_to_list for grocery saves item and shows confirmation', (tester) async {
      const mockResponse = '''
{
  "action": "add_to_list",
  "list": "grocery",
  "items": ["potatoes"]
}
''';

      final repo = FakeGroceryRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            llm: MockLlmClient(fixedResponse: mockResponse),
            spaceRepository: FakeSpaceRepository(),
            groceryRepository: repo,
            thoughtRepository: FakeThoughtRepository(),
            todoRepository: FakeTodoRepository(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'I need potatoes');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.textContaining('potatoes'), findsWidgets);

      final saved = await repo.getAll();
      expect(saved.length, equals(1));
      expect(saved.first.name, equals('potatoes'));
    });

    testWidgets('add_to_list for todo saves item and shows confirmation', (tester) async {
      const mockResponse = '''
{
  "action": "add_to_list",
  "list": "todo",
  "items": ["call the dentist"]
}
''';

      final repo = FakeTodoRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            llm: MockLlmClient(fixedResponse: mockResponse),
            spaceRepository: FakeSpaceRepository(),
            groceryRepository: FakeGroceryRepository(),
            thoughtRepository: FakeThoughtRepository(),
            todoRepository: repo,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'add to my todo: call the dentist');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.textContaining('call the dentist'), findsWidgets);

      final saved = await repo.getAll();
      expect(saved.length, equals(1));
      expect(saved.first.text, equals('call the dentist'));
    });

    testWidgets('when llm.complete() throws, error message includes the reason', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            llm: ThrowingLlmClient('401 unauthorized'),
            spaceRepository: FakeSpaceRepository(),
            groceryRepository: FakeGroceryRepository(),
            thoughtRepository: FakeThoughtRepository(),
            todoRepository: FakeTodoRepository(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.textContaining('401 unauthorized'), findsOneWidget);
    });

    testWidgets(
      'when LLM response causes a processing error, error appears in chat and send button is re-enabled',
      (tester) async {
        const mockResponse = '''
{
  "action": "answer"
}
''';

        await tester.pumpWidget(
          MaterialApp(
            home: ChatScreen(
              llm: MockLlmClient(fixedResponse: mockResponse),
              spaceRepository: FakeSpaceRepository(),
              groceryRepository: FakeGroceryRepository(),
              thoughtRepository: FakeThoughtRepository(),
              todoRepository: FakeTodoRepository(),
            ),
          ),
        );

        await tester.enterText(find.byType(TextField), 'groceries');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        expect(find.textContaining('Error:'), findsOneWidget);
        expect(
          tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send)).onPressed,
          isNotNull,
        );
      },
    );
  });
}
