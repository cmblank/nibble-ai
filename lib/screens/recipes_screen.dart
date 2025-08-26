import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // for kDebugMode
import 'package:nibble_ai/models/models.dart';
import 'package:nibble_ai/services/recipe_service.dart';
import '../design_tokens/color_tokens.dart';
import '../widgets/nibble_app_bar.dart';
import 'chatbot_screen.dart';
import 'achievements_screen.dart';
import '../widgets/profile_sheet.dart';
import '../widgets/pantry_search_header.dart';
import '../widgets/category_chip.dart';
import '../utils/profile_storage.dart';
import '../utils/favorites_storage.dart';
import '../utils/recipe_filtering.dart';
import 'recipe_detail_screen.dart';
import 'add_edit_recipe_screen.dart';
import 'import_recipe_link_screen.dart';
import 'ocr_import_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  // Mutable list; avoid const so we can expand safely after profile load.
  List<String> _categories = ['All', 'Recent', 'Favorites'];
  bool _loading = true;
  bool _initial = true;
  List<Recipe> _recipes = [];
  String? _error;
  Set<String> _favorites = {};
  // Advanced filter controllers/state
  final TextEditingController _includeCtrl = TextEditingController();
  final TextEditingController _excludeCtrl = TextEditingController();
  RangeValues _timeRange = const RangeValues(0, 180);
  bool _filterApplied = false;
  final Set<String> _selectedDifficulties = {};
  final Set<String> _selectedMealTypes = {};

  @override
  void initState() {
    super.initState();
  _loadRecipeCategories();
  _loadFavorites();
  _loadRecipes();
  _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
  _includeCtrl.dispose();
  _excludeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final favs = await FavoritesStorage.load();
    if (!mounted) return;
    setState(() => _favorites = favs);
  }

  void _onSearchChanged() {
    // Simple debounce: reload after short delay if user pauses typing
    final current = _searchController.text;
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      if (current == _searchController.text) {
        _loadRecipes();
      }
    });
  }

  Future<void> _loadRecipeCategories() async {
    final profile = await ProfileStorage.loadProfile();
    final cats = _buildCategoriesFromProfile(profile);
    if (!mounted) return;
    setState(() {
      _categories = cats;
      if (!_categories.contains(_selectedCategory)) {
        _selectedCategory = 'All';
      }
    });
  }

  Future<void> _loadRecipes() async {
    debugPrint('[RecipesScreen._loadRecipes] start search="${_searchController.text.trim()}"');
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await RecipeService.fetchAll(
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      );
      debugPrint('[RecipesScreen._loadRecipes] fetched count=${list.length}');
      if (!mounted) return;
      setState(() {
        _recipes = list;
        _loading = false;
        _initial = false;
      });
    } catch (e) {
      debugPrint('[RecipesScreen._loadRecipes] error=$e');
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load recipes';
        _loading = false;
        _initial = false;
      });
    }
  }

  List<String> _buildCategoriesFromProfile(Map<String, dynamic> profile) {
    final List<String> base = ['All', 'Recent', 'Favorites'];

    List<String> list(dynamic v) => v is List ? List<String>.from(v) : <String>[];
    // Pull user selections from onboarding
    final mealFocus = list(profile['mealFocus']);
    final tools = list(profile['tools']);
    final diets = list(profile['diets']);
    final cuisinesRaw = list(profile['cuisines']);
    final cuisines = cuisinesRaw.where((c) {
      final lc = c.trim().toLowerCase();
      return lc.isNotEmpty && lc != 'any' && lc != 'none';
    }).toList();

    // Curate tool labels to concise forms for chips
    String conciseTool(String t) {
      final lc = t.toLowerCase();
      if (lc.contains('pressure')) return 'Pressure cooker';
      if (lc.contains('slow')) return 'Slow cooker';
      if (lc.contains('air fryer')) return 'Air fryer';
      if (lc.contains('hand')) return 'Hand mixer';
      if (lc.contains('microwave')) return 'Microwave';
      if (lc.contains('blender')) return 'Blender';
      if (lc.contains('grill')) return 'Grill';
      return t;
    }

    final toolCats = tools
        .where((t) => t.toLowerCase() != 'none')
        .map(conciseTool)
        .toList();

    // Merge in a friendly order: meal focus → tools → diets → cuisines
    final merged = <String>{
      ...base,
      ...mealFocus,
      ...toolCats,
      ...diets,
      ...cuisines,
    }.toList();

    // Ensure base appear first and preserve intuitive ordering
    merged.removeWhere((e) => base.contains(e));
    final result = [...base, ...merged];
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.gray300,
      body: NestedScrollView(
        headerSliverBuilder: (context, inner) => [
          NibbleSliverAppBar(
            currentTab: NibbleTab.recipes,
            showAchievements: true,
            onChatTap: (ctx) => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatbotScreen()),
            ),
            onAchievementsTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AchievementsScreen()),
            ),
            onProfileTap: () => showProfileSheet(context),
          ),
        ],
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: BackgroundColors.secondary,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SpecSearchField(
                          controller: _searchController,
                          hintText: 'Search recipes',
                          onClear: () => _searchController.clear(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Tooltip(
                        message: 'Filter & sort',
                        child: IconButton(
                          icon: Icon(Icons.tune, color: _filterApplied ? Colors.deepPurple : null),
                          onPressed: _showAdvancedFilters,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                      children: [
                        ..._categories.map((category) {
                          final isSelected = category == _selectedCategory;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: CategoryChip(
                              label: category,
                              selected: isSelected,
                              onTap: () => setState(() => _selectedCategory = category),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async { await _loadRecipes(); await _loadFavorites(); },
                child: Builder(builder: (_) {
                  final list = _applyAdvanced(_filteredRecipes());
                  if (_loading && _initial) {
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: List.generate(6, (i) => const _LoadingCard()),
                    );
                  }
                  if (_error != null) {
                    return ListView(
                      padding: const EdgeInsets.all(32),
                      children: [
                        Center(child: Text(_error!)),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _loadRecipes, child: const Text('Retry')),
                      ],
                    );
                  }
                  if (list.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.all(48),
                      children: [
                        const Icon(Icons.receipt_long, size: 48, color: Colors.black38),
                        const SizedBox(height: 12),
                        const Center(child: Text('No recipes match. Tap + to add one.')),
                        if (_selectedCategory != 'All') ...[
                          const SizedBox(height: 8),
                          TextButton(onPressed: () => setState(() => _selectedCategory = 'All'), child: const Text('Clear category filter')),
                        ]
                      ],
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final r = list[index];
                      return GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipeId: r.id, initial: r)),
                          );
                          _loadRecipes();
                        },
                        child: _buildRecipeCard(r),
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'recipes-fab',
        onPressed: _showAddMenu,
        tooltip: 'Add recipe',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  List<Recipe> _filteredRecipes() => filterRecipes(recipes: _recipes, category: _selectedCategory, favorites: _favorites);
  List<Recipe> _applyAdvanced(List<Recipe> list) {
    if (!_filterApplied) return list;
    final include = _includeCtrl.text.toLowerCase().split(',').map((e)=> e.trim()).where((e)=> e.isNotEmpty).toList();
    final exclude = _excludeCtrl.text.toLowerCase().split(',').map((e)=> e.trim()).where((e)=> e.isNotEmpty).toList();
    return list.where((r) {
      if (r.cookingTimeMinutes != null) {
        final t = r.cookingTimeMinutes!;
        if (t < _timeRange.start || t > _timeRange.end) return false;
      }
      if (_selectedDifficulties.isNotEmpty) {
        final diff = r.difficultyLevel?.name;
        if (diff == null || !_selectedDifficulties.contains(diff)) return false;
      }
      if (_selectedMealTypes.isNotEmpty) {
        final meal = r.mealType?.name;
        if (meal == null || !_selectedMealTypes.contains(meal)) return false;
      }
      final ingLower = r.ingredients.map((i)=> i.toLowerCase()).toList();
      if (include.isNotEmpty && !include.every((inc)=> ingLower.any((i)=> i.contains(inc)))) return false;
      if (exclude.any((ex)=> ingLower.any((i)=> i.contains(ex)))) return false;
      return true;
    }).toList();
  }

  Future<void> _toggleFavorite(String id) async {
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
    });
    await FavoritesStorage.save(_favorites);
  }

  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Add manually'),
              onTap: () {
                Navigator.pop(ctx);
                _openAddManual();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Import from link'),
              onTap: () {
                Navigator.pop(ctx);
                _openImportLink();
              },
            ),
            ListTile(
              leading: const Icon(Icons.document_scanner),
              title: const Text('Scan (OCR)'),
              onTap: () {
                Navigator.pop(ctx);
                _openOCR();
              },
            ),
            ListTile(
              leading: const Icon(Icons.paste),
              title: const Text('Paste text'),
              onTap: () {
                Navigator.pop(ctx);
                _showPasteDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddManual() async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditRecipeScreen()),
    );
    if (changed == true) _loadRecipes();
  }

  Future<void> _openImportLink() async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ImportRecipeLinkScreen()),
    );
    if (changed == true) _loadRecipes();
  }

  Future<void> _openOCR() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OCRImportScreen()),
    );
  }

  void _showPasteDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Paste Recipe Text'),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: ctrl,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: 'Paste a recipe or ingredient list...'
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              // TODO: parse & continue
              Navigator.pop(dCtx);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(Recipe r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Placeholder image area
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: r.imageUrl == null
                  ? Container(
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
                    )
                  : Image.network(
                      r.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        r.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (kDebugMode)
                      IconButton(
                        tooltip: 'Debug row',
                        icon: const Icon(Icons.bug_report, size: 20),
                        onPressed: () {
                          debugPrint('[CardDebug] id=${r.id} name="${r.name}" imageUrl=${r.imageUrl} ingredientsType=${r.ingredients.runtimeType} instructionsType=${r.instructions.runtimeType} nutritionType=${r.nutritionInfo.runtimeType} ingredientsLen=${r.ingredients.length} instructionsLen=${r.instructions.length}');
                        },
                      ),
                    IconButton(
                      icon: Icon(_favorites.contains(r.id) ? Icons.favorite : Icons.favorite_border, color: _favorites.contains(r.id) ? Colors.redAccent : null),
                      onPressed: () => _toggleFavorite(r.id),
                      tooltip: _favorites.contains(r.id) ? 'Unfavorite' : 'Favorite',
                    ),
                  ],
                ),
                if (r.description != null && r.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    r.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (r.totalMinutes != null || r.cookingTimeMinutes != null)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.access_time, size: 14), const SizedBox(width: 4),
                        Text('${r.totalMinutes ?? r.cookingTimeMinutes} min')
                      ]),
                    if (r.servings != null)
                      Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.restaurant, size: 14), const SizedBox(width: 4), Text('Serves ${r.servings}')]),
                    if (r.author != null && r.author!.isNotEmpty)
                      Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.person, size: 14), const SizedBox(width: 4), Flexible(child: Text(r.author!, overflow: TextOverflow.ellipsis))]),
                    if (r.difficultyLevel != null)
                      Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.local_fire_department, size: 14), const SizedBox(width: 4), Text(r.difficultyLevel!.name)]),
                    if (r.mealType != null)
                      Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.restaurant_menu, size: 14), const SizedBox(width: 4), Text(r.mealType!.name)]),
                    if (r.aiEnrichedAt != null)
                      Tooltip(
                        message: 'AI enriched' + (r.aiConfidenceAvg!=null? ' ${(r.aiConfidenceAvg!*100).toStringAsFixed(0)}%':'') ,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.auto_awesome, size: 14, color: Colors.deepPurple), const SizedBox(width: 4),
                          Text('AI', style: const TextStyle(fontSize: 12))
                        ]),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  void _showAdvancedFilters() {
    final diffs = _recipes.map((r)=> r.difficultyLevel?.name).whereType<String>().toSet().toList()..sort();
    final meals = _recipes.map((r)=> r.mealType?.name).whereType<String>().toSet().toList()..sort();
    RangeValues tempRange = _timeRange;
    final tempInclude = TextEditingController(text: _includeCtrl.text);
    final tempExclude = TextEditingController(text: _excludeCtrl.text);
    final tempDiffs = Set<String>.from(_selectedDifficulties);
    final tempMeals = Set<String>.from(_selectedMealTypes);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setModal) => SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children:[const Icon(Icons.tune), const SizedBox(width:8), const Text('Advanced Filters', style: TextStyle(fontSize:18, fontWeight: FontWeight.bold))]),
                  const SizedBox(height:16),
                  TextField(
                    controller: tempInclude,
                    decoration: const InputDecoration(labelText: 'Include ingredients (comma separated)', hintText: 'chicken, garlic'),
                  ),
                  const SizedBox(height:12),
                  TextField(
                    controller: tempExclude,
                    decoration: const InputDecoration(labelText: 'Exclude ingredients (comma separated)', hintText: 'peanut, cilantro'),
                  ),
                  const SizedBox(height:20),
                  const Text('Time Range (minutes)', style: TextStyle(fontWeight: FontWeight.w600)),
                  RangeSlider(
                    values: tempRange,
                    min: 0,
                    max: 180,
                    divisions: 18,
                    labels: RangeLabels(tempRange.start.round().toString(), tempRange.end.round().toString()),
                    onChanged: (v)=> setModal(()=> tempRange = v),
                  ),
                  if (diffs.isNotEmpty) ...[
                    const SizedBox(height:12),
                    const Text('Difficulty', style: TextStyle(fontWeight: FontWeight.w600)),
                    Wrap(spacing: 6, children: [
                      for (final d in diffs)
                        FilterChip(
                          label: Text(d),
                          selected: tempDiffs.contains(d),
                          onSelected: (sel)=> setModal(()=> sel ? tempDiffs.add(d) : tempDiffs.remove(d)),
                        ),
                    ]),
                  ],
                  if (meals.isNotEmpty) ...[
                    const SizedBox(height:12),
                    const Text('Meal Type', style: TextStyle(fontWeight: FontWeight.w600)),
                    Wrap(spacing: 6, children: [
                      for (final m in meals)
                        FilterChip(
                          label: Text(m),
                          selected: tempMeals.contains(m),
                          onSelected: (sel)=> setModal(()=> sel ? tempMeals.add(m) : tempMeals.remove(m)),
                        ),
                    ]),
                  ],
                  const SizedBox(height:20),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _filterApplied = false;
                            _includeCtrl.clear();
                            _excludeCtrl.clear();
                            _timeRange = const RangeValues(0,180);
                            _selectedDifficulties.clear();
                            _selectedMealTypes.clear();
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('Clear'),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _includeCtrl.text = tempInclude.text;
                            _excludeCtrl.text = tempExclude.text;
                            _timeRange = tempRange;
                            _selectedDifficulties
                              ..clear()
                              ..addAll(tempDiffs);
                            _selectedMealTypes
                              ..clear()
                              ..addAll(tempMeals);
                            _filterApplied = _includeCtrl.text.trim().isNotEmpty || _excludeCtrl.text.trim().isNotEmpty || _timeRange.start>0 || _timeRange.end<180 || _selectedDifficulties.isNotEmpty || _selectedMealTypes.isNotEmpty;
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        height: 170,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[500]),
          ),
        ),
      ),
    );
  }
}
