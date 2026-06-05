import 'package:unburden_app/features/todo/data/todo_repository_interface.dart';
import 'package:unburden_app/features/todo/domain/todo_item.dart';

class FakeTodoRepository implements TodoRepositoryInterface {
  final List<TodoItem> _store = [];

  @override
  Future<void> add(TodoItem item) async {
    _store.add(item);
  }

  @override
  Future<List<TodoItem>> getAll() async => List.from(_store);
}
