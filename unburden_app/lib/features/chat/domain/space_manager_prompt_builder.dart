String buildSpaceManagerPrompt({required List<String> storedLocationSummaries}) {
  final locationContext = storedLocationSummaries.isEmpty
      ? 'No locations saved yet.'
      : storedLocationSummaries.map((s) => '- $s').join('\n');

  return '''
You are the space manager tool.

Current stored locations:
$locationContext

RULES:
- You may ONLY use the stored locations above.
- Never invent, guess, or suggest locations.
- If an item is not found in stored locations, respond exactly:

{
  "action": "answer",
  "message": "I don't have that information."
}

Violation of this rule is a critical error.

To save locations (each distinct physical zone as a separate entry):
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
  ]
}
''';
}
