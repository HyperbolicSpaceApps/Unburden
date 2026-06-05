import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:unburden_app/core/app_logger.dart';
import 'package:unburden_app/core/llm_client.dart';

class GroqLlmClient implements LlmClient {
  final String apiKey;
  final String model;

  GroqLlmClient({required this.apiKey, this.model = 'llama-3.1-8b-instant'});

  @override
  Future<String> complete(String systemPrompt, List<Map<String, String>> messages) async {
    const maxRetries = 3;
    var delay = const Duration(seconds: 2);

    for (var attempt = 0; attempt < maxRetries; attempt++) {
      AppLogger.groq('sending request, ${messages.length} messages');

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            ...messages,
          ],
        }),
      );

      AppLogger.groq('http status: ${response.statusCode}');
      AppLogger.groq('raw response body: ${response.body}');

      if (response.statusCode == 429) {
        if (attempt < maxRetries - 1) {
          final wait = _parseRetryAfter(response.body) ?? delay;
          AppLogger.groq('rate limited, retrying in ${wait.inMilliseconds}ms');
          await Future.delayed(wait);
          delay *= 2;
          continue;
        }
        throw Exception('Groq rate limit exceeded after $maxRetries attempts');
      }

      final json = jsonDecode(response.body);
      final content = json['choices']?[0]?['message']?['content'];

      if (content == null) {
        throw Exception('Groq returned null content');
      }

      return content as String;
    }

    throw Exception('Groq request failed after $maxRetries attempts');
  }

  Duration? _parseRetryAfter(String body) {
    final match = RegExp(r'try again in (\d+(?:\.\d+)?)s').firstMatch(body);
    if (match == null) return null;
    final seconds = double.tryParse(match.group(1)!);
    if (seconds == null) return null;
    return Duration(milliseconds: (seconds * 1000).ceil() + 200);
  }
}
