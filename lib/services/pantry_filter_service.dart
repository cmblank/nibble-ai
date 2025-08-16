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
        case SortCriteria.useFirst:
          int dupScore(PantryItem i) {
            final name = i.name.trim().toLowerCase();
            final count = items.where((x) => x.name.trim().toLowerCase() == name).length;
            return count > 1 ? 0 : 1;
          }
          final primary = dupScore(a).compareTo(dupScore(b));
          final stable = a.expirationDate.compareTo(b.expirationDate);
          cmp = primary != 0 ? primary : stable;
          break;
      }
      return filter.sortAscending ? cmp : -cmp;
    });

    return filtered;
  }
}
