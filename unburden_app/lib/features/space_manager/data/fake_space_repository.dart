import 'package:unburden_app/features/space_manager/data/space_repository_interface.dart';
import 'package:unburden_app/features/space_manager/domain/storage_location.dart';

class FakeSpaceRepository implements SpaceRepositoryInterface {
  final List<StorageLocation> _store = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> add(StorageLocation location) async {
    final exists = _store.any((l) => l.name == location.name);
    if (!exists) _store.add(location);
  }

  @override
  Future<List<StorageLocation>> getAll() async => List.from(_store);
}
