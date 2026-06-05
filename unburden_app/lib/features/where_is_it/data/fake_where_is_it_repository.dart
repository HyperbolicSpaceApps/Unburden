import 'package:unburden_app/features/where_is_it/data/where_is_it_repository_interface.dart';
import 'package:unburden_app/features/where_is_it/domain/storage_location.dart';

class FakeWhereIsItRepository implements WhereIsItRepositoryInterface {
  final List<StorageLocation> _store = [];

  @override
  Future<void> add(StorageLocation location) async {
    final exists = _store.any((l) => l.name == location.name);
    if (!exists) _store.add(location);
  }

  @override
  Future<List<StorageLocation>> getAll() async => List.from(_store);
}
