
import 'package:unburden_app/core/llm_client.dart';

class MockLlmClient implements LlmClient {
  final String fixedResponse;

  MockLlmClient({required this.fixedResponse});

  @override
  Future<String> complete(String prompt) async {
    return fixedResponse;
  }
}
