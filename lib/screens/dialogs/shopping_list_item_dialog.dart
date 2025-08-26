import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/shopping_list_item.dart';
import '../../utils/ingredient_categorizer.dart';

class ShoppingListItemDialog extends StatefulWidget {
  final ShoppingListItem? item;

  const ShoppingListItemDialog({
    super.key,
    this.item,
  });

  @override
  State<ShoppingListItemDialog> createState() => _ShoppingListItemDialogState();
}

class _ShoppingListItemDialogState extends State<ShoppingListItemDialog> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _noteController;
  String _selectedCategory = 'Produce';
  String _selectedUnit = 'pieces';

  final List<String> _categories = [
    'Produce',
    'Proteins',
    'Dairy',
    'Pantry Staples',
    'Spices',
    'Beverages',
    'Snacks',
    'Condiments',
    'Baking',
  ];

  final List<String> _units = [
    'pieces',
    'grams',
    'kg',
    'ml',
    'L',
    'cups',
    'tbsp',
    'tsp',
    'oz',
    'lb',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _quantityController = TextEditingController(
      text: widget.item?.quantity.toString() ?? '1',
    );
    _noteController = TextEditingController(text: widget.item?.note ?? '');
    _selectedCategory = widget.item?.category ?? _categories[0];
    _selectedUnit = widget.item?.unit ?? _units[0];

    // Listen to name changes to auto-suggest category when adding new
    if (widget.item == null) {
      _nameController.addListener(_maybeSuggestCategory);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _maybeSuggestCategory() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final suggested = IngredientCategorizer.categorize(name, fallback: _selectedCategory);
    if (suggested != _selectedCategory) {
      setState(() { _selectedCategory = suggested; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.item == null ? 'Add to Shopping List' : 'Edit Item',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    items: _units.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUnit = value!;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    final newItem = ShoppingListItem(
                      name: _nameController.text,
                      category: _selectedCategory,
                      quantity: double.parse(_quantityController.text),
                      unit: _selectedUnit,
                      note: _noteController.text.isEmpty ? null : _noteController.text,
                      source: 'manual',
                    );
                    Navigator.of(context).pop(newItem);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gardenHerb,
                  ),
                  child: Text(widget.item == null ? 'Add' : 'Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
