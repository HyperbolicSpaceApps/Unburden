import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unburden_app/core/llm_client.dart';
import 'package:unburden_app/core/mock_llm_client.dart';
import 'package:unburden_app/core/throwing_llm_client.dart';
import 'package:unburden_app/features/chat/domain/list_tool.dart';
import 'package:unburden_app/features/chat/presentation/chat_screen.dart';
import 'package:unburden_app/features/list/data/fake_list_repository.dart';
import 'package:unburden_app/features/where_is_it/data/fake_where_is_it_repository.dart';

ChatScreen _screen({LlmClient? llm, List<ListTool>? listTools}) => ChatScreen(
  llm: llm ?? MockLlmClient(),
  whereIsItRepository: FakeWhereIsItRepository(),
  listTools:
      listTools ??
      [
        ListTool(name: 'grocery', repository: FakeListRepository()),
        ListTool(name: 'todo', repository: FakeListRepository()),
        ListTool(name: 'thoughts', repository: FakeListRepository()),
      ],
);

void main() {
  group('ChatScreen', () {
    testWidgets('shows a text input and send button', (tester) async {
      await tester.pumpWidget(MaterialApp(home: _screen()));
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('user message appears in chat after sending', (tester) async {
      await tester.pumpWidget(MaterialApp(home: _screen()));
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
  "locations": [{"name": "hallway shelf", "contents": ["tools"]}]
}
''';
        final repository = FakeWhereIsItRepository();
        await tester.pumpWidget(
          MaterialApp(
            home: ChatScreen(
              llm: MockLlmClient(fixedResponse: mockResponse),
              whereIsItRepository: repository,
              listTools: [],
            ),
          ),
        );
        await tester.enterText(find.byType(TextField), 'I have a shelf in the hallway with tools');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();
        expect(find.textContaining('Saved: hallway shelf'), findsOneWidget);
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
      final repository = FakeWhereIsItRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            llm: MockLlmClient(fixedResponse: mockResponse),
            whereIsItRepository: repository,
            listTools: [],
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'where are my tools?');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
      expect(find.text('Your tools are on the hallway shelf.'), findsOneWidget);
      final saved = await repository.getAll();
      expect(saved, isEmpty);
    });

    testWidgets('a shelf with multiple levels is saved as separate locations', (tester) async {
      const mockResponse = '''
{
  "action": "save_locations",
  "locations": [
    {"name": "Billy top level", "contents": ["board games"]},
    {"name": "Billy middle level", "contents": ["books"]},
    {"name": "Billy bottom level", "contents": ["cables"]}
  ]
}
''';
      final repository = FakeWhereIsItRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            llm: MockLlmClient(fixedResponse: mockResponse),
            whereIsItRepository: repository,
            listTools: [],
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Billy shelf with three levels');
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
    {"name": "Billy top level", "contents": ["board games"]},
    {"name": "Billy middle level", "contents": ["books"]}
  ]
}
''';
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            llm: MockLlmClient(fixedResponse: mockResponse),
            whereIsItRepository: FakeWhereIsItRepository(),
            listTools: [],
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
      await tester.pumpWidget(MaterialApp(home: _screen()));
      for (int i = 0; i < 10; i++) {
        await tester.enterText(find.byType(TextField), 'message $i');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();
      }
      expect(find.text('message 9'), findsOneWidget);
    });

    testWidgets('LLM response is selectable text', (tester) async {
      await tester.pumpWidget(MaterialApp(home: _screen()));
      await tester.enterText(find.byType(TextField), 'hello');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
      expect(find.byType(SelectableText), findsAtLeastNWidgets(1));
    });

    testWidgets('shows welcome message on first load before any user input', (tester) async {
      await tester.pumpWidget(MaterialApp(home: _screen()));
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
      final repo = FakeListRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            llm: MockLlmClient(fixedResponse: mockResponse),
            whereIsItRepository: FakeWhereIsItRepository(),
            listTools: [ListTool(name: 'grocery', repository: repo)],
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'I need potatoes');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
      expect(find.textContaining('potatoes'), findsWidgets);
      final saved = await repo.getAll();
      expect(saved.length, equals(1));
      expect(saved.first, equals('potatoes'));
    });

    testWidgets('add_to_list for todo saves item and shows confirmation', (tester) async {
      const mockResponse = '''
{
  "action": "add_to_list",
  "list": "todo",
  "items": ["call the dentist"]
}
''';
      final repo = FakeListRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            llm: MockLlmClient(fixedResponse: mockResponse),
            whereIsItRepository: FakeWhereIsItRepository(),
            listTools: [ListTool(name: 'todo', repository: repo)],
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'add to my todo: call the dentist');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
      expect(find.textContaining('call the dentist'), findsWidgets);
      final saved = await repo.getAll();
      expect(saved.length, equals(1));
      expect(saved.first, equals('call the dentist'));
    });

    testWidgets('add_to_list for thoughts is stored', (tester) async {
      const mockResponse = '''
{
  "action": "add_to_list",
  "list": "thoughts",
  "items": ["interesting sunset today"]
}
''';
      final repo = FakeListRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            llm: MockLlmClient(fixedResponse: mockResponse),
            whereIsItRepository: FakeWhereIsItRepository(),
            listTools: [ListTool(name: 'thoughts', repository: repo)],
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'interesting sunset today');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
      final saved = await repo.getAll();
      expect(saved.length, equals(1));
      expect(saved.first, contains('sunset'));
    });

    testWidgets('remove_from_list with items ["all"] clears the list and shows confirmation', (
      tester,
    ) async {
      const mockResponse = '''
{
  "action": "remove_from_list",
  "list": "todo",
  "items": ["all"]
}
''';
      final repo = FakeListRepository();
      await repo.addAll(['béquille peugeot', 'call dentist']);
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            llm: MockLlmClient(fixedResponse: mockResponse),
            whereIsItRepository: FakeWhereIsItRepository(),
            listTools: [ListTool(name: 'todo', repository: repo)],
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'yes');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(await repo.getAll(), isEmpty);
      expect(find.textContaining('Error:'), findsNothing);
    });

    testWidgets('when llm.complete() throws, error message includes the reason', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            llm: ThrowingLlmClient('401 unauthorized'),
            whereIsItRepository: FakeWhereIsItRepository(),
            listTools: [],
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
              whereIsItRepository: FakeWhereIsItRepository(),
              listTools: [],
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
