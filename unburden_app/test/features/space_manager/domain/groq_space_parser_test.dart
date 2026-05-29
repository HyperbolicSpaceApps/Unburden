import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unburden_app/core/groq_llm_client.dart';
import 'package:unburden_app/features/space_manager/domain/space_parser.dart';

// Run manually only — requires UNBURDEN_GROQ_API_KEY in .env.
// flutter test test/features/space_manager/domain/groq_space_parser_test.dart
void main() async {
  await dotenv.load(fileName: ".env");
  final apiKey = dotenv.env['UNBURDEN_GROQ_API_KEY'] ?? '';

  group('SpaceParser with GroqLlmClient', () {
    late SpaceParser parser;

    setUp(() {
      if (apiKey.isEmpty) {
        return; // skip setup — tests will be skipped below
      }
      parser = SpaceParser(llm: GroqLlmClient(apiKey: apiKey));
    });

    test('parses a single location from a short description', () async {
      if (apiKey.isEmpty) {
        markTestSkipped('UNBURDEN_GROQ_API_KEY not set');
        return;
      }

      final locations = await parser.parseMany('white shelf in the hallway');

      expect(locations, isNotEmpty);
      expect(locations.first.name, isNotEmpty);
    });

    test('parses multiple locations from a compound description', () async {
      if (apiKey.isEmpty) {
        markTestSkipped('UNBURDEN_GROQ_API_KEY not set');
        return;
      }

      final locations = await parser.parseMany(
        'in the hallway I have a white shelf with tools and canned food. '
        'On top of the washing machine I have shirts.',
      );

      expect(locations.length, greaterThanOrEqualTo(2));
      expect(locations.any((l) => l.name.toLowerCase().contains('hallway')), isTrue);
      expect(
        locations.any(
          (l) =>
              l.name.toLowerCase().contains('washing') || l.name.toLowerCase().contains('machine'),
        ),
        isTrue,
      );
    });
  });
}
