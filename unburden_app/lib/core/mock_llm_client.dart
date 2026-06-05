import 'package:unburden_app/core/app_logger.dart';
import 'package:unburden_app/core/llm_client.dart';

class MockLlmClient implements LlmClient {
  final String? fixedResponse;

  MockLlmClient({this.fixedResponse});

  @override
  Future<String> complete(String systemPrompt, List<Map<String, String>> messages) async {
    AppLogger.mock('received ${messages.length} messages');

    if (fixedResponse != null) {
      AppLogger.mock('using fixed response: $fixedResponse');
      return fixedResponse!;
    }

    const response = '''
{
  "action": "answer",
  "message": "I'm not sure how to help with that yet."
}
''';
    AppLogger.mock('returning default response');
    return response;
  }
}
