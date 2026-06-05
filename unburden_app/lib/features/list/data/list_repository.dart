import 'package:unburden_app/core/app_database.dart';
import 'package:unburden_app/features/list/data/list_repository_interface.dart';

class ListRepository implements ListRepositoryInterface {
  final AppDatabase database;
  final String listName;

  ListRepository({required this.database, required this.listName});

  @override
  Future<void> addAll(List<String> items) async {
    final db = await database.db;
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final item in items) {
      await db.insert('list_items', {'list_name': listName, 'text': item, 'created_at': now});
    }
  }

  @override
  Future<List<String>> getAll() async {
    final db = await database.db;
    final rows = await db.query(
      'list_items',
      where: 'list_name = ?',
      whereArgs: [listName],
      orderBy: 'created_at ASC',
    );
    return rows.map((row) => row['text'] as String).toList();
  }
}
