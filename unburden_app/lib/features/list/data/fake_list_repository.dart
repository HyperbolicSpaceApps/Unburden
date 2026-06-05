import 'package:unburden_app/features/list/data/list_repository_interface.dart';

class FakeListRepository implements ListRepositoryInterface {
  final List<String> _store = [];

  @override
  Future<void> addAll(List<String> items) async {
    _store.addAll(items);
  }

  @override
  Future<List<String>> getAll() async => List.from(_store);

  @override
  Future<void> clear() async => _store.clear();
}
