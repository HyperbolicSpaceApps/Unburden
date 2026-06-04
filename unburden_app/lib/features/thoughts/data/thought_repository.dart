import 'package:unburden_app/core/app_database.dart';
import 'package:unburden_app/features/thoughts/data/thought_repository_interface.dart';
import 'package:unburden_app/features/thoughts/domain/thought_entry.dart';

class ThoughtRepository implements ThoughtRepositoryInterface {
  final AppDatabase database;

  ThoughtRepository({required this.database});

  @override
  Future<void> add(ThoughtEntry entry) async {
    final db = await database.db;
    await db.insert('thoughts', {
      'text': entry.text,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<List<ThoughtEntry>> getAll() async {
    final db = await database.db;
    final rows = await db.query('thoughts', orderBy: 'created_at ASC');
    return rows.map((row) => ThoughtEntry(text: row['text'] as String)).toList();
  }
}
