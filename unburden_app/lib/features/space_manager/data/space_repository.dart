import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:unburden_app/features/space_manager/data/space_repository_interface.dart';
import 'package:unburden_app/features/space_manager/domain/storage_location.dart';

class SpaceRepository implements SpaceRepositoryInterface {
  final String dbPath;
  Database? _db;

  SpaceRepository({required this.dbPath});

  @override
  Future<void> init() async {
    if (_db != null) return; // already initialised, do nothing
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE storage_locations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            width_cm REAL,
            depth_cm REAL,
            height_cm REAL,
            contents TEXT,
            access_note TEXT
          )
        ''');
      },
    );
  }

  @override
  Future<void> add(StorageLocation location) async {
    await init(); // guard
    await _db!.insert('storage_locations', {
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
    await init(); // guard
    final rows = await _db!.query('storage_locations');
    return rows.map((row) => StorageLocation(
      name: row['name'] as String,
      widthCm: (row['width_cm'] as num).toDouble(),
      depthCm: (row['depth_cm'] as num).toDouble(),
      heightCm: (row['height_cm'] as num).toDouble(),
      contents: List<String>.from(jsonDecode(row['contents'] as String)),
      accessNote: row['access_note'] as String,
    )).toList();
  }
}