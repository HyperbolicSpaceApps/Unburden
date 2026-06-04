import 'package:unburden_app/features/grocery/domain/grocery_item.dart';

abstract class GroceryRepositoryInterface {
  Future<void> add(GroceryItem item);
  Future<List<GroceryItem>> getAll();
}
