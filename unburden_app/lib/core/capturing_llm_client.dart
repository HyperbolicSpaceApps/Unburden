import 'package:unburden_app/core/llm_client.dart';

class CapturingLlmClient implements LlmClient {
  final List<String> responses;
  final List<List<Map<String, String>>> capturedMessages = [];
  int _callCount = 0;

  CapturingLlmClient({required this.responses});

  @override
  Future<String> complete(String systemPrompt, List<Map<String, String>> messages) async {
    capturedMessages.add(List.unmodifiable(messages));
    final response = responses[_callCount];
    _callCount++;
    return response;
  }
}
