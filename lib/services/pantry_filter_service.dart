import '../models/pantry_item.dart';
import '../models/pantry_filter.dart';

class PantryFilterService {
  List<PantryItem> filterAndSort(List<PantryItem> items, PantryFilter filter) {
    // Filter
    var filtered = items.where(filter.matches).toList();

    // Sort
    filtered.sort((a, b) {
      int cmp;
      switch (filter.sortBy) {
        case SortCriteria.name:
          cmp = a.name.compareTo(b.name);
          break;
        case SortCriteria.purchaseDate:
          cmp = a.purchaseDate.compareTo(b.purchaseDate);
          break;
        case SortCriteria.expiryDate:
          cmp = a.expirationDate.compareTo(b.expirationDate);
          break;
      }
      return filter.sortAscending ? cmp : -cmp;
    });

    return filtered;
  }
}
