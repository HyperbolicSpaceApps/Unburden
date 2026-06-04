import 'package:unburden_app/core/llm_client.dart';

class ThrowingLlmClient implements LlmClient {
  final String message;
  ThrowingLlmClient([this.message = 'network error']);

  @override
  Future<String> complete(String prompt) async {
    throw Exception(message);
  }
}
