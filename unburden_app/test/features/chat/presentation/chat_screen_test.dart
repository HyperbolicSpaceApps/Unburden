import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unburden_app/core/mock_llm_client.dart';
import 'package:unburden_app/features/chat/presentation/chat_screen.dart';
import 'package:unburden_app/features/space_manager/data/fake_space_repository.dart';

void main() {
  group('ChatScreen', () {
    testWidgets('shows a text input and send button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(llm: MockLlmClient(), repository: FakeSpaceRepository()),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('user message appears in chat after sending', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(llm: MockLlmClient(), repository: FakeSpaceRepository()),
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
              repository: repository,
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
            repository: repository,
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
            repository: repository,
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
            repository: FakeSpaceRepository(),
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
      final repository = FakeSpaceRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(llm: MockLlmClient(), repository: repository),
        ),
      );

      for (int i = 0; i < 10; i++) {
        await tester.enterText(find.byType(TextField), 'message $i');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();
      }

      expect(find.textContaining('Saved: message 9'), findsOneWidget);
    });

    testWidgets('LLM response is selectable text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(llm: MockLlmClient(), repository: FakeSpaceRepository()),
        ),
      );

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.byType(SelectableText), findsAtLeastNWidgets(1));
    });
  });
}
