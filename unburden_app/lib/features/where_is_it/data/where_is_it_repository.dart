import 'dart:convert';

import 'package:unburden_app/core/app_database.dart';
import 'package:unburden_app/features/where_is_it/data/where_is_it_repository_interface.dart';
import 'package:unburden_app/features/where_is_it/domain/storage_location.dart';

class WhereIsItRepository implements WhereIsItRepositoryInterface {
  final AppDatabase database;

  WhereIsItRepository({required this.database});

  @override
  Future<void> add(StorageLocation location) async {
    final db = await database.db;
    final existing = await db.query(
      'storage_locations',
      where: 'name = ?',
      whereArgs: [location.name],
    );
    if (existing.isNotEmpty) return;
    await db.insert('storage_locations', {
      'name': location.name,
      'width_cm': null,
      'depth_cm': null,
      'height_cm': null,
      'contents': jsonEncode(location.contents),
      'access_note': '',
    });
  }

  @override
  Future<List<StorageLocation>> getAll() async {
    final db = await database.db;
    final rows = await db.query('storage_locations');
    return rows
        .map(
          (row) => StorageLocation(
            name: row['name'] as String,
            contents: List<String>.from(jsonDecode(row['contents'] as String)),
          ),
        )
        .toList();
  }
}
