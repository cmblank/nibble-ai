import 'pantry_item.dart';
import 'pantry_enums.dart';

class PantryFilter {
  final String? searchTerm;
  final Set<FoodCategory>? categories;
  final StorageLocation? location;
  final SortCriteria sortBy;
  final bool sortAscending;
  // Quick filters
  final bool onlyLowStock; // when true, show only items marked low stock
  final int? expiringWithinDays; // when set, show items expiring within N days from now

  const PantryFilter({
    this.searchTerm,
    this.categories,
    this.location,
    this.sortBy = SortCriteria.name,
    this.sortAscending = true,
  this.onlyLowStock = false,
  this.expiringWithinDays,
  });

  bool matches(PantryItem item) {
    if (searchTerm != null && searchTerm!.isNotEmpty) {
      final term = searchTerm!.toLowerCase();
      if (!item.name.toLowerCase().contains(term) &&
          !(item.details?.toLowerCase().contains(term) ?? false)) {
        return false;
      }
    }

    final cats = categories;
    if (cats != null && cats.isNotEmpty && !cats.contains(item.category)) return false;

    if (location != null && item.storageLocation != location) {
      return false;
    }

    if (onlyLowStock && item.isLowStock != true) {
      return false;
    }

    final days = expiringWithinDays;
    if (days != null) {
      final now = DateTime.now();
      final cutoff = now.add(Duration(days: days));
      if (item.expirationDate.isAfter(cutoff)) {
        return false;
      }
    }

    return true;
  }

  PantryFilter copyWith({
    String? searchTerm,
    Set<FoodCategory>? categories,
    StorageLocation? location,
    SortCriteria? sortBy,
    bool? sortAscending,
    bool? onlyLowStock,
    int? expiringWithinDays,
  }) {
    return PantryFilter(
      searchTerm: searchTerm ?? this.searchTerm,
      categories: categories ?? this.categories,
      location: location ?? this.location,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
      onlyLowStock: onlyLowStock ?? this.onlyLowStock,
      expiringWithinDays: expiringWithinDays ?? this.expiringWithinDays,
    );
  }
}

enum SortCriteria {
  name,
  purchaseDate,
  expiryDate,
  useFirst;

  String get displayName {
    switch (this) {
      case SortCriteria.name:
        return 'Name';
      case SortCriteria.purchaseDate:
        return 'Date Added';
      case SortCriteria.expiryDate:
        return 'Expiring Soon';
      case SortCriteria.useFirst:
        return 'Use First';
    }
  }
}
