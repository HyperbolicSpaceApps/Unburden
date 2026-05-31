import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:unburden_app/core/mock_llm_client.dart';
import 'package:unburden_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    if (Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  });

  testWidgets('app starts and shows chat screen', (tester) async {
    app.main(
      dbPath: 'test_${DateTime.now().millisecondsSinceEpoch}.db',
      llmClient: MockLlmClient(),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);
  });

  testWidgets('user message appears in chat after sending', (tester) async {
    app.main(
      dbPath: 'test_${DateTime.now().millisecondsSinceEpoch}.db',
      llmClient: MockLlmClient(),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('submitting a location saves it and shows confirmation', (tester) async {
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

    app.main(
      dbPath: 'test_${DateTime.now().millisecondsSinceEpoch}.db',
      llmClient: MockLlmClient(fixedResponse: mockResponse),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      'I have a white shelf in the hallway with tools',
    );
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.textContaining('hallway shelf'), findsOneWidget);
  });

  testWidgets('chat scrolls to show latest message', (tester) async {
    app.main(
      dbPath: 'test_${DateTime.now().millisecondsSinceEpoch}.db',
      llmClient: MockLlmClient(),
    );
    await tester.pumpAndSettle();

    for (int i = 0; i < 10; i++) {
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'message $i');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
    }

    expect(find.textContaining('Saved: message 9', skipOffstage: false), findsOneWidget);
  });
}
