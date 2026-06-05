import 'package:unburden_app/core/llm_client.dart';

class ThrowingLlmClient implements LlmClient {
  final String message;
  ThrowingLlmClient([this.message = 'network error']);

  @override
  Future<String> complete(String systemPrompt, List<Map<String, String>> messages) async {
    throw Exception(message);
  }
}
