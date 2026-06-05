import 'package:flutter_test/flutter_test.dart';
import 'package:unburden_app/features/chat/domain/grocery_prompt_builder.dart';
import 'package:unburden_app/features/chat/domain/space_manager_prompt_builder.dart';
import 'package:unburden_app/features/chat/domain/thoughts_prompt_builder.dart';

void main() {
  group('Space Manager Prompt', () {
    test('includes stored location summaries', () {
      final prompt = buildSpaceManagerPrompt(
        storedLocationSummaries: ['hallway shelf: tools, umbrella'],
      );
      expect(prompt, contains('hallway shelf'));
      expect(prompt, contains('tools'));
      expect(prompt, contains('umbrella'));
    });

    test('contains a strict no-invention rule', () {
      final prompt = buildSpaceManagerPrompt(storedLocationSummaries: []);
      expect(prompt, contains('ONLY'));
    });

    test('does not mention grocery actions', () {
      final prompt = buildSpaceManagerPrompt(storedLocationSummaries: []);
      expect(prompt, isNot(contains('add_items')));
    });

    test('does not mention thoughts actions', () {
      final prompt = buildSpaceManagerPrompt(storedLocationSummaries: []);
      expect(prompt, isNot(contains('add_thought')));
    });
  });

  group('Grocery Prompt', () {
    test('includes current grocery items', () {
      final prompt = buildGroceryPrompt(storedGroceryItems: ['potatoes', 'milk']);
      expect(prompt, contains('potatoes'));
      expect(prompt, contains('milk'));
    });

    test('includes tool rules when provided', () {
      final prompt = buildGroceryPrompt(
        storedGroceryItems: [],
        toolRules: ['show list when I say grocery'],
      );
      expect(prompt, contains('show list when I say grocery'));
    });

    test('does not mention space manager actions', () {
      final prompt = buildGroceryPrompt(storedGroceryItems: []);
      expect(prompt, isNot(contains('save_locations')));
      expect(prompt, isNot(contains('access_note')));
    });

    test('does not mention thoughts actions', () {
      final prompt = buildGroceryPrompt(storedGroceryItems: []);
      expect(prompt, isNot(contains('add_thought')));
    });
  });

  group('Thoughts Prompt', () {
    test('contains add_thought action', () {
      final prompt = buildThoughtsPrompt();
      expect(prompt, contains('add_thought'));
    });

    test('does not mention other tool actions', () {
      final prompt = buildThoughtsPrompt();
      expect(prompt, isNot(contains('add_items')));
      expect(prompt, isNot(contains('save_locations')));
    });
  });
}
