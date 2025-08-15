import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/shopping_list_item.dart';
import '../services/shopping_list_service.dart';
import '../services/app_services.dart';
import 'dialogs/shopping_list_item_dialog.dart';
import '../widgets/nibble_app_bar.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  late ShoppingListService _service;
  final List<ShoppingListItem> _items = [];
  bool _showCompleted = false;
  bool _loading = true;
  bool _error = false;
  final Set<String?> _recentlyAddedIds = {}; // highlight set

  @override
  void initState() {
    super.initState();
    // Defer service lookup to after first frame to ensure InheritedWidget present
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _service = AppServicesScope.of(context)!.shoppingListService;
      _load();
    });
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = false; });
    try {
  final data = await _service.getShoppingList();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(data);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = true; });
    }
  }

  List<ShoppingListItem> get _filteredItems {
    if (_showCompleted) {
      return _items;
    }
    return _items.where((item) => !item.isChecked).toList();
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
      appBar: NibbleAppBar(
        title: 'Shopping List',
        actions: [
          IconButton(
            icon: Icon(
              _showCompleted ? Icons.check_box : Icons.check_box_outline_blank,
            ),
            onPressed: () {
              setState(() {
                _showCompleted = !_showCompleted;
              });
            },
            tooltip: 'Show/Hide Completed Items',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear_completed':
                  _clearCompleted();
                  break;
                case 'sort_category':
                  _sortByCategory();
                  break;
                case 'sort_name':
                  _sortByName();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_completed',
                child: Text('Clear Completed'),
              ),
              const PopupMenuItem(
                value: 'sort_category',
                child: Text('Sort by Category'),
              ),
              const PopupMenuItem(
                value: 'sort_name',
                child: Text('Sort by Name'),
              ),
            ],
          ),
        ],
      ),
    body: _loading
      ? _buildShimmer()
          : _error
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Failed to load list'),
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildStats(),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index.isEven) {
                  return _buildCategoryHeader(_filteredItems[index ~/ 2].category);
                }
                return _buildShoppingListItem(_filteredItems[index ~/ 2]);
              },
              childCount: _filteredItems.length * 2,
            ),
          ),
        ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        backgroundColor: AppColors.gardenHerb,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStats() {
    final totalItems = _items.length;
    final completedItems = _items.where((item) => item.isChecked).length;
    final remainingItems = totalItems - completedItems;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total', totalItems),
            _buildStatItem('Remaining', remainingItems),
            _buildStatItem('Completed', completedItems),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryHeader(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      color: Colors.grey[100],
      child: Text(
        category,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildShoppingListItem(ShoppingListItem item) {
    return Dismissible(
      key: Key(item.name),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) async {
        if (item.id == null) return; // can't delete without id
        try {
          await _service.removeItem(int.tryParse(item.id!) ?? -1); // assuming numeric id in backend
          _items.removeWhere((e) => e.id == item.id);
          if (mounted) setState(() {});
        } catch (_) {}
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        color: _recentlyAddedIds.contains(item.id)
            ? AppColors.gardenHerb.withAlpha((255 * 0.12).round())
            : null,
        child: ListTile(
        leading: Checkbox(
          value: item.isChecked,
          onChanged: (value) async {
            final updated = item.copyWith(isChecked: value ?? false);
            final idx = _items.indexOf(item);
            setState(() => _items[idx] = updated);
            try {
              await _service.updateItem(updated);
            } catch (_) {
              // revert on failure
              if (!mounted) return;
              setState(() => _items[idx] = item);
            }
          },
          activeColor: AppColors.gardenHerb,
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.isChecked ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text('${item.quantity} ${item.unit}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.source != 'manual')
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getSourceColor(item.source).withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.source,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getSourceColor(item.source),
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editItem(item),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Color _getSourceColor(String source) {
    switch (source) {
      case 'pantry':
        return AppColors.gardenHerb;
      case 'recipe':
        return AppColors.flameOrange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _addItem() async {
    final created = await showDialog<ShoppingListItem>(
      context: context,
      builder: (_) => const ShoppingListItemDialog(),
    );
    if (created != null) {
      try {
        final inserted = await _service.addItems([created]);
        _recentlyAddedIds.addAll(inserted.map((e) => e.id));
        await _load();
      } catch (_) {}
    }
  }

  Future<void> _editItem(ShoppingListItem item) async {
    final updated = await showDialog<ShoppingListItem>(
      context: context,
      builder: (_) => ShoppingListItemDialog(item: item),
    );
    if (updated != null) {
      final idx = _items.indexOf(item);
      setState(() => _items[idx] = updated);
      try {
        await _service.updateItem(updated);
      } catch (_) {
        if (!mounted) return;
        setState(() => _items[idx] = item); // revert
      }
    }
  }

  Widget _buildShimmer() {
    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.all(16),
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            _shimmerBox(width: 24, height: 24, radius: 4),
            const SizedBox(width: 12),
            Expanded(child: _shimmerBox(height: 16, radius: 4)),
            const SizedBox(width: 12),
            _shimmerBox(width: 60, height: 16, radius: 4),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox({double? width, double? height, double radius = 8}) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 800),
      opacity: _loading ? 0.5 : 0.0,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  void _clearCompleted() {
    setState(() {
      _items.removeWhere((item) => item.isChecked);
    });
  }

  void _sortByCategory() {
    setState(() {
      _items.sort((a, b) => a.category.compareTo(b.category));
    });
  }

  void _sortByName() {
    setState(() {
      _items.sort((a, b) => a.name.compareTo(b.name));
    });
  }
}
