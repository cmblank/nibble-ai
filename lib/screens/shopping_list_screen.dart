import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';
import '../models/shopping_list_item.dart';
import '../services/shopping_list_service.dart';
import '../services/app_services.dart';
import 'dialogs/shopping_list_item_dialog.dart';
import '../widgets/nibble_app_bar.dart';
import '../widgets/profile_sheet.dart';
import 'achievements_screen.dart';
import 'chatbot_screen.dart';
import '../design_tokens/color_tokens.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:developer' as developer;

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
  RealtimeChannel? _channel; // realtime subscription

  @override
  void initState() {
    super.initState();
    // Defer service lookup to after first frame to ensure InheritedWidget present
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scope = AppServicesScope.of(context);
      if (scope == null) {
        developer.log('AppServicesScope not found in context; falling back to new ShoppingListService()', name: 'ShoppingList');
        _service = ShoppingListService();
      } else {
        _service = scope.shoppingListService;
      }
      _load();
  _subscribe();
    });
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = false; });
    try {
      developer.log('Loading shopping list', name: 'ShoppingList');
    developer.log('Current user: ' + (Supabase.instance.client.auth.currentUser?.id ?? 'NULL'), name: 'ShoppingList');
	  final data = await _service.getShoppingList(mergeDuplicates: true);
      developer.log('Loaded ${data.length} items (merged)', name: 'ShoppingList');
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(data);
        _loading = false;
      });
    } catch (e, st) {
      developer.log('Error loading shopping list', name: 'ShoppingList', error: e, stackTrace: st);
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
      backgroundColor: DesignTokens.gray300,
      appBar: NibbleAppBar(
        currentTab: NibbleTab.more,
        showAchievements: true,
        onWordmarkTap: () {
          final controller = PrimaryScrollController.of(context);
          if (controller.hasClients) {
            controller.animateTo(
              0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }
        },
        onChatTap: (ctx) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatbotScreen()),
          );
        },
        onAchievementsTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AchievementsScreen()),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share List',
            onPressed: _shareList,
          ),
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
        onProfileTap: () => showProfileSheet(context),
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
        heroTag: 'shopping-fab',
        onPressed: _addItem,
  tooltip: 'Add list item',
  child: const Icon(Icons.add, color: Colors.white),
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

  void _subscribe() {
    if (_channel != null) return;
    _channel = Supabase.instance.client.channel('public:shopping_list');
    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'shopping_list',
          callback: (payload) {
            _load(); // simple full refresh; could optimize by diff
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _shareList() async {
    // Use current filtered (respect show completed flag), but group by category for readability
    final buffer = StringBuffer();
    final itemsToShare = _filteredItems.where((i) => !i.isChecked).toList();
    if (itemsToShare.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nothing to share')));
      return;
    }
    // Group by category
    final Map<String, List<ShoppingListItem>> byCat = {};
    for (final it in itemsToShare) {
      byCat.putIfAbsent(it.category, () => []).add(it);
    }
    final cats = byCat.keys.toList()..sort();
    buffer.writeln('Grocery List');
    buffer.writeln('');
    for (final cat in cats) {
      buffer.writeln('=== $cat ===');
      final catItems = byCat[cat]!;
      catItems.sort((a,b)=>a.name.compareTo(b.name));
        for (final it in catItems) {
          String qty;
          if (it.quantity == it.quantity.roundToDouble()) {
            qty = it.quantity.round().toString();
          } else {
            // Trim trailing zeros safely
            qty = it.quantity.toStringAsFixed(2);
            if (qty.contains('.')) {
              qty = qty.replaceFirst(RegExp(r'0+ ?$', multiLine: false), '');
              qty = qty.replaceFirst(RegExp(r'\.$'), '');
            }
          }
          final qtyStr = it.unit.isNotEmpty ? '$qty ${it.unit}' : qty;
          final showQty = it.quantity != 1 || it.unit.isNotEmpty;
            buffer.writeln('- ${it.name}${showQty ? ' ($qtyStr)' : ''}${it.source != 'manual' ? ' [${it.source}]' : ''}');
      }
      buffer.writeln('');
    }
    final text = buffer.toString().trim();
    try {
      await Share.share(text, subject: 'Grocery List');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share failed')));
    }
  }
}
