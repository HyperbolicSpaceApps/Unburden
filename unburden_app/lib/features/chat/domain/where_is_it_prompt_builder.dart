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
- Search the stored locations above for that specific item in the contents list.
- Only answer with a location if that exact item (or a close match) appears in its contents.
- If the item is NOT listed in any location's contents, say you don't have a record of where it is. Do NOT mention any location.
Use the answer action:
{
  "action": "answer",
  "message": "your response"
}

When the user TELLS you about a location or where something is stored, save it:
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
