import 'package:flutter/material.dart';
import 'dart:async';
import '../services/pantry_service.dart';
// import '../services/profile_prefs_service.dart';
import '../models/pantry_item.dart';
import '../models/pantry_filter.dart';
import '../models/pantry_enums.dart';
import '../design_tokens/color_tokens.dart';
// Bring back non-sticky app bar for Pantry
import '../utils/profile_storage.dart';
import '../widgets/pantry_item_tile.dart';
import '../widgets/category_chip.dart';
import '../widgets/pantry_search_header.dart';
import '../widgets/nibble_app_bar.dart';
import 'chatbot_screen.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  List<PantryItem> _items = [];
  bool _isLoading = false;
  PantryFilter _filter = const PantryFilter();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  
  
  @override
  void initState() {
    super.initState();
    _searchController.text = _filter.searchTerm ?? '';
    _searchController.addListener(_onSearchChanged);
    _loadItems();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      final term = _searchController.text.trim();
      if (term == (_filter.searchTerm ?? '')) return;
      setState(() {
        _filter = _filter.copyWith(searchTerm: term.isEmpty ? null : term);
      });
    });
  }

  void _loadItems() {
    setState(() => _isLoading = true);
    () async {
      try {
        if (PantryService.isAuthenticated) {
          final loaded = await PantryService.fetchItems();
          if (loaded.isEmpty) {
            // Try importing onboarding pantry snapshot if present
            final imported = await PantryService.importOnboardingPantryIfEmpty();
            if (imported > 0) {
              // Cloud import succeeded; refresh from DB
              final refreshed = await PantryService.fetchItems();
              setState(() {
                _items = refreshed;
                _filter = const PantryFilter();
                _searchController.clear();
              });
            } else {
              // Cloud import yielded nothing; try local onboarding fallback
              final localCount = await _tryLocalOnboardingImport(toDatabase: true);
              if (localCount > 0) {
                // DB write(s) succeeded; refresh from DB.
                final refreshed = await PantryService.fetchItems();
                setState(() {
                  _items = refreshed;
                  _filter = const PantryFilter();
                  _searchController.clear();
                });
              } else if (_items.isNotEmpty) {
                // DB write(s) failed; fallback items were set locally by _tryLocalOnboardingImport.
                setState(() {
                  _filter = const PantryFilter();
                  _searchController.clear();
                });
              } else {
                setState(() => _items = loaded);
              }
            }
          } else {
            setState(() => _items = loaded);
          }
        } else {
          // Not signed in: try local onboarding first, else show small sample
          final localProfile = await ProfileStorage.loadProfile();
          final generated = _generatePantryFromProfile(localProfile);
          if (generated.isNotEmpty) {
            setState(() => _items = generated);
          } else {
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
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }();
  }

  // Generate PantryItems from local onboarding profile_data
  List<PantryItem> _generatePantryFromProfile(Map<String, dynamic> profile) {
    final pantry = profile['pantry'];
    if (pantry is! Map<String, dynamic>) return [];
    List<String> list(dynamic v) => v is List ? List<String>.from(v) : <String>[];
    final names = <String>{
      ...list(pantry['pantryStaples']),
      ...list(pantry['grainsPasta']),
      ...list(pantry['condiments']),
      ...list(pantry['dairyAlternatives']),
      ...list(pantry['proteins']),
      ...list(pantry['veggies']),
      ...list(pantry['fruits']),
    }..removeWhere((e) => e.trim().isEmpty);
    if (names.isEmpty) return [];

    FoodCategory guessCategory(String n) {
      final s = n.toLowerCase();
      if (s.contains('flour') || s.contains('sugar') || s.contains('baking') || s.contains('yeast') || s.contains('bicarb')) {
        return FoodCategory.baking;
      }
      if (s.contains('cumin') || s.contains('pepper') || s.contains('chili') || s.contains('oregano') || s.contains('paprika') || s.contains('spice')) {
        return FoodCategory.herbsAndSpices;
      }
      if (s.contains('oil') || s.contains('vinegar') || s.contains('sauce') || s.contains('ketchup') || s.contains('mustard') || s.contains('mayo')) {
        return FoodCategory.condiments;
      }
      if (s.contains('milk') || s.contains('cheese') || s.contains('yogurt') || s.contains('butter')) {
        return FoodCategory.dairy;
      }
      if (s.contains('rice') || s.contains('pasta') || s.contains('noodle') || s.contains('grain') || s.contains('oats')) {
        return FoodCategory.grains;
      }
      if (s.contains('chicken') || s.contains('beef') || s.contains('pork') || s.contains('tofu') || s.contains('egg')) {
        return FoodCategory.protein;
      }
      if (s.contains('apple') || s.contains('banana') || s.contains('berry') || s.contains('lettuce') || s.contains('spinach') || s.contains('carrot') || s.contains('tomato')) {
        return FoodCategory.produce;
      }
      return FoodCategory.other;
    }
    StorageLocation defaultStorage(FoodCategory c) {
      switch (c) {
        case FoodCategory.produce:
        case FoodCategory.dairy:
        case FoodCategory.protein:
          return StorageLocation.fridge;
        case FoodCategory.frozenFoods:
          return StorageLocation.freezer;
        default:
          return StorageLocation.pantry;
      }
    }
    DateTime computeExpiry(FoodCategory c, StorageLocation s, DateTime purchase) {
      return purchase.add(c.getShelfLife(s));
    }
    final now = DateTime.now();
    return names.map((n) {
      final cat = guessCategory(n);
      final loc = defaultStorage(cat);
      return PantryItem(
        name: n,
        purchaseDate: now,
        expirationDate: computeExpiry(cat, loc, now),
        category: cat,
        storageLocation: loc,
      );
    }).toList();
  }

  // Try importing from local onboarding; optionally push to DB if signed in.
  Future<int> _tryLocalOnboardingImport({required bool toDatabase}) async {
    final localProfile = await ProfileStorage.loadProfile();
    final items = _generatePantryFromProfile(localProfile);
    if (items.isEmpty) return 0;
    if (toDatabase && PantryService.isAuthenticated) {
      // dedupe by name against current DB items
      final existing = await PantryService.fetchItems();
      final existingNames = existing.map((e) => e.name.trim().toLowerCase()).toSet();
      final toAdd = items.where((i) => !existingNames.contains(i.name.trim().toLowerCase())).toList();
      int success = 0;
      for (final it in toAdd) {
        final inserted = await PantryService.addItem(it);
        if (inserted != null) success++;
      }
      // If no inserts succeeded (e.g., due to RLS), show local items as a fallback.
      if (success == 0) {
        setState(() => _items = items);
      }
      return success;
    }
    // Not pushing to DB; just surface locally
    setState(() => _items = items);
    return items.length;
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
        case SortCriteria.useFirst:
          int dupScore(PantryItem i) {
            final name = i.name.trim().toLowerCase();
            final count = _items.where((x) => x.name.trim().toLowerCase() == name).length;
            return count > 1 ? 0 : 1;
          }
          final result = dupScore(a).compareTo(dupScore(b));
          final stable = a.expirationDate.compareTo(b.expirationDate);
          final combined = result != 0 ? result : stable;
          return _filter.sortAscending ? combined : -combined;
      }
    });
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.gray300,
      floatingActionButton: FloatingActionButton(
        heroTag: 'pantry-fab',
        onPressed: _showAddItemDialog,
        tooltip: 'Add pantry item',
  backgroundColor: DesignTokens.brick900,
  child: const Icon(Icons.add, color: Colors.white),
      ),
  body: _isLoading
      ? const Center(child: CircularProgressIndicator())
      : _buildPantryContent(),
    );
  }

  Widget _buildPantryContent() {
    final items = _filteredItems;
    return CustomScrollView(
      slivers: [
        NibbleSliverAppBar(
          currentTab: NibbleTab.pantry,
          onChatTap: (ctx) => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatbotScreen()),
          ),
        ),
        SliverToBoxAdapter(
          child: PantrySearchHeader(
            searchController: _searchController,
            onFilterTap: _showFilterDialog,
            selectedCategories: _filter.categories ?? <FoodCategory>{},
            onCategoriesChanged: (next) => setState(() {
              _filter = _filter.copyWith(categories: next);
            }),
          ),
        ),
        SliverToBoxAdapter(child: _buildStatsRow(items)),
        if (items.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 80),
              child: Column(
                children: const [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No items match your filters',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  SizedBox(height: 8),
                  Text('Try clearing filters or add new items.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          )
        else
          SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, index) => _buildPantryItemTile(items[index]),
          ),
      ],
    );
  }

  Widget _buildStatsRow(List<PantryItem> items) {
    final total = items.length;
    final lowStock = items.where((i) => i.isLowStock == true).length;
    final now = DateTime.now();
  final expiringSoon = items
    .where((i) => i.expirationDate.isBefore(now.add(const Duration(days: 7))))
    .length;

    Widget statCard(String value, String label, Color valueColor, {VoidCallback? onTap}) {
      final card = Container(
        height: 64,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: BackgroundColors.primary,
          border: Border.all(color: BorderColors.primary),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: TextColors.secondary,
              ),
            ),
          ],
        ),
      );
      if (onTap == null) return card;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: card,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: statCard(
              '$total',
              'Total Items',
              TextColors.success,
              onTap: () {
                // Clear quick filters but keep other selections/search
                setState(() => _filter = _filter.copyWith(
                  onlyLowStock: false,
                  expiringWithinDays: null,
                ));
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: statCard(
              '$lowStock',
              'Low Stock',
              TextColors.warning,
              onTap: () {
                setState(() => _filter = _filter.copyWith(
                  onlyLowStock: true,
                  expiringWithinDays: null,
                  sortBy: SortCriteria.useFirst,
                  sortAscending: true,
                ));
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: statCard(
              '$expiringSoon',
              'Expiring < 7d',
              TextColors.danger,
              onTap: () {
                setState(() => _filter = _filter.copyWith(
                  onlyLowStock: false,
                  expiringWithinDays: 7,
                  sortBy: SortCriteria.expiryDate,
                  sortAscending: true,
                ));
              },
            ),
          ),
        ],
      ),
    );
  }

  // _buildSearchAndFilters removed: replaced by PantrySearchHeader

  // _buildCategoryChips removed: handled by PantrySearchHeader

  Widget _buildPantryItemTile(PantryItem item) {
    // Determine tags:
    // - Use First: there are duplicates (case-insensitive) of this name in the full items list
    // - Expiring Soon: within 7 days from today
    final lowerName = item.name.trim().toLowerCase();
    final totalWithName = _items.where((i) => i.name.trim().toLowerCase() == lowerName).length;
    final showUseFirst = totalWithName > 1;
  final daysUntil = item.expirationDate.difference(DateTime.now()).inDays;
  final showExpiringSoon = daysUntil >= 0 && daysUntil <= 3 && !showUseFirst; // 3-day window; use-first takes precedence

    return PantryCard(
      item: item,
      showUseFirst: showUseFirst,
      showExpiringSoon: showExpiringSoon,
      onTap: () => _showEditItemDialog(item),
      onEdit: () => _showEditItemDialog(item),
      onDelete: () => _deleteItem(item),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Convert "today"/"yesterday" using the spec's anchor date (July 7, 2025).
  DateTime? _parseUserDate(String? input) {
    if (input == null) return null;
    final txt = input.trim();
    if (txt.isEmpty) return null;
    final lower = txt.toLowerCase();
    // Use fixed anchor for deterministic conversions per requirement
  final anchor = DateTime(2025, 7, 7);
    if (lower == 'today') return DateTime(anchor.year, anchor.month, anchor.day);
    if (lower == 'yesterday') {
      final y = anchor.subtract(const Duration(days: 1));
      return DateTime(y.year, y.month, y.day);
    }
    return DateTime.tryParse(txt);
  }

  // Estimate expiry using category/location rules in PantryItem
  DateTime _estimateExpiry({
    required FoodCategory category,
    required StorageLocation storage,
    required DateTime purchaseDate,
  }) {
    final tmp = PantryItem(
      name: 'tmp',
      purchaseDate: purchaseDate,
      category: category,
      storageLocation: storage,
    );
    return tmp.expirationDate;
  }

  void _showAddItemDialog() {
    // Present Add Item as a bottom sheet, matching the filter pattern
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddItemSheet(),
    );
  }

  void _showEditItemDialog(PantryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildEditItemSheet(item),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterDialog(),
    );
  }

  Widget _buildAddItemSheet() {
  final nameController = TextEditingController();
  final detailsController = TextEditingController();
  final sizeController = TextEditingController();
  final purchaseController = TextEditingController();
  final expiryController = TextEditingController();
  final urlController = TextEditingController();

  FoodCategory selectedCategory = FoodCategory.other;
  StorageLocation selectedLocation = StorageLocation.pantry;

  DateTime purchaseDate = DateTime.now();
  DateTime estimatedExpiry = _estimateExpiry(
    category: selectedCategory,
    storage: selectedLocation,
    purchaseDate: purchaseDate,
  );
  purchaseController.text = _formatDate(purchaseDate);
  expiryController.text = _formatDate(estimatedExpiry);

  bool includeExpiry = false; // default OFF; user can opt-in to edit expiry

  return StatefulBuilder(
    builder: (context, setSheetState) {
      return DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.5,
        maxChildSize: 0.98,
        expand: false,
        builder: (ctx, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DesignTokens.gray400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Add Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Item name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                              borderSide: BorderSide(color: InputColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                              borderSide: BorderSide(color: InputColors.borderFocus, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Categories', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...FoodCategory.values.map((c) => CategoryChip(
                                  label: c.display,
                                  selected: selectedCategory == c,
                                  onTap: () => setSheetState(() {
                                    selectedCategory = c;
                                    estimatedExpiry = _estimateExpiry(
                                      category: selectedCategory,
                                      storage: selectedLocation,
                                      purchaseDate: purchaseDate,
                                    );
                                    expiryController.text = _formatDate(estimatedExpiry);
                                  }),
                                )),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: BorderColors.secondary, thickness: 1, height: 1),
                        ),
                        const Text('Locations', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...StorageLocation.values.map((loc) => CategoryChip(
                                  label: loc.display,
                                  selected: selectedLocation == loc,
                                  onTap: () => setSheetState(() {
                                    selectedLocation = loc;
                                    estimatedExpiry = _estimateExpiry(
                                      category: selectedCategory,
                                      storage: selectedLocation,
                                      purchaseDate: purchaseDate,
                                    );
                                    expiryController.text = _formatDate(estimatedExpiry);
                                  }),
                                )),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: BorderColors.secondary, thickness: 1, height: 1),
                        ),
                        const Text('Details', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: detailsController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                              borderSide: BorderSide(color: InputColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                              borderSide: BorderSide(color: InputColors.borderFocus, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: sizeController,
                          decoration: const InputDecoration(
                            labelText: 'Size / Quantity',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                              borderSide: BorderSide(color: InputColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                              borderSide: BorderSide(color: InputColors.borderFocus, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              initialDate: purchaseDate,
                              builder: (ctx, child) {
                                final theme = Theme.of(ctx);
                                return Theme(
                                  data: theme.copyWith(
                                    datePickerTheme: const DatePickerThemeData(
                                      backgroundColor: Colors.white,
                                      surfaceTintColor: Colors.transparent,
                                    ),
                                    colorScheme: theme.colorScheme.copyWith(
                                      surface: Colors.white,
                                      onSurface: Colors.black,
                                      surfaceTint: Colors.transparent,
                                    ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setSheetState(() {
                                purchaseDate = picked;
                                purchaseController.text = _formatDate(purchaseDate);
                                estimatedExpiry = _estimateExpiry(
                                  category: selectedCategory,
                                  storage: selectedLocation,
                                  purchaseDate: purchaseDate,
                                );
                                expiryController.text = _formatDate(estimatedExpiry);
                              });
                            }
                          },
                          child: AbsorbPointer(
                            child: TextField(
                              controller: purchaseController,
                              decoration: const InputDecoration(
                                labelText: 'Purchase Date',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                  borderSide: BorderSide(color: InputColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                  borderSide: BorderSide(color: InputColors.borderFocus, width: 2),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Include Expiration Date toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Include Expiration Date', style: TextStyle(fontWeight: FontWeight.w600)),
                            Switch(
                              value: includeExpiry,
                              onChanged: (v) => setSheetState(() => includeExpiry = v),
                            ),
                          ],
                        ),
                        if (includeExpiry) ...[
                          const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              initialDate: estimatedExpiry,
                              builder: (ctx, child) {
                                final theme = Theme.of(ctx);
                                return Theme(
                                  data: theme.copyWith(
                                    datePickerTheme: const DatePickerThemeData(
                                      backgroundColor: Colors.white,
                                      surfaceTintColor: Colors.transparent,
                                    ),
                                    colorScheme: theme.colorScheme.copyWith(
                                      surface: Colors.white,
                                      onSurface: Colors.black,
                                      surfaceTint: Colors.transparent,
                                    ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setSheetState(() {
                                estimatedExpiry = picked;
                                expiryController.text = _formatDate(estimatedExpiry);
                              });
                            }
                          },
                          child: AbsorbPointer(
                            child: TextField(
                              controller: expiryController,
                              decoration: const InputDecoration(
                                labelText: 'Projected Expiration Date',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                  borderSide: BorderSide(color: InputColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                  borderSide: BorderSide(color: InputColors.borderFocus, width: 2),
                                ),
                              ),
                            ),
                          ),
                          ),
                        ],
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: BorderColors.secondary, thickness: 1, height: 1),
                        ),
                        const Text('URL', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: urlController,
                          decoration: const InputDecoration(
                            labelText: 'Product URL',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                              borderSide: BorderSide(color: InputColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                              borderSide: BorderSide(color: InputColors.borderFocus, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: DesignTokens.gray600,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          if (nameController.text.trim().isNotEmpty) {
                            final parsedPurchase = _parseUserDate(purchaseController.text) ?? purchaseDate;
                            _addItemFull(
                              name: nameController.text.trim(),
                              details: detailsController.text.trim().isNotEmpty ? detailsController.text.trim() : null,
                              size: sizeController.text.trim().isNotEmpty ? sizeController.text.trim() : null,
                              category: selectedCategory,
                              location: selectedLocation,
                              purchaseDate: parsedPurchase,
                              expiryDate: estimatedExpiry,
                            );
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignTokens.brick900,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

  Widget _buildFilterDialog() {
    Set<FoodCategory> selectedCategories = _filter.categories != null
        ? Set<FoodCategory>.from(_filter.categories!)
        : <FoodCategory>{};
    StorageLocation? selectedLocation = _filter.location;
    SortCriteria sortBy = _filter.sortBy;
    bool sortAscending = _filter.sortAscending;
  // Search is handled in the header; omit in-sheet search controls.

    return StatefulBuilder(
      builder: (context, setSheetState) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: DesignTokens.gray400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Filter & Sort', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Removed in-sheet search; search stays in the header.
                          const Text('Categories', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              CategoryChip(
                                label: 'All',
                                selected: selectedCategories.isEmpty,
                                onTap: () => setSheetState(() => selectedCategories.clear()),
                              ),
                              ...FoodCategory.values.map((c) => CategoryChip(
                                    label: c.display,
                                    selected: selectedCategories.contains(c),
                                    onTap: () => setSheetState(() {
                                      if (selectedCategories.contains(c)) {
                                        selectedCategories.remove(c);
                                      } else {
                                        selectedCategories.add(c);
                                      }
                                    }),
                                  )),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(color: BorderColors.secondary, thickness: 1, height: 1),
                          ),
                          const Text('Locations', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              CategoryChip(
                                label: 'All',
                                selected: selectedLocation == null,
                                onTap: () => setSheetState(() => selectedLocation = null),
                              ),
                              ...StorageLocation.values.map((loc) => CategoryChip(
                                    label: loc.display,
                                    selected: selectedLocation == loc,
                                    onTap: () => setSheetState(() => selectedLocation = loc),
                                  )),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(color: BorderColors.secondary, thickness: 1, height: 1),
                          ),
                          const Text('Sort by', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...[SortCriteria.name, SortCriteria.purchaseDate, SortCriteria.expiryDate, SortCriteria.useFirst].map(
                                (criteria) => CategoryChip(
                                  label: criteria.displayName,
                                  selected: sortBy == criteria,
                                  onTap: () => setSheetState(() => sortBy = criteria),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: DesignTokens.gray600,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Cancel'),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _filter = const PantryFilter();
                            });
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: DesignTokens.brick900,
                            backgroundColor: Color(0xFFFFE7E4),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Clear'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _filter = PantryFilter(
                                // Preserve current search and quick filters; only change fields configured here
                                searchTerm: _filter.searchTerm,
                                categories: selectedCategories,
                                location: selectedLocation,
                                sortBy: sortBy,
                                sortAscending: sortAscending,
                                onlyLowStock: _filter.onlyLowStock,
                                expiringWithinDays: _filter.expiringWithinDays,
                              );
                            });
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignTokens.brick900,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _addItemFull({
    required String name,
    String? details,
    String? size,
    required FoodCategory category,
    required StorageLocation location,
    required DateTime purchaseDate,
    required DateTime expiryDate,
  }) {
    final localItem = PantryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      details: details,
      size: size,
      purchaseDate: purchaseDate,
      expirationDate: expiryDate,
      category: category,
      storageLocation: location,
    );

    () async {
      PantryItem? added;
      if (PantryService.isAuthenticated) {
        added = await PantryService.addItem(localItem);
      }
      setState(() {
        _items.add(added ?? localItem);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added $name to pantry')),
        );
      }
    }();
  }

  void _updateItemFull({
    required PantryItem originalItem,
    required String name,
    String? details,
    String? size,
    required FoodCategory category,
    required StorageLocation location,
    required DateTime purchaseDate,
    required DateTime expiryDate,
  }) {
    final index = _items.indexWhere((i) => i.id == originalItem.id);
    if (index == -1) return;
    final updated = originalItem.copyWith(
      name: name,
      details: details,
      size: size,
      category: category,
      storageLocation: location,
      purchaseDate: purchaseDate,
      expirationDate: expiryDate,
    );

    () async {
      var ok = true;
      if (PantryService.isAuthenticated) {
        ok = await PantryService.updateItem(updated);
      }
      if (ok) {
        setState(() => _items[index] = updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Updated $name')),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update item')),
        );
      }
    }();
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
              () async {
                var ok = true;
                if (PantryService.isAuthenticated && item.id != null) {
                  ok = await PantryService.deleteItem(item.id!);
                }
                if (ok) {
                  setState(() {
                    _items.removeWhere((i) => i.id == item.id);
                  });
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Deleted ${item.name}')),
                    );
                  }
                } else if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete item')),
                  );
                }
              }();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEditItemDialog(PantryItem item) {
    final nameController = TextEditingController(text: item.name);
    final detailsController = TextEditingController(text: item.details ?? '');
    final sizeController = TextEditingController(text: item.size ?? '');
    final purchaseController = TextEditingController(text: _formatDate(item.purchaseDate));
    final expiryController = TextEditingController(text: _formatDate(item.expirationDate));
    final urlController = TextEditingController();

    DateTime purchaseDate = item.purchaseDate;
    DateTime localExpiry = item.expirationDate;
    FoodCategory selectedCategory = item.category;
    StorageLocation selectedLocation = item.storageLocation;
    bool includeExpiry = false; // default OFF for edit as requested

    return StatefulBuilder(
      builder: (context, setSheetState) {
        return DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.5,
          maxChildSize: 0.98,
          expand: false,
          builder: (ctx, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: DesignTokens.gray400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Edit Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Item name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                                borderSide: BorderSide(color: InputColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                                borderSide: BorderSide(color: InputColors.borderFocus, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Categories', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...FoodCategory.values.map((c) => CategoryChip(
                                    label: c.display,
                                    selected: selectedCategory == c,
                                    onTap: () => setSheetState(() {
                                      selectedCategory = c;
                                      // Update projected expiry when category/location changes
                                      localExpiry = _estimateExpiry(
                                        category: selectedCategory,
                                        storage: selectedLocation,
                                        purchaseDate: purchaseDate,
                                      );
                                      expiryController.text = _formatDate(localExpiry);
                                    }),
                                  )),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(color: BorderColors.secondary, thickness: 1, height: 1),
                          ),
                          const Text('Locations', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...StorageLocation.values.map((loc) => CategoryChip(
                                    label: loc.display,
                                    selected: selectedLocation == loc,
                                    onTap: () => setSheetState(() {
                                      selectedLocation = loc;
                                      localExpiry = _estimateExpiry(
                                        category: selectedCategory,
                                        storage: selectedLocation,
                                        purchaseDate: purchaseDate,
                                      );
                                      expiryController.text = _formatDate(localExpiry);
                                    }),
                                  )),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(color: BorderColors.secondary, thickness: 1, height: 1),
                          ),
                          const Text('Details', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: detailsController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                                borderSide: BorderSide(color: InputColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                                borderSide: BorderSide(color: InputColors.borderFocus, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: sizeController,
                            decoration: const InputDecoration(
                              labelText: 'Size / Quantity',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                                borderSide: BorderSide(color: InputColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                                borderSide: BorderSide(color: InputColors.borderFocus, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                                initialDate: purchaseDate,
                                builder: (ctx, child) {
                                  final theme = Theme.of(ctx);
                                  return Theme(
                                    data: theme.copyWith(
                                      datePickerTheme: const DatePickerThemeData(
                                        backgroundColor: Colors.white,
                                        surfaceTintColor: Colors.transparent,
                                      ),
                                      colorScheme: theme.colorScheme.copyWith(
                                        surface: Colors.white,
                                        onSurface: Colors.black,
                                        surfaceTint: Colors.transparent,
                                      ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setSheetState(() {
                                  purchaseDate = picked;
                                  purchaseController.text = _formatDate(purchaseDate);
                                  localExpiry = _estimateExpiry(
                                    category: selectedCategory,
                                    storage: selectedLocation,
                                    purchaseDate: purchaseDate,
                                  );
                                  expiryController.text = _formatDate(localExpiry);
                                });
                              }
                            },
                            child: AbsorbPointer(
                              child: TextField(
                                controller: purchaseController,
                                decoration: const InputDecoration(
                                  labelText: 'Purchase Date',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(8)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(8)),
                                    borderSide: BorderSide(color: InputColors.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(8)),
                                    borderSide: BorderSide(color: InputColors.borderFocus, width: 2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Include Expiration Date toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Include Expiration Date', style: TextStyle(fontWeight: FontWeight.w600)),
                              Switch(
                                value: includeExpiry,
                                onChanged: (v) => setSheetState(() => includeExpiry = v),
                              ),
                            ],
                          ),
                          if (includeExpiry) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                  initialDate: localExpiry,
                                  builder: (ctx, child) {
                                    final theme = Theme.of(ctx);
                                    return Theme(
                                      data: theme.copyWith(
                                        datePickerTheme: const DatePickerThemeData(
                                          backgroundColor: Colors.white,
                                          surfaceTintColor: Colors.transparent,
                                        ),
                                        colorScheme: theme.colorScheme.copyWith(
                                          surface: Colors.white,
                                          onSurface: Colors.black,
                                          surfaceTint: Colors.transparent,
                                        ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setSheetState(() {
                                    localExpiry = picked;
                                    expiryController.text = _formatDate(localExpiry);
                                  });
                                }
                              },
                              child: AbsorbPointer(
                                child: TextField(
                                  controller: expiryController,
                                  decoration: const InputDecoration(
                                    labelText: 'Projected Expiration Date',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(8)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(8)),
                                      borderSide: BorderSide(color: InputColors.border),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(8)),
                                      borderSide: BorderSide(color: InputColors.borderFocus, width: 2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(color: BorderColors.secondary, thickness: 1, height: 1),
                          ),
                          const Text('URL', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: urlController,
                            decoration: const InputDecoration(
                              labelText: 'Product URL',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                                borderSide: BorderSide(color: InputColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                                borderSide: BorderSide(color: InputColors.borderFocus, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: DesignTokens.gray600,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Cancel'),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            if (nameController.text.trim().isNotEmpty) {
                              final parsedPurchase = _parseUserDate(purchaseController.text) ?? purchaseDate;
                              _updateItemFull(
                                originalItem: item,
                                name: nameController.text.trim(),
                                details: detailsController.text.trim().isEmpty ? null : detailsController.text.trim(),
                                size: sizeController.text.trim().isEmpty ? null : sizeController.text.trim(),
                                category: selectedCategory,
                                location: selectedLocation,
                                purchaseDate: parsedPurchase,
                                expiryDate: localExpiry,
                              );
                              Navigator.of(context).pop();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignTokens.brick900,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Update'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Bottom sheet variant used by _showEditItemDialog to match Add Item styling
  Widget _buildEditItemSheet(PantryItem item) => _buildEditItemDialog(item);
}

/// Spec-styled search field matching token colors and measurements
// Local SpecSearchField removed in favor of widgets/pantry_search_header.dart
