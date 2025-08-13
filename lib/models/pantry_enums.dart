enum FoodCategory {
  produce('Produce'),
  dairy('Dairy'),
  grains('Grains'),
  protein('Protein'),
  baking('Baking'),
  herbsAndSpices('Herbs & Spices'),
  bakery('Bakery'),
  condiments('Condiments'),
  frozenFoods('Frozen Foods'),
  beverages('Beverages'),
  snacks('Snacks'),
  other('Other');

  final String display;
  const FoodCategory(this.display);

  static FoodCategory fromString(String value) {
    return FoodCategory.values.firstWhere(
      (category) => category.display.toLowerCase() == value.toLowerCase(),
      orElse: () => FoodCategory.other,
    );
  }
}

enum StorageLocation {
  pantry('Pantry'),
  fridge('Fridge'),
  freezer('Freezer');

  final String display;
  const StorageLocation(this.display);

  static StorageLocation fromString(String value) {
    return StorageLocation.values.firstWhere(
      (location) => location.display.toLowerCase() == value.toLowerCase(),
      orElse: () => StorageLocation.pantry,
    );
  }
}

extension FoodCategoryExtension on FoodCategory {
  Duration get defaultShelfLife {
    switch (this) {
      case FoodCategory.produce:
        return const Duration(days: 5);
      case FoodCategory.dairy:
        return const Duration(days: 7);
      case FoodCategory.grains:
        return const Duration(days: 180);
      case FoodCategory.herbsAndSpices:
      case FoodCategory.baking:
        return const Duration(days: 365);
      case FoodCategory.bakery:
        return const Duration(days: 7);
      case FoodCategory.condiments:
        return const Duration(days: 30);
      case FoodCategory.protein:
        // Default to fridge duration, storage location will modify this
        return const Duration(days: 3);
      case FoodCategory.frozenFoods:
        return const Duration(days: 120);
      case FoodCategory.beverages:
        return const Duration(days: 12);
      case FoodCategory.snacks:
        return const Duration(days: 90);
      case FoodCategory.other:
        return const Duration(days: 30);
    }
  }

  Duration getShelfLife(StorageLocation storageLocation) {
    if (this == FoodCategory.protein) {
      switch (storageLocation) {
        case StorageLocation.freezer:
          return const Duration(days: 60);
        case StorageLocation.fridge:
        case StorageLocation.pantry:
          return const Duration(days: 3);
      }
    }
    return defaultShelfLife;
  }
}
