import 'package:flutter_test/flutter_test.dart';
import 'package:unburden_app/core/mock_llm_client.dart';
import 'package:unburden_app/features/space_manager/domain/space_parser.dart';


void main() {
  group('SpaceParser', () {
    test('parses a natural language description into a StorageLocation', () async {
      final parser = SpaceParser(
        llm: MockLlmClient(fixedResponse: '''
{
  "name": "top wardrobe shelf",
  "width_cm": 80.0,
  "depth_cm": 40.0,
  "height_cm": 30.0,
  "contents": ["winter coats", "Christmas deco"],
  "access_note": "need the escabeau to reach it"
}
'''),
      );

      final result = await parser.parse(
        'top wardrobe shelf, about 80x40x30cm, winter coats and Christmas deco, need the escabeau to reach it',
      );

      expect(result.name, 'top wardrobe shelf');
      expect(result.widthCm, 80.0);
      expect(result.contents, contains('winter coats'));
      expect(result.accessNote, isNotEmpty);
    });
  });
}