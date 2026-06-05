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

    final json = jsonDecode(response.body);
    final content = json['choices']?[0]?['message']?['content'];

    if (content == null) {
      throw Exception('Groq returned null content');
    }

    return content as String;
  }
}
