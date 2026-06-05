import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:unburden_app/core/mock_llm_client.dart';

void main() {
  group('MockLlmClient', () {
    test('default response without fixedResponse returns answer action', () async {
      final client = MockLlmClient();
      final raw = await client.complete('', [
        {'role': 'user', 'content': 'anything'},
      ]);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;

      expect(decoded['action'], equals('answer'));
      expect(decoded['message'], isA<String>());
    });
  });
}
