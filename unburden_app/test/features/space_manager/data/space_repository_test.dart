import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:unburden_app/features/space_manager/data/space_repository.dart';
import 'package:unburden_app/features/space_manager/domain/storage_location.dart';

void main() {
  setUpAll(() {
    // Use in-memory SQLite so tests run without a phone
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SpaceRepository', () {
    test('add and retrieve a storage location', () async {
      final repo = SpaceRepository(dbPath: inMemoryDatabasePath);
      await repo.init();

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
  });
}