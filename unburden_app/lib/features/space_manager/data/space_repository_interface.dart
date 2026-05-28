import 'package:unburden_app/features/space_manager/domain/storage_location.dart';

abstract class SpaceRepositoryInterface {
  Future<void> init();
  Future<void> add(StorageLocation location);
  Future<List<StorageLocation>> getAll();
}
