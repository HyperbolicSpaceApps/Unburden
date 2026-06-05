import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:unburden_app/core/app_database.dart';
import 'package:unburden_app/features/space_manager/data/fake_space_repository.dart';
import 'package:unburden_app/features/space_manager/data/space_repository.dart';
import 'package:unburden_app/features/space_manager/domain/storage_location.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SpaceRepository', () {
    late SpaceRepository repo;
    int dbCounter = 0;

    setUp(() async {
      final db = AppDatabase(dbPath: 'file:test_${dbCounter++}?mode=memory&cache=shared');
      repo = SpaceRepository(database: db);
      await repo.init();
    });

    test('add and retrieve a storage location', () async {
      final location = StorageLocation(
        name: 'Top wardrobe shelf',
        widthCm: 80,
        depthCm: 40,
        heightCm: 30,
        contents: ['winter coats', 'Christmas decorations'],
        accessNote: 'escabeau needed',
      );

      await repo.add(location);
      final results = await repo.getAll();

      expect(results.length, 1);
      expect(results.first.name, 'Top wardrobe shelf');
      expect(results.first.contents, contains('winter coats'));
    });

    test('adding the same location twice does not create a duplicate in Fake repo', () async {
      final fakeRepo = FakeSpaceRepository();
      await fakeRepo.init();

      final location = StorageLocation(
        name: 'top wardrobe shelf',
        widthCm: 80.0,
        depthCm: 40.0,
        heightCm: 30.0,
        contents: ['winter coats'],
        accessNote: 'need the escabeau',
      );

      await fakeRepo.add(location);
      await fakeRepo.add(location);

      final all = await fakeRepo.getAll();
      expect(all.length, 1);
    });

    test('adding the same location twice does not create a duplicate in SQLite', () async {
      final location = StorageLocation(
        name: 'top wardrobe shelf',
        widthCm: 80.0,
        depthCm: 40.0,
        heightCm: 30.0,
        contents: ['winter coats'],
        accessNote: 'need the escabeau',
      );

      await repo.add(location);
      await repo.add(location);

      final all = await repo.getAll();
      expect(all.length, 1);
    });
  });

  group('persistence across app restart', () {
    const dbPath = 'test_persistence_space.db';

    tearDown(() async {
      final file = File(dbPath);
      if (await file.exists()) await file.delete();
    });

    test('data written by one instance is readable by a new instance on the same path', () async {
      final db1 = AppDatabase(dbPath: dbPath);
      final repo1 = SpaceRepository(database: db1);
      await repo1.add(StorageLocation(
        name: 'hallway shelf',
        contents: ['tools'],
        accessNote: '',
      ));

      final db2 = AppDatabase(dbPath: dbPath);
      final repo2 = SpaceRepository(database: db2);
      final items = await repo2.getAll();

      expect(items.length, equals(1));
      expect(items.first.name, equals('hallway shelf'));
    });
  });
}
