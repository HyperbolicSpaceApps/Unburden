import 'dart:convert';

import 'package:unburden_app/core/llm_client.dart';
import 'package:unburden_app/features/space_manager/domain/storage_location.dart';

class SpaceParser {
  final LlmClient llm;

  SpaceParser({required this.llm});

  Future<StorageLocation> parse(String input) async {
    final prompt = '''
Extract storage location details from this description and return ONLY valid JSON, no other text:
"$input"

JSON format:
{
  "name": "short location name",
  "width_cm": 0.0,
  "depth_cm": 0.0,
  "height_cm": 0.0,
  "contents": ["item1", "item2"],
  "access_note": "how hard to reach"
}
''';

    final response = await llm.complete(prompt);
    final json = jsonDecode(response);

    return StorageLocation(
      name: json['name'] as String,
      widthCm: (json['width_cm'] as num).toDouble(),
      depthCm: (json['depth_cm'] as num).toDouble(),
      heightCm: (json['height_cm'] as num).toDouble(),
      contents: List<String>.from(json['contents']),
      accessNote: json['access_note'] as String,
    );
  }
}