String buildListToolPrompt({required String listName, required List<String> storedItems}) {
  final context =
      storedItems.isEmpty ? 'No items yet.' : storedItems.map((i) => '- $i').join('\n');

  return '''
--- LIST: $listName ---
Use when the user names items to add to their $listName, or confirms adding after clarification.
If the user only says "$listName" or asks to see the list, respond with:
{
  "action": "answer",
  "message": "Your $listName: item1, item2, ..."
}

Current $listName:
$context

To add items:
{
  "action": "add_to_list",
  "list": "$listName",
  "items": ["item 1", "item 2"]
}
''';
}
