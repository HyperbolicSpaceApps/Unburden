import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:unburden_app/core/groq_llm_client.dart';
import 'package:unburden_app/features/space_manager/domain/space_parser.dart';

void main() {
  group('GroqLlmClient (live API)', () {
    late String apiKey;

    setUpAll(() {
      apiKey = Platform.environment['UNBURDEN_GROQ_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        // skip gracefully if no key present
        return;
      }
    });

    test('SpaceParser with GroqLlmClient parses natural language into a StorageLocation', () async {
      if (apiKey.isEmpty) {
        markTestSkipped('UNBURDEN_GROQ_API_KEY not set');
        return;
      }

      final llm = GroqLlmClient(apiKey: apiKey);
      final parser = SpaceParser(llm: llm);

      final location = await parser.parseMany(
        'white shelf in the hallway, holds shoes and umbrella',
      );

      expect(location.first.name, isNotEmpty);
      expect(location.first.contents, isNotEmpty);
    });

    test(
      'parseMany with GroqLlmClient correctly splits a long description into meaningful locations',
      () async {
        if (apiKey.isEmpty) {
          markTestSkipped('UNBURDEN_GROQ_API_KEY not set');
          return;
        }

        final llm = GroqLlmClient(apiKey: apiKey);
        final parser = SpaceParser(llm: llm);

        final results = await parser.parseMany(
          'in the hallway I have a big white shelf with tools on the first 2 levels, '
          'canned food on the next 2 levels, and bike gear on the top which is difficult to reach. '
          'On top of the washing machine I have all my shirts.',
        );

        expect(results.length, greaterThanOrEqualTo(2));
        expect(
          results.any(
            (l) =>
                l.name.toLowerCase().contains('hallway') || l.name.toLowerCase().contains('shelf'),
          ),
          isTrue,
        );
        expect(
          results.any(
            (l) => l.contents.any(
              (c) => c.toLowerCase().contains('bike') || c.toLowerCase().contains('tool'),
            ),
          ),
          isTrue,
        );
        expect(
          results.any(
            (l) =>
                l.name.toLowerCase().contains('washing') ||
                l.contents.any((c) => c.toLowerCase().contains('shirt')),
          ),
          isTrue,
        );
      },
    );
  });
}
