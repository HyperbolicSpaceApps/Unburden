String buildWhereIsItPrompt({required List<String> storedLocationSummaries}) {
  final locationContext = storedLocationSummaries.isEmpty
      ? 'No locations saved yet.'
      : storedLocationSummaries.map((s) => '- $s').join('\n');

  return '''
--- TOOL: where is it ---
Current stored locations:
$locationContext
STRICT RULE: You MUST only reference locations listed above. Never invent or guess a location.

When the user ASKS where something is (e.g. "where are my comic books?"):
- Check each location's contents list for the asked item.
- Only name a location if the item is explicitly listed in its contents. No guessing, no inference.
- If the item does not appear in any contents list, respond that you have no record of it. Do NOT name any location.
Use the answer action:
{
  "action": "answer",
  "message": "your response"
}

When the user TELLS you about a location or where something is stored, save it.
Do NOT use save_locations when the message is a task, errand, or something to remember to do.
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
