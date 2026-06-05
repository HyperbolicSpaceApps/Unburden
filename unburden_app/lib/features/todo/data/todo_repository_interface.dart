import 'package:unburden_app/features/todo/domain/todo_item.dart';

abstract class TodoRepositoryInterface {
  Future<void> add(TodoItem item);
  Future<List<TodoItem>> getAll();
}
