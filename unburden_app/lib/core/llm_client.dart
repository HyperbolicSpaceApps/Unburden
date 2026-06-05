abstract class LlmClient {
  Future<String> complete(String systemPrompt, List<Map<String, String>> messages);
}
