const _defaultDescriptions = {
  'grocery':
      'Use when the user mentions buying something, needing to purchase something, or adding items to a shopping list.',
  'todo':
      'Use when the user mentions a task, errand, or something they need to do or remember to do.',
  'thoughts':
      'Use when the user shares a personal feeling, reflection, observation, memory, or any thought they want to remember.',
};

String buildListToolPrompt({
  required String listName,
  required List<String> storedItems,
  List<String> toolRules = const [],
  String? useWhen,
}) {
  final context =
      storedItems.isEmpty ? 'No items yet.' : storedItems.map((i) => '- $i').join('\n');
  final rulesSection =
      toolRules.isEmpty ? '' : '\nUser rules:\n${toolRules.map((r) => '- $r').join('\n')}\n';
  final trigger =
      useWhen ??
      _defaultDescriptions[listName] ??
      'Use when the user names items to add to their $listName, or confirms adding after clarification.';

  return '''
--- LIST: $listName ---
$trigger
If the user only says "$listName" or asks to see the list, respond with:
{
  "action": "answer",
  "message": "Your $listName: item1, item2, ..."
}
$rulesSection
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
