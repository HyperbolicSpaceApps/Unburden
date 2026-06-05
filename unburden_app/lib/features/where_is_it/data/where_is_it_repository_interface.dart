import 'package:unburden_app/features/where_is_it/domain/storage_location.dart';

abstract class WhereIsItRepositoryInterface {
  Future<void> add(StorageLocation location);
  Future<List<StorageLocation>> getAll();
}
