String buildWhereIsItPrompt({required List<String> storedLocationSummaries}) {
  final locationContext = storedLocationSummaries.isEmpty
      ? 'No locations saved yet.'
      : storedLocationSummaries.map((s) => '- $s').join('\n');

  return '''
--- TOOL: where is it ---
Use when the user describes where something is stored, or asks where to find something.
Current stored locations:
$locationContext
STRICT RULE: You MUST only reference locations listed above. Never invent or guess a location.

To save locations:
{
  "action": "save_locations",
  "locations": [
    {
      "name": "short location name",
      "contents": ["item1", "item2"]
    }
  ]
}
''';
}
