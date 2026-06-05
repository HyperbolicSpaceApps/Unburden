import 'package:flutter_test/flutter_test.dart';
import 'package:unburden_app/features/chat/domain/grocery_prompt_builder.dart';
import 'package:unburden_app/features/chat/domain/list_tool_prompt_builder.dart';
import 'package:unburden_app/features/chat/domain/space_manager_prompt_builder.dart';
import 'package:unburden_app/features/chat/domain/thoughts_prompt_builder.dart';
import 'package:unburden_app/features/chat/domain/todo_prompt_builder.dart';
import 'package:unburden_app/features/chat/domain/where_is_it_prompt_builder.dart';

void main() {
  group('Where Is It Prompt', () {
    test('contains save_locations action', () {
      final prompt = buildWhereIsItPrompt(storedLocationSummaries: []);
      expect(prompt, contains('save_locations'));
    });

    test('includes stored location summaries', () {
      final prompt = buildWhereIsItPrompt(
        storedLocationSummaries: ['hallway shelf: tools, umbrella'],
      );
      expect(prompt, contains('hallway shelf'));
      expect(prompt, contains('tools'));
    });

    test('schema has no dimensions or access note', () {
      final prompt = buildWhereIsItPrompt(storedLocationSummaries: []);
      expect(prompt, isNot(contains('width_cm')));
      expect(prompt, isNot(contains('depth_cm')));
      expect(prompt, isNot(contains('height_cm')));
      expect(prompt, isNot(contains('access_note')));
    });

    test('does not mention list actions', () {
      final prompt = buildWhereIsItPrompt(storedLocationSummaries: []);
      expect(prompt, isNot(contains('add_to_list')));
      expect(prompt, isNot(contains('add_thought')));
    });
  });

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

  group('List Tool Prompt', () {
    test('contains add_to_list action', () {
      final prompt = buildListToolPrompt(listName: 'grocery', storedItems: []);
      expect(prompt, contains('add_to_list'));
    });

    test('includes the list name in the action schema', () {
      final prompt = buildListToolPrompt(listName: 'grocery', storedItems: []);
      expect(prompt, contains('grocery'));
    });

    test('includes stored items', () {
      final prompt = buildListToolPrompt(listName: 'grocery', storedItems: ['milk', 'eggs']);
      expect(prompt, contains('milk'));
      expect(prompt, contains('eggs'));
    });

    test('does not mention old per-tool action names', () {
      final prompt = buildListToolPrompt(listName: 'grocery', storedItems: []);
      expect(prompt, isNot(contains('add_items')));
      expect(prompt, isNot(contains('add_todo')));
    });
  });

  group('Todo Prompt', () {
    test('contains add_todo action', () {
      final prompt = buildTodoPrompt(storedTodos: []);
      expect(prompt, contains('add_todo'));
    });

    test('includes existing todos in prompt', () {
      final prompt = buildTodoPrompt(storedTodos: ['buy milk', 'call dentist']);
      expect(prompt, contains('buy milk'));
      expect(prompt, contains('call dentist'));
    });

    test('does not mention other tool actions', () {
      final prompt = buildTodoPrompt(storedTodos: []);
      expect(prompt, isNot(contains('add_items')));
      expect(prompt, isNot(contains('save_locations')));
      expect(prompt, isNot(contains('add_thought')));
    });
  });
}
