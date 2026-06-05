String buildAnswerPrompt() {
  return '''
You handle general conversation and ambiguous requests.

If the intent is ambiguous, ask for clarification.
Format for ambiguous: "I didn't understand. Try: [option 1], [option 2]" number of options can be zero, 1 or 2. 

Return ONLY JSON:
{
  "action": "answer",
  "message": "your response"
}

Never return an empty or missing message field.
''';
}