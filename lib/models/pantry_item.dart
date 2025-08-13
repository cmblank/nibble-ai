import 'pantry_enums.dart';

class PantryItem {
  final String? id;
  final String name;
  final String? details;
  final String? size;
  final DateTime purchaseDate;
  final DateTime? openedDate;
  final DateTime expirationDate;
  final FoodCategory category;
  final StorageLocation storageLocation;
  final bool isLowStock;
  final double? lowStockThreshold;

  PantryItem({
    this.id,
    required this.name,
    this.details,
    this.size,
    required this.purchaseDate,
    this.openedDate,
    DateTime? expirationDate,
    required this.category,
    required this.storageLocation,
    this.isLowStock = false,
    this.lowStockThreshold,
  }) : expirationDate = expirationDate ?? _calculateExpiryDate(
          category: category,
          storageLocation: storageLocation,
          purchaseDate: purchaseDate,
          openedDate: openedDate,
        );

  static DateTime _calculateExpiryDate({
    required FoodCategory category,
    required StorageLocation storageLocation,
    required DateTime purchaseDate,
    DateTime? openedDate,
  }) {
    if (category == FoodCategory.condiments && openedDate != null) {
      return openedDate.add(category.defaultShelfLife);
    }

    if (category == FoodCategory.beverages && openedDate != null) {
      return openedDate.add(category.defaultShelfLife);
    }

    final shelfLife = category.getShelfLife(storageLocation);
    return purchaseDate.add(shelfLife);
  }

  factory PantryItem.fromJson(Map<String, dynamic> json) {
    return PantryItem(
      id: json['id'] as String?,
      name: json['name'] as String,
      details: json['details'] as String?,
      size: json['size'] as String?,
      purchaseDate: DateTime.parse(json['purchase_date'] as String),
      openedDate: json['opened_date'] != null 
          ? DateTime.parse(json['opened_date'] as String) 
          : null,
      expirationDate: json['expiration_date'] != null 
          ? DateTime.parse(json['expiration_date'] as String)
          : null,
      category: FoodCategory.fromString(json['category'] as String),
      storageLocation: StorageLocation.fromString(json['storage_location'] as String),
      isLowStock: json['is_low_stock'] as bool? ?? false,
      lowStockThreshold: json['low_stock_threshold'] as double?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    if (details != null) 'details': details,
    if (size != null) 'size': size,
    'purchase_date': purchaseDate.toIso8601String(),
    if (openedDate != null) 'opened_date': openedDate!.toIso8601String(),
    'expiration_date': expirationDate.toIso8601String(),
    'category': category.display,
    'storage_location': storageLocation.display,
    'is_low_stock': isLowStock,
    if (lowStockThreshold != null) 'low_stock_threshold': lowStockThreshold,
  };

  PantryItem copyWith({
    String? id,
    String? name,
    String? details,
    String? size,
    DateTime? purchaseDate,
    DateTime? openedDate,
    DateTime? expirationDate,
    FoodCategory? category,
    StorageLocation? storageLocation,
    bool? isLowStock,
    double? lowStockThreshold,
  }) {
    return PantryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      details: details ?? this.details,
      size: size ?? this.size,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      openedDate: openedDate ?? this.openedDate,
      expirationDate: expirationDate,
      category: category ?? this.category,
      storageLocation: storageLocation ?? this.storageLocation,
      isLowStock: isLowStock ?? this.isLowStock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    );
  }

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is PantryItem &&
    runtimeType == other.runtimeType &&
    id == other.id &&
    name == other.name &&
    details == other.details &&
    size == other.size &&
    purchaseDate == other.purchaseDate &&
    openedDate == other.openedDate &&
    expirationDate == other.expirationDate &&
    category == other.category &&
    storageLocation == other.storageLocation &&
    isLowStock == other.isLowStock &&
    lowStockThreshold == other.lowStockThreshold;

  @override
  int get hashCode =>
    id.hashCode ^
    name.hashCode ^
    details.hashCode ^
    size.hashCode ^
    purchaseDate.hashCode ^
    openedDate.hashCode ^
    expirationDate.hashCode ^
    category.hashCode ^
    storageLocation.hashCode ^
    isLowStock.hashCode ^
    lowStockThreshold.hashCode;
}
