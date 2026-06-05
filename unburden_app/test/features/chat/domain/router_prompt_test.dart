import 'package:flutter_test/flutter_test.dart';
import 'package:unburden_app/features/chat/domain/router_prompt_builder.dart';

void main() {
  group('Router Prompt', () {
    test('lists all available tool identifiers', () {
      final prompt = buildRouterPrompt();
      expect(prompt, contains('space_manager'));
      expect(prompt, contains('grocery'));
      expect(prompt, contains('thoughts'));
      expect(prompt, contains('answer'));
    });

    test('instructs LLM to return a JSON tool field', () {
      final prompt = buildRouterPrompt();
      expect(prompt, contains('"tool"'));
    });

    test('contains no tool-specific business rules or actions', () {
      final prompt = buildRouterPrompt();
      expect(prompt, isNot(contains('add_items')));
      expect(prompt, isNot(contains('save_locations')));
      expect(prompt, isNot(contains('add_thought')));
      expect(prompt, isNot(contains('invent')));
    });
  });
}
