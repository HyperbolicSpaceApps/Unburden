import 'dart:convert';

import 'package:unburden_app/core/app_database.dart';
import 'package:unburden_app/features/space_manager/data/space_repository_interface.dart';
import 'package:unburden_app/features/space_manager/domain/storage_location.dart';

class SpaceRepository implements SpaceRepositoryInterface {
  final AppDatabase database;

  SpaceRepository({required this.database});

  @override
  Future<void> init() async {
    await database.db;
  }

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
      'width_cm': location.widthCm,
      'depth_cm': location.depthCm,
      'height_cm': location.heightCm,
      'contents': jsonEncode(location.contents),
      'access_note': location.accessNote,
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
            widthCm: (row['width_cm'] as num?)?.toDouble(),
            depthCm: (row['depth_cm'] as num?)?.toDouble(),
            heightCm: (row['height_cm'] as num?)?.toDouble(),
            contents: List<String>.from(jsonDecode(row['contents'] as String)),
            accessNote: row['access_note'] as String,
          ),
        )
        .toList();
  }
}
