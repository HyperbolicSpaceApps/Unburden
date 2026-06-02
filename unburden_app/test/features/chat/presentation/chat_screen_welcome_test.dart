import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unburden_app/core/mock_llm_client.dart';
import 'package:unburden_app/features/chat/presentation/chat_screen.dart';
import 'package:unburden_app/features/space_manager/data/fake_space_repository.dart';

void main() {
  group('ChatScreen welcome', () {
    testWidgets('shows welcome message on first load before any user input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(llm: MockLlmClient(), repository: FakeSpaceRepository()),
        ),
      );

      expect(find.text('Welcome to Unburden, what\'s up?'), findsOneWidget);
    });
  });
}
