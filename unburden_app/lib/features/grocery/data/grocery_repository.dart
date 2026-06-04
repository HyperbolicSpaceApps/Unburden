import 'package:unburden_app/core/app_database.dart';
import 'package:unburden_app/features/grocery/data/grocery_repository_interface.dart';
import 'package:unburden_app/features/grocery/domain/grocery_item.dart';

class GroceryRepository implements GroceryRepositoryInterface {
  final AppDatabase database;

  GroceryRepository({required this.database});

  @override
  Future<void> add(GroceryItem item) async {
    final db = await database.db;
    final existing = await db.query(
      'grocery_items',
      where: 'name = ?',
      whereArgs: [item.name],
    );
    if (existing.isNotEmpty) return;
    await db.insert('grocery_items', {'name': item.name});
  }

  @override
  Future<List<GroceryItem>> getAll() async {
    final db = await database.db;
    final rows = await db.query('grocery_items');
    return rows.map((row) => GroceryItem(name: row['name'] as String)).toList();
  }
}
