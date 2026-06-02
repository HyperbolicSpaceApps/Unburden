import 'package:flutter_test/flutter_test.dart';
import 'package:unburden_app/features/grocery/data/fake_grocery_repository.dart';
import 'package:unburden_app/features/grocery/domain/grocery_item.dart';

void main() {
  group('GroceryRepository', () {
    test('stored item is returned by getAll', () async {
      final repo = FakeGroceryRepository();
      await repo.add(GroceryItem(name: 'potatoes'));

      final items = await repo.getAll();

      expect(items.length, equals(1));
      expect(items.first.name, equals('potatoes'));
    });

    test('duplicate item is not stored twice', () async {
      final repo = FakeGroceryRepository();
      await repo.add(GroceryItem(name: 'milk'));
      await repo.add(GroceryItem(name: 'milk'));

      final items = await repo.getAll();

      expect(items.length, equals(1));
    });

    test('multiple distinct items are all stored', () async {
      final repo = FakeGroceryRepository();
      await repo.add(GroceryItem(name: 'potatoes'));
      await repo.add(GroceryItem(name: 'milk'));

      final items = await repo.getAll();

      expect(items.length, equals(2));
    });
  });
}
