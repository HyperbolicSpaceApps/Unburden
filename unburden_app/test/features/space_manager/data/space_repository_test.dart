import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
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
      repo = SpaceRepository(dbPath: 'file:test_${dbCounter++}?mode=memory&cache=shared');
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
      expect(all.length, 1); // TODO: merge contents on duplicate instead of silently dropping
    });
  });
}
