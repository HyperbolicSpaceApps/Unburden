import 'package:sqflite/sqflite.dart';

class AppDatabase {
  final String dbPath;
  Database? _db;

  AppDatabase({required this.dbPath});

  Future<Database> get db async {
    if (_db != null) return _db!;
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
        await db.execute('''
          CREATE TABLE grocery_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE thoughts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE todos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }
}
