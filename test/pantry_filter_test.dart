import 'package:flutter_test/flutter_test.dart';
import 'package:nibble_ai/models/pantry_item.dart';
import 'package:nibble_ai/models/pantry_filter.dart';
import 'package:nibble_ai/models/pantry_enums.dart';
import 'package:nibble_ai/services/pantry_filter_service.dart';

void main() {
  group('PantryFilterService', () {
    final now = DateTime.now();
    final items = [
      PantryItem(
        id: '1',
        name: 'Milk',
        details: 'Whole dairy',
        size: '1L',
        purchaseDate: now.subtract(const Duration(days: 1)),
        category: FoodCategory.dairy,
        storageLocation: StorageLocation.fridge,
      ),
      PantryItem(
        id: '2',
        name: 'Almonds',
        details: 'Raw whole',
        size: '200g',
        purchaseDate: now.subtract(const Duration(days: 10)),
        category: FoodCategory.snacks,
        storageLocation: StorageLocation.pantry,
      ),
    ];
    final service = PantryFilterService();

    test('search term filters by name or details', () {
      final filter = const PantryFilter(searchTerm: 'milk');
      final result = service.filterAndSort(items, filter);
      expect(result.map((e) => e.name), ['Milk']);
    });

    test('category filter applies', () {
      final filter = const PantryFilter(categories: {FoodCategory.snacks});
      final result = service.filterAndSort(items, filter);
      expect(result.length, 1);
      expect(result.first.name, 'Almonds');
    });

    test('sort by purchase date descending', () {
      final filter = const PantryFilter(sortBy: SortCriteria.purchaseDate, sortAscending: false);
      final result = service.filterAndSort(items, filter);
      expect(result.first.name, 'Milk'); // newer purchase date
    });
  });
}
