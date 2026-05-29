import 'package:flutter_test/flutter_test.dart';
import 'package:unburden_app/core/mock_llm_client.dart';
import 'package:unburden_app/features/space_manager/domain/space_parser.dart';

void main() {
  group('SpaceParser', () {
    test('parses a natural language description into a StorageLocation', () async {
      final parser = SpaceParser(
        llm: MockLlmClient(
          fixedResponse: '''
[
  {
    "name": "top wardrobe shelf",
    "width_cm": 80.0,
    "depth_cm": 40.0,
    "height_cm": 30.0,
    "contents": ["winter coats", "Christmas deco"],
    "access_note": "need the escabeau to reach it"
  }
]
''',
        ),
      );

      final result = await parser.parseMany(
        'top wardrobe shelf, about 80x40x30cm, winter coats and Christmas deco, need the escabeau to reach it',
      );

      expect(result.first.name, 'top wardrobe shelf');
      expect(result.first.widthCm, 80.0);
      expect(result.first.contents, contains('winter coats'));
      expect(result.first.accessNote, isNotEmpty);
    });

    test('parse uses input text as location name', () async {
      final llm = MockLlmClient(
        fixedResponse: '''
[
  {
    "name": "white shelf in hallway",
    "width_cm": 60.0,
    "depth_cm": 30.0,
    "height_cm": 180.0,
    "contents": ["shoes", "umbrella"],
    "access_note": "easy to reach"
  }
]
''',
      );
      final parser = SpaceParser(llm: llm);
      final location = await parser.parseMany('white shelf in hallway');
      expect(location.first.name, 'white shelf in hallway');
    });

    test('parses a long description into multiple StorageLocations', () async {
      final parser = SpaceParser(
        llm: MockLlmClient(
          fixedResponse: '''
[
  {
    "name": "white shelf in hallway",
    "width_cm": 0.0,
    "depth_cm": 0.0,
    "height_cm": 0.0,
    "contents": ["tools", "canned food"],
    "access_note": ""
  },
  {
    "name": "top of washing machine",
    "width_cm": 0.0,
    "depth_cm": 0.0,
    "height_cm": 0.0,
    "contents": ["shirts"],
    "access_note": ""
  }
]
''',
        ),
      );

      final results = await parser.parseMany(
        'in the hallway I have a white shelf with tools and canned food. On top of the washing machine I have shirts.',
      );

      expect(results.length, 2);
      expect(results[0].name, 'white shelf in hallway');
      expect(results[1].name, 'top of washing machine');
    });
    test('parseMany handles a single-object JSON response gracefully', () async {
      final parser = SpaceParser(
        llm: MockLlmClient(
          fixedResponse: '''
{
  "name": "white shelf in hallway",
  "width_cm": 60.0,
  "depth_cm": 30.0,
  "height_cm": 180.0,
  "contents": ["shoes", "umbrella"],
  "access_note": "easy to reach"
}
''',
        ),
      );

      final results = await parser.parseMany('white shelf in hallway');

      expect(results.length, 1);
      expect(results.first.name, 'white shelf in hallway');
    });
  });
}
