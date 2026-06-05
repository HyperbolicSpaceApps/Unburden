import 'dart:convert';

import 'package:unburden_app/core/app_logger.dart';
import 'package:unburden_app/core/llm_client.dart';
import 'package:unburden_app/features/space_manager/domain/storage_location.dart';

class SpaceParser {
  final LlmClient llm;

  SpaceParser({required this.llm});

  Future<List<StorageLocation>> parseMany(String input) async {
    final prompt =
        '''
Extract all storage locations from this description and return ONLY a valid JSON array, no other text:
"$input"

JSON format:
[
  {
    "name": "short location name",
    "width_cm": 0.0,
    "depth_cm": 0.0,
    "height_cm": 0.0,
    "contents": ["item1", "item2"],
    "access_note": "how hard to reach"
  }
]
''';

    final response = await llm.complete('', [
      {'role': 'user', 'content': prompt},
    ]);
    AppLogger.llm('raw response: $response');

    final decoded = jsonDecode(response);
    AppLogger.llm('json decoded: $decoded');

    final json = decoded is List ? decoded : [decoded];
    AppLogger.llm('parsed result: $json');

    return json
        .map(
          (item) => StorageLocation(
            name: item['name'] as String,
            widthCm: (item['width_cm'] as num?)?.toDouble(),
            depthCm: (item['depth_cm'] as num?)?.toDouble(),
            heightCm: (item['height_cm'] as num?)?.toDouble(),
            contents: List<String>.from(item['contents']),
            accessNote: item['access_note'] as String? ?? '',
          ),
        )
        .toList();
  }
}
