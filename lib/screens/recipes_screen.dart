import 'package:flutter/material.dart';
import '../design_tokens/color_tokens.dart';
import '../widgets/nibble_app_bar.dart';
import 'chatbot_screen.dart';
import 'achievements_screen.dart';
import '../widgets/profile_sheet.dart';
import '../widgets/pantry_search_header.dart';
import '../widgets/category_chip.dart';
import '../utils/profile_storage.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  List<String> _categories = const ['All', 'Recent', 'Favorites'];

  @override
  void initState() {
    super.initState();
    _loadRecipeCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                          icon: const Icon(Icons.tune),
                          onPressed: () {
                            // TODO: recipes filter dialog
                          },
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
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 10, // Replace with actual recipe count
                itemBuilder: (context, index) {
                  return _buildRecipeCard();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'recipes-fab',
        onPressed: () {
          // TODO: Implement add recipe
        },
  tooltip: 'Add recipe',
  child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildRecipeCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.image, size: 48, color: Colors.grey),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recipe Name',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.favorite_border),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16),
                    const SizedBox(width: 4),
                    const Text('30 min'),
                    const SizedBox(width: 16),
                    const Icon(Icons.local_fire_department, size: 16),
                    const SizedBox(width: 4),
                    const Text('Easy'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
