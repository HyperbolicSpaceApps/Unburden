import 'package:unburden_app/features/grocery/data/grocery_repository_interface.dart';
import 'package:unburden_app/features/grocery/domain/grocery_item.dart';

class FakeGroceryRepository implements GroceryRepositoryInterface {
  final List<GroceryItem> _store = [];

  @override
  Future<void> add(GroceryItem item) async {
    final exists = _store.any((i) => i.name == item.name);
    if (!exists) _store.add(item);
  }

  @override
  Future<List<GroceryItem>> getAll() async => List.from(_store);
}
