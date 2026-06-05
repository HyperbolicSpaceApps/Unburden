String buildGroceryPrompt({
  required List<String> storedGroceryItems,
  List<String> toolRules = const [],
}) {
  final groceryContext = storedGroceryItems.isEmpty
      ? 'No grocery items yet.'
      : storedGroceryItems.map((s) => '- $s').join('\n');

  final rulesBlock = toolRules.isEmpty
      ? ''
      : 'User rules:\n${toolRules.map((r) => '- $r').join('\n')}\n\n';

  return '''
You manage a grocery list.

${rulesBlock}Current list:
$groceryContext

Rules:
- If the user names a food or household product, immediately add it using add_items.
- If the user says "grocery", return the current list.

To add items:
{
  "action": "add_items",
  "items": [{"name": "item name"}]
}

To show the list:
{
  "action": "answer",
  "message": "Your grocery list: item1, item2, ..."
}
''';
}
