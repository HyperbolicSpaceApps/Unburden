import 'package:unburden_app/core/app_logger.dart';
import 'package:unburden_app/core/llm_client.dart';

class MockLlmClient implements LlmClient {
  final String? fixedResponse;

  MockLlmClient({this.fixedResponse});

  @override
  Future<String> complete(String prompt) async {
    AppLogger.mock('received prompt: $prompt');

    if (fixedResponse != null) {
      AppLogger.mock('using fixed response: $fixedResponse');
      return fixedResponse!;
    }

    final response = '''
{
  "action": "answer",
  "message": "I'm not sure how to help with that yet."
}
''';
    AppLogger.mock('returning response: $response');
    return response;
  }
}
