import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/pantry_item.dart';
import '../../models/pantry_enums.dart';

class PantryItemDialog extends StatefulWidget {
  final PantryItem? item; // null for new item => add flow

  const PantryItemDialog({super.key, this.item});

  @override
  State<PantryItemDialog> createState() => _PantryItemDialogState();
}

class _PantryItemDialogState extends State<PantryItemDialog> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  String _selectedCategory = 'Pantry Staples';
  String _selectedUnit = 'pieces';
  late DateTime _expirationDate;
  bool _isLowStock = false;
  double _lowStockThreshold = 1;

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
      text: widget.item?.size ?? '1',
    );
    // Map from model (which uses enums) to dialog simple strings if needed
    _selectedCategory = widget.item?.category.display ?? _categories[0];
    _selectedUnit = widget.item?.size ?? _units[0];
    _expirationDate = widget.item?.expirationDate ?? DateTime.now().add(const Duration(days: 7));
    _isLowStock = widget.item?.isLowStock ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
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
              widget.item == null ? 'Add Item' : 'Edit Item',
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Expiration Date'),
              subtitle: Text(
                '${_expirationDate.year}-${_expirationDate.month.toString().padLeft(2, '0')}-${_expirationDate.day.toString().padLeft(2, '0')}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _expirationDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (picked != null) {
                    setState(() {
                      _expirationDate = picked;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable Low Stock Alert'),
              value: _isLowStock,
              onChanged: (value) {
                setState(() {
                  _isLowStock = value;
                });
              },
            ),
            if (_isLowStock) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Low Stock Threshold:'),
                  Expanded(
                    child: Slider(
                      value: _lowStockThreshold,
                      min: 0,
                      max: 10,
                      divisions: 20,
                      label: _lowStockThreshold.toString(),
                      onChanged: (value) {
                        setState(() {
                          _lowStockThreshold = value;
                        });
                      },
                    ),
                  ),
                  Text(_lowStockThreshold.toString()),
                ],
              ),
            ],
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
                    // Map string selections to enums (fallback to defaults)
                    final categoryEnum = FoodCategory.values.firstWhere(
                      (c) => c.display == _selectedCategory,
                      orElse: () => FoodCategory.other,
                    );
                    final locationEnum = StorageLocation.pantry; // dialog lacks location UI here
                    final newItem = widget.item?.copyWith(
                          name: _nameController.text.trim(),
                          size: _quantityController.text.trim(),
                          expirationDate: _expirationDate,
                          isLowStock: _isLowStock,
                          category: categoryEnum,
                          storageLocation: locationEnum,
                        ) ?? PantryItem(
                          name: _nameController.text.trim(),
                          details: null,
                          size: _quantityController.text.trim(),
                          purchaseDate: DateTime.now(),
                          openedDate: null,
                          expirationDate: _expirationDate,
                          category: categoryEnum,
                          storageLocation: locationEnum,
                          isLowStock: _isLowStock,
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
