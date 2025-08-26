class ShoppingListItem {
  final String? id;
  final String name;
  final String category;
  final double quantity;
  final String unit;
  final bool isChecked; // purchased flag
  final String? note;
  final String source; // 'manual', 'pantry', 'recipe', 'receipt'

  ShoppingListItem({
    this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    this.isChecked = false,
    this.note,
    required this.source,
  });

  ShoppingListItem copyWith({
    String? id,
    String? name,
    String? category,
    double? quantity,
    String? unit,
    bool? isChecked,
    String? note,
    String? source,
  }) => ShoppingListItem(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    isChecked: isChecked ?? this.isChecked,
    note: note ?? this.note,
    source: source ?? this.source,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    'category': category,
    'quantity': quantity,
    'unit': unit,
  'is_purchased': isChecked,
    'note': note,
    'source': source,
  };

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) => ShoppingListItem(
    id: json['id']?.toString(),
    name: json['name'] as String,
    category: json['category'] as String? ?? 'Other',
    quantity: (json['quantity'] is int)
        ? (json['quantity'] as int).toDouble()
        : (json['quantity'] as num?)?.toDouble() ?? 1,
    unit: json['unit'] as String? ?? '',
  isChecked: (json['is_purchased'] as bool?) ?? (json['isChecked'] as bool?) ?? false,
    note: json['note'] as String?,
    source: json['source'] as String? ?? 'manual',
  );
}
