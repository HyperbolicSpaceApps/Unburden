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
  ],
  "message": "Got it, I've saved your hallway shelf with tools."
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
        expect(find.text("Got it, I've saved your hallway shelf with tools."), findsOneWidget);

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
  });
}
