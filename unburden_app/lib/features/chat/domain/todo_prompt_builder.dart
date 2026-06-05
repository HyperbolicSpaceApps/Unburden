String buildTodoPrompt({required List<String> storedTodos}) {
  final todoContext = storedTodos.isEmpty
      ? 'No todos yet.'
      : storedTodos.map((t) => '- $t').join('\n');

  return '''
You manage the user's todo list.

Current todos:
$todoContext

To add a todo item:
{
  "action": "add_todo",
  "text": "the task to remember"
}
''';
}
