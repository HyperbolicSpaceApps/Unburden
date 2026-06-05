import 'package:unburden_app/core/app_database.dart';
import 'package:unburden_app/features/todo/data/todo_repository_interface.dart';
import 'package:unburden_app/features/todo/domain/todo_item.dart';

class TodoRepository implements TodoRepositoryInterface {
  final AppDatabase database;

  TodoRepository({required this.database});

  @override
  Future<void> add(TodoItem item) async {
    final db = await database.db;
    await db.insert('todos', {
      'text': item.text,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<List<TodoItem>> getAll() async {
    final db = await database.db;
    final rows = await db.query('todos', orderBy: 'created_at ASC');
    return rows.map((row) => TodoItem(text: row['text'] as String)).toList();
  }
}
