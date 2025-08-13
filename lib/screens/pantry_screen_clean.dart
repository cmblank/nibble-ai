import 'package:flutter/material.dart';
import '../models/pantry_item.dart';
import '../models/pantry_filter.dart';
import '../models/pantry_enums.dart';
import '../widgets/nibble_app_bar.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  List<PantryItem> _items = [];
  final bool _isLoading = false;
  PantryFilter _filter = const PantryFilter();
  
  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    // For now, create some sample data
    setState(() {
      _items = [
        PantryItem(
          id: '1',
          name: 'Milk',
          details: '2% Milk',
          purchaseDate: DateTime.now().subtract(const Duration(days: 2)),
          category: FoodCategory.dairy,
          storageLocation: StorageLocation.fridge,
        ),
        PantryItem(
          id: '2',
          name: 'Bread',
          details: 'Whole wheat bread',
          purchaseDate: DateTime.now().subtract(const Duration(days: 1)),
          category: FoodCategory.bakery,
          storageLocation: StorageLocation.pantry,
        ),
        PantryItem(
          id: '3',
          name: 'Apples',
          details: 'Red delicious apples',
          purchaseDate: DateTime.now(),
          category: FoodCategory.produce,
          storageLocation: StorageLocation.fridge,
          isLowStock: true,
        ),
      ];
    });
  }

  List<PantryItem> get _filteredItems {
    var filtered = _items.where((item) => _filter.matches(item)).toList();
    
    // Sort items
    filtered.sort((a, b) {
      switch (_filter.sortBy) {
        case SortCriteria.name:
          final result = a.name.compareTo(b.name);
          return _filter.sortAscending ? result : -result;
        case SortCriteria.purchaseDate:
          final result = a.purchaseDate.compareTo(b.purchaseDate);
          return _filter.sortAscending ? result : -result;
        case SortCriteria.expiryDate:
          final result = a.expirationDate.compareTo(b.expirationDate);
          return _filter.sortAscending ? result : -result;
      }
    });
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NibbleAppBar(
        title: 'My Pantry',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddItemDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildPantryContent(),
    );
  }

  Widget _buildPantryContent() {
    final filteredItems = _filteredItems;
    
    if (filteredItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Your pantry is empty',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              'Add some items to get started!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildPantryItemTile(item);
      },
    );
  }

  Widget _buildPantryItemTile(PantryItem item) {
    final daysUntilExpiry = item.expirationDate.difference(DateTime.now()).inDays;
    final isExpired = daysUntilExpiry < 0;
    final isExpiringSoon = daysUntilExpiry >= 0 && daysUntilExpiry <= 3;
    
    Color? statusColor;
    if (isExpired) {
      statusColor = Colors.red;
    } else if (isExpiringSoon) {
      statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(item.category),
          child: Icon(_getCategoryIcon(item.category), color: Colors.white),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: statusColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.details != null) Text(item.details!),
            Text(
              'Expires: ${_formatDate(item.expirationDate)}',
              style: TextStyle(color: statusColor),
            ),
            Text('Location: ${item.storageLocation.display}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.isLowStock)
              const Icon(Icons.warning, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditItemDialog(item);
                } else if (value == 'delete') {
                  _deleteItem(item);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(FoodCategory category) {
    switch (category) {
      case FoodCategory.produce:
        return Colors.green;
      case FoodCategory.dairy:
        return Colors.blue;
      case FoodCategory.protein:
        return Colors.red;
      case FoodCategory.grains:
        return Colors.brown;
      case FoodCategory.beverages:
        return Colors.cyan;
      case FoodCategory.snacks:
        return Colors.purple;
      case FoodCategory.condiments:
        return Colors.amber;
      case FoodCategory.frozenFoods:
        return Colors.lightBlue;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(FoodCategory category) {
    switch (category) {
      case FoodCategory.produce:
        return Icons.eco;
      case FoodCategory.dairy:
        return Icons.water_drop;
      case FoodCategory.protein:
        return Icons.restaurant;
      case FoodCategory.grains:
        return Icons.grain;
      case FoodCategory.beverages:
        return Icons.local_drink;
      case FoodCategory.snacks:
        return Icons.cookie;
      case FoodCategory.condiments:
        return Icons.room_service;
      case FoodCategory.frozenFoods:
        return Icons.ac_unit;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildAddItemDialog(),
    );
  }

  void _showEditItemDialog(PantryItem item) {
    showDialog(
      context: context,
      builder: (context) => _buildEditItemDialog(item),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildFilterDialog(),
    );
  }

  Widget _buildAddItemDialog() {
    final nameController = TextEditingController();
    final detailsController = TextEditingController();
    FoodCategory selectedCategory = FoodCategory.other;
    StorageLocation selectedLocation = StorageLocation.pantry;
    DateTime purchaseDate = DateTime.now();

    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Add Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: detailsController,
                  decoration: const InputDecoration(
                    labelText: 'Details (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<FoodCategory>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: FoodCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category.display),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<StorageLocation>(
                  value: selectedLocation,
                  decoration: const InputDecoration(
                    labelText: 'Storage Location',
                    border: OutlineInputBorder(),
                  ),
                  items: StorageLocation.values.map((location) {
                    return DropdownMenuItem(
                      value: location,
                      child: Text(location.display),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedLocation = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  _addItem(
                    nameController.text.trim(),
                    detailsController.text.trim().isEmpty ? null : detailsController.text.trim(),
                    selectedCategory,
                    selectedLocation,
                    purchaseDate,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditItemDialog(PantryItem item) {
    final nameController = TextEditingController(text: item.name);
    final detailsController = TextEditingController(text: item.details ?? '');
    FoodCategory selectedCategory = item.category;
    StorageLocation selectedLocation = item.storageLocation;

    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Edit Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: detailsController,
                  decoration: const InputDecoration(
                    labelText: 'Details (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<FoodCategory>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: FoodCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category.display),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<StorageLocation>(
                  value: selectedLocation,
                  decoration: const InputDecoration(
                    labelText: 'Storage Location',
                    border: OutlineInputBorder(),
                  ),
                  items: StorageLocation.values.map((location) {
                    return DropdownMenuItem(
                      value: location,
                      child: Text(location.display),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedLocation = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  _updateItem(
                    item,
                    nameController.text.trim(),
                    detailsController.text.trim().isEmpty ? null : detailsController.text.trim(),
                    selectedCategory,
                    selectedLocation,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterDialog() {
    String? searchTerm = _filter.searchTerm;
    FoodCategory? selectedCategory = _filter.category;
    StorageLocation? selectedLocation = _filter.location;
    SortCriteria sortBy = _filter.sortBy;
    bool sortAscending = _filter.sortAscending;

    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Filter & Sort'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    searchTerm = value.isEmpty ? null : value;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<FoodCategory?>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<FoodCategory?>(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ...FoodCategory.values.map((category) {
                      return DropdownMenuItem<FoodCategory?>(
                        value: category,
                        child: Text(category.display),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<StorageLocation?>(
                  value: selectedLocation,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<StorageLocation?>(
                      value: null,
                      child: Text('All Locations'),
                    ),
                    ...StorageLocation.values.map((location) {
                      return DropdownMenuItem<StorageLocation?>(
                        value: location,
                        child: Text(location.display),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedLocation = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<SortCriteria>(
                  value: sortBy,
                  decoration: const InputDecoration(
                    labelText: 'Sort By',
                    border: OutlineInputBorder(),
                  ),
                  items: SortCriteria.values.map((criteria) {
                    return DropdownMenuItem(
                      value: criteria,
                      child: Text(criteria.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      sortBy = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Ascending Order'),
                  value: sortAscending,
                  onChanged: (value) {
                    setDialogState(() {
                      sortAscending = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _filter = const PantryFilter();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Clear'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _filter = PantryFilter(
                    searchTerm: searchTerm,
                    category: selectedCategory,
                    location: selectedLocation,
                    sortBy: sortBy,
                    sortAscending: sortAscending,
                  );
                });
                Navigator.of(context).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  void _addItem(String name, String? details, FoodCategory category, 
      StorageLocation location, DateTime purchaseDate) {
    final newItem = PantryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      details: details,
      purchaseDate: purchaseDate,
      category: category,
      storageLocation: location,
    );

    setState(() {
      _items.add(newItem);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added $name to pantry')),
    );
  }

  void _updateItem(PantryItem originalItem, String name, String? details, 
      FoodCategory category, StorageLocation location) {
    final index = _items.indexWhere((item) => item.id == originalItem.id);
    if (index != -1) {
      setState(() {
        _items[index] = originalItem.copyWith(
          name: name,
          details: details,
          category: category,
          storageLocation: location,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated $name')),
      );
    }
  }

  void _deleteItem(PantryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete ${item.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _items.removeWhere((i) => i.id == item.id);
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted ${item.name}')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
