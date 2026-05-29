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

    // Extract the user input from the prompt to use as name
    final match = RegExp(r'"([^"]+)"').firstMatch(prompt);
    final name = match?.group(1) ?? 'unknown location';

    final response =
        '''
{
  "action": "save_locations",
  "locations": [
    {
      "name": "$name",
      "width_cm": 0.0,
      "depth_cm": 0.0,
      "height_cm": 0.0,
      "contents": [],
      "access_note": ""
    }
  ],
  "message": "Got it, I've saved $name."
}
''';
    AppLogger.mock('returning response: $response');
    return response;
  }
}
