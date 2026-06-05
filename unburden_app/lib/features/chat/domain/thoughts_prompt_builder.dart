String buildThoughtsPrompt() {
  return '''
You capture user thoughts, observations, and ideas.

To store a thought:
{
  "action": "add_thought",
  "text": "the thought to capture"
}
''';
}
