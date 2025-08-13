import 'pantry_item.dart';
import 'pantry_enums.dart';

class PantryFilter {
  final String? searchTerm;
  final FoodCategory? category;
  final StorageLocation? location;
  final SortCriteria sortBy;
  final bool sortAscending;

  const PantryFilter({
    this.searchTerm,
    this.category,
    this.location,
    this.sortBy = SortCriteria.name,
    this.sortAscending = true,
  });

  bool matches(PantryItem item) {
    if (searchTerm != null && searchTerm!.isNotEmpty) {
      final term = searchTerm!.toLowerCase();
      if (!item.name.toLowerCase().contains(term) &&
          !(item.details?.toLowerCase().contains(term) ?? false)) {
        return false;
      }
    }

    if (category != null && item.category != category) {
      return false;
    }

    if (location != null && item.storageLocation != location) {
      return false;
    }

    return true;
  }

  PantryFilter copyWith({
    String? searchTerm,
    FoodCategory? category,
    StorageLocation? location,
    SortCriteria? sortBy,
    bool? sortAscending,
  }) {
    return PantryFilter(
      searchTerm: searchTerm ?? this.searchTerm,
      category: category ?? this.category,
      location: location ?? this.location,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}

enum SortCriteria {
  name,
  purchaseDate,
  expiryDate;

  String get displayName {
    switch (this) {
      case SortCriteria.name:
        return 'Name';
      case SortCriteria.purchaseDate:
        return 'Purchase Date';
      case SortCriteria.expiryDate:
        return 'Expiry Date';
    }
  }
}
