String buildChatPrompt({required String userInput, required List<String> storedLocationSummaries}) {
  final context = storedLocationSummaries.isEmpty
      ? 'No locations saved yet.'
      : storedLocationSummaries.map((s) => '- $s').join('\n');

  return '''
You are a home space assistant. You help the user manage and optimize their storage spaces.

Current stored locations:
$context

User message: "$userInput"

You MUST respond ONLY with a valid JSON object. No prose, no markdown, no explanation outside the JSON.

If the user is describing storage locations to save, save each distinct physical zone (shelf level, drawer, box, surface) as a separate location:
{
  "action": "save_locations",
  "locations": [
    {
      "name": "short location name",
      "width_cm": 0.0,
      "depth_cm": 0.0,
      "height_cm": 0.0,
      "contents": ["item1", "item2"],
      "access_note": "how hard to reach"
    }
  ],
  "message": "your natural confirmation message"
}

If the user is asking a question or having a conversation:
{
  "action": "answer",
  "message": "your natural response"
}
''';
}
