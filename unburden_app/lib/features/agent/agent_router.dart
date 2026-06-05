enum Tool { grocery, thoughts, space, todo }

// TODO(routing): keyword matching is a placeholder.
// Replace with LLM-based routing once the tool set stabilises.
// The test contract in agent_router_test.dart defines the expected behaviour
// and should remain unchanged when the implementation is swapped.
Tool routeInput(String input) {
  final lower = input.toLowerCase();

  const groceryKeywords = [
    'need',
    'buy',
    'pick up',
    'get',
    'milk',
    'eggs',
    'potatoes',
    'shopping',
    'grocery',
    'groceries',
    'store',
  ];

  const thoughtKeywords = [
    'like',
    'love',
    'hate',
    'think',
    'feel',
    'idea',
    'thought',
    'interesting',
    'noticed',
    'today',
    'sunset',
    'app',
  ];

  const todoKeywords = [
    'todo',
    'to-do',
    'to do',
    'remind me',
    'remember to',
    'don\'t forget',
    'add to my list',
  ];

  if (groceryKeywords.any((k) => lower.contains(k))) return Tool.grocery;
  if (todoKeywords.any((k) => lower.contains(k))) return Tool.todo;
  if (thoughtKeywords.any((k) => lower.contains(k))) return Tool.thoughts;

  return Tool.thoughts;
}
