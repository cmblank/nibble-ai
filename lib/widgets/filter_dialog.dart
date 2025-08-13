import 'package:flutter/material.dart';
import 'package:nibble_ai/models/pantry_enums.dart';
import 'package:nibble_ai/models/pantry_filter.dart';

class FilterDialog extends StatefulWidget {
  final PantryFilter currentFilter;

  const FilterDialog({super.key, required this.currentFilter});

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late TextEditingController _searchController;
  late FoodCategory? _selectedCategory;
  late StorageLocation? _selectedLocation;
  late SortCriteria _sortBy;
  late bool _sortAscending;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.currentFilter.searchTerm);
    _selectedCategory = widget.currentFilter.category;
    _selectedLocation = widget.currentFilter.location;
    _sortBy = widget.currentFilter.sortBy;
    _sortAscending = widget.currentFilter.sortAscending;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Items',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<FoodCategory?>(
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              value: _selectedCategory,
              items: [
                const DropdownMenuItem<FoodCategory?>(
                  value: null,
                  child: Text('All Categories'),
                ),
                ...FoodCategory.values.map(
                  (c) => DropdownMenuItem<FoodCategory?>(
                    value: c,
                    child: Text(c.display),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _selectedCategory = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<StorageLocation?>(
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
              value: _selectedLocation,
              items: [
                const DropdownMenuItem<StorageLocation?>(
                  value: null,
                  child: Text('All Locations'),
                ),
                ...StorageLocation.values.map(
                  (l) => DropdownMenuItem<StorageLocation?>(
                    value: l,
                    child: Text(l.display),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _selectedLocation = value),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<SortCriteria>(
                    decoration: const InputDecoration(
                      labelText: 'Sort By',
                      border: OutlineInputBorder(),
                    ),
                    value: _sortBy,
                    items: SortCriteria.values
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.displayName),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _sortBy = value);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(_sortAscending
                      ? Icons.arrow_upward
                      : Icons.arrow_downward),
                  onPressed: () =>
                      setState(() => _sortAscending = !_sortAscending),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    final filter = PantryFilter(
                      searchTerm: _searchController.text.trim(),
                      category: _selectedCategory,
                      location: _selectedLocation,
                      sortBy: _sortBy,
                      sortAscending: _sortAscending,
                    );
                    Navigator.of(context).pop(filter);
                  },
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
