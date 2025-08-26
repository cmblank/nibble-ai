import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:nibble_ai/models/recipe_model.dart';
import 'package:nibble_ai/services/recipe_service.dart';
import 'recipe_detail_screen.dart';
import '../design_tokens/color_tokens.dart';
import '../design_tokens/typography_tokens.dart';
import '../design_tokens/spacing_tokens.dart';
import '../design_tokens/component_tokens.dart';
import '../widgets/nibble_app_bar.dart';
import 'achievements_screen.dart';
import 'chatbot_screen.dart';
import '../widgets/profile_sheet.dart';
import 'shopping_list_screen.dart';
import '../services/shopping_list_badge_notifier.dart';
import 'pantry_screen_clean.dart';
import 'paste_import_screen.dart';
import 'recipe_review_screen.dart';
import '../services/recipe_event_service.dart';
import '../services/weekly_planner_service.dart';
import '../models/weekly_plan.dart';
import '../models/recipe_enums.dart';
import 'meal_planner_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(NibbleTab tab)? onNavigateToTab;
  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _recipesLoading = false;
  List<PlanEntry> _plan = [];
  bool _planLoading = false;
  Map<String,Recipe> _recipeMap = {};

  @override
  void initState() {
    super.initState();
    ShoppingListBadgeNotifier.instance.start();
    _loadRecipes();
  _loadPlan();
  }

  Widget _weeklyReviewBanner(BuildContext context) {
    // Compute weekly positives (cook_soon, plan_add, cooked_confirm, fav) since Monday
  final now = DateTime.now();
  final todayMidnight = DateTime(now.year, now.month, now.day);
  final monday = todayMidnight.subtract(Duration(days: now.weekday - 1));
    final positives = RecipeEventService.all().where((e){
      return e.timestamp.isAfter(monday) && (e.type=='cook_soon' || e.type=='plan_add' || e.type=='cooked_confirm' || e.type=='fav');
    }).map((e)=> e.recipeId).toSet();
    final count = positives.length;
    const target = 10;
    final done = count >= target;
    final progress = (count/target).clamp(0.0,1.0);
    return Opacity(
      opacity: done ? 0.75 : 1,
      child: GestureDetector(
        onTap: done ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeReviewScreen())).then((_){ setState((){}); }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.spaceMD, vertical: SpacingTokens.spaceSM),
          decoration: BoxDecoration(
            color: done ? DesignTokens.gray200 : DesignTokens.sage100,
            borderRadius: BorderRadius.circular(RadiusTokens.md),
            border: Border.all(color: DesignTokens.sage1000.withOpacity(0.35), width: 1),
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      backgroundColor: Colors.white,
                      valueColor: AlwaysStoppedAnimation(DesignTokens.sage1000),
                    ),
                  ),
                  const Icon(Icons.auto_awesome, size: 18, color: DesignTokens.sage1000),
                ],
              ),
              const SizedBox(width: SpacingTokens.spaceSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      done ? 'Weekly Review Complete' : 'Weekly Recipe Review',
                      style: TextStyles.body100.copyWith(
                        fontWeight: TypographyTokens.bold,
                        color: const Color(0xFF1D2126),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      done ? '10 saved for personalization' : 'Pick ${target - count} more to reach $target',
                      style: TextStyles.body75.copyWith(
                        color: DesignTokens.gray600,
                        fontWeight: TypographyTokens.medium,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(done ? Icons.check_circle : Icons.arrow_forward_ios, size: 18, color: DesignTokens.gray600),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadRecipes() async {
    setState(() { _recipesLoading = true; });
    try {
      final rec = await RecipeService.fetchAll();
      if (!mounted) return;
  setState(() { _recipesLoading = false; _recipeMap = {for (final r in rec) r.id: r}; });
      developer.log('Loaded ${rec.length} recipes for home screen', name: 'HomeScreen');
    } catch(e){
      if (!mounted) return;
      setState(() { _recipesLoading = false; });
      developer.log('Failed loading recipes: $e', name: 'HomeScreen', error: e);
    }
  }

  Future<void> _loadPlan() async {
    setState(()=> _planLoading = true);
    try {
      await WeeklyPlannerService.init();
      final week = WeeklyPlannerService.loadWeek(DateTime.now());
      if (!mounted) return;
      setState(()=> _plan = week..sort((a,b)=> a.date.compareTo(b.date)) );
    } catch(e) {
      developer.log('Failed loading plan: $e', name: 'HomeScreen');
    } finally {
      if (mounted) setState(()=> _planLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.gray100,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-import-paste',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PasteImportScreen()),
          );
        },
        icon: const Icon(Icons.paste),
        label: const Text('Import Paste'),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, inner) => [
          NibbleSliverAppBar(
            currentTab: NibbleTab.home,
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
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full-width header with no top padding
              _buildWelcomeBanner(context),
              const SizedBox(height: SpacingTokens.spaceXL),
              // Main content padded
              Padding(
                padding: const EdgeInsets.all(SpacingTokens.spaceLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _weeklyReviewBanner(context),
                    const SizedBox(height: SpacingTokens.spaceXL),
                    // Tonight Section
                    _buildTonightSection(),
                    const SizedBox(height: SpacingTokens.spaceLG),
                    // Spacer before upcoming meals
                    const SizedBox(height: SpacingTokens.spaceXL),
                    // Upcoming Meals
                    _buildUpcomingMealsSection(),
                    const SizedBox(height: SpacingTokens.spaceXL),
                    // Cooking Journey
                    _buildCookingJourneySection(context),
                    const SizedBox(height: SpacingTokens.spaceXL),
                    // Pantry Status
                    _buildPantryStatusSection(),
                    const SizedBox(height: 100), // Extra space for bottom nav
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SpacingTokens.spaceMD), // 16px padding
      decoration: const BoxDecoration(
        color: DesignTokens.sage1000, // sage/1000 token
        // Make header flush with app bar: no rounded corners
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
  crossAxisAlignment: CrossAxisAlignment.center, // Center alignment
        children: [
          // Text section with 4px spacing between lines
          Column(
            children: [
              Text(
                'Welcome, Courtney',
                style: TextStyles.heading150.copyWith(
                  color: Colors.white,
                  // heading150 is already semibold; keep explicit for clarity
                  fontWeight: TypographyTokens.semibold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4), // 4px spacing between text lines
              Text(
                'Let\'s cook something delicious.',
                style: TextStyles.body100.copyWith(
                  color: Colors.white,
                  fontWeight: TypographyTokens.medium,
                  fontSize: 16,
                  height: 20 / 14, // line height 20px
                  fontFamily: 'Manrope',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 28), // 28px spacing between text and buttons
    Row(
            children: [
              Expanded(
                child: _buildWelcomeButton(
                  'Plan Week',
      Icons.calendar_today,
      () {
        // Prefer switching to the Planning tab rather than pushing a new screen
  widget.onNavigateToTab?.call(NibbleTab.planning);
      },
      assetName: 'assets/images/icon-calendar-date.png',
                ),
              ),
              const SizedBox(width: SpacingTokens.spaceSM), // 8px gap between buttons
              Expanded(
                child: _buildWelcomeButton(
                  'Add Pantry Item',
      Icons.check,
      () {
  Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PantryScreen()),
        );
      },
      assetName: 'assets/images/icon-approve-circle.png',
                ),
              ),
              const SizedBox(width: SpacingTokens.spaceSM), // 8px gap between buttons
              Expanded(
                child: StreamBuilder<int>(
                  stream: ShoppingListBadgeNotifier.instance.countStream,
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return _buildWelcomeButton(
                      'Grocery List',
                      Icons.shopping_cart,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ShoppingListScreen()),
                        );
                      },
                      assetName: 'assets/images/icon-cart.png',
                      badge: count > 0 ? (count > 99 ? '99+' : count.toString()) : null,
                      badgeColor: DesignTokens.flameOrange,
                      badgeTop: -6,
                      badgeRight: -6,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeButton(String text, IconData icon, VoidCallback onTap, {String? badge, String? assetName, Color? badgeColor, double? badgeTop, double? badgeRight}) {
    var body75 = TextStyles.body75;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.spaceSM), // 8px padding
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(RadiusTokens.lg),
          border: Border.all(
            color: DesignTokens.gray300,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (assetName != null)
                    Image.asset(
                      assetName,
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                    )
                  else
                    Icon(
                      icon,
                      color: DesignTokens.gray600, // Dark gray icon
                      size: 24,
                    ),
                  const SizedBox(height: SpacingTokens.spaceXS),
                  Text(
                    text,
                    style: TextStyles.body75.copyWith(
                      color: const Color.fromARGB(255, 41, 44, 47), // color/text/medium token
                      fontWeight: TypographyTokens.semibold,
                      fontSize: 12,
                      fontFamily: 'Manrope',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: badgeTop ?? 8,
                right: badgeRight ?? 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor ?? DesignTokens.brick900,
                    borderRadius: BorderRadius.circular(RadiusTokens.full),
                  ),
                  child: Text(
                    badge,
                    style: body75.copyWith(
                      color: Colors.white,
                      fontWeight: TypographyTokens.semibold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTonightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tonight',
              style: TextStyles.heading150.copyWith(
                fontWeight: TypographyTokens.bold,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_)=> const MealPlannerScreen())); },
              child: Text(
                'Edit Plan →',
                style: TextStyles.body85.copyWith(
                  color: DesignTokens.brick900,
                  fontWeight: TypographyTokens.medium,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.spaceSM),
        _buildTonightRecipeCard(),
      ],
    );
  }
  Recipe? get _tonightRecipe {
    final today = DateTime.now();
    final d0 = DateTime(today.year, today.month, today.day);
    final entry = _plan.firstWhere(
  (e) => e.mealType==MealType.dinner && e.date.year==d0.year && e.date.month==d0.month && e.date.day==d0.day,
  orElse: ()=> PlanEntry(date: DateTime(1970,1,1), mealType: MealType.dinner, recipeId: ''),
    );
    if (entry.recipeId.isEmpty) return null;
    return _recipeMap[entry.recipeId];
  }

  Widget _buildTonightRecipeCard() {
    final r = _tonightRecipe;
    if (_recipesLoading && r == null) {
      return Container(
        width: double.infinity,
        height: 260,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(RadiusTokens.xl),
        ),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }
    return GestureDetector(
      onTap: r == null ? null : () => _openRecipe(r),
      child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(RadiusTokens.xl),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.gray400.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recipe Image
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(RadiusTokens.xl),
              ),
              image: r?.imageUrl != null && r!.imageUrl!.isNotEmpty
                  ? DecorationImage(image: NetworkImage(r.imageUrl!), fit: BoxFit.cover)
                  : const DecorationImage(image: AssetImage('assets/images/meal-salad.png'), fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(SpacingTokens.spaceLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r?.name ?? 'Add a recipe', style: TextStyles.heading125.copyWith(fontWeight: TypographyTokens.bold)),
                const SizedBox(height: SpacingTokens.spaceSM),
                Row(
                  children: [
                    _buildRecipeDetail(Icons.people, r?.servings?.toString() ?? '—'),
                    const SizedBox(width: SpacingTokens.spaceLG),
                    _buildRecipeDetail(
                      Icons.access_time,
                      r == null
                          ? '—'
                          : ((r.totalMinutes ?? r.cookingTimeMinutes) != null
                              ? '${(r.totalMinutes ?? r.cookingTimeMinutes)}m'
                              : '—'),
                    ),
                  ],
                ),
                const SizedBox(height: SpacingTokens.spaceMD),
                Wrap(
                  spacing: SpacingTokens.spaceSM,
                  runSpacing: 4,
                  children: [
                    if (r != null && (r.cookingTimeMinutes ?? r.totalMinutes) != null) _buildRecipeTag('Time ${(r.cookingTimeMinutes ?? r.totalMinutes)}m'),
                    if (r?.mealType != null) _buildRecipeTag(r!.mealType!.name),
                  ],
                ),
                const SizedBox(height: SpacingTokens.spaceLG),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: r == null ? null : () {},
                        style: ComponentTokens.secondaryButton(
                          backgroundColor: Colors.orange.shade100,
                          foregroundColor: Colors.orange.shade800,
                        ),
                        child: const Text('Swap'),
                      ),
                    ),
                    const SizedBox(width: SpacingTokens.spaceMD),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: r == null ? null : () => _openRecipe(r),
                        style: ComponentTokens.primaryButton(
                          backgroundColor: DesignTokens.brick900,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Cook Now'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildRecipeDetail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: DesignTokens.gray600,
        ),
        const SizedBox(width: SpacingTokens.spaceXS),
        Text(
          text,
          style: TextStyles.body85.copyWith(
            color: DesignTokens.gray600,
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.spaceSM,
        vertical: SpacingTokens.spaceXS,
      ),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(RadiusTokens.full),
      ),
      child: Text(
        text,
        style: TextStyles.body75.copyWith(
          color: Colors.green.shade700,
          fontWeight: TypographyTokens.medium,
        ),
      ),
    );
  }

  // ignore: unused_element

  Widget _buildUpcomingMealsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(
              'Upcoming Meals',
              style: TextStyles.heading150.copyWith(
                fontWeight: TypographyTokens.bold,
              ),
            )),
            GestureDetector(
              onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_)=> const MealPlannerScreen())); },
              child: Text(
                'Edit Plan →',
                style: TextStyles.body85.copyWith(
                  color: DesignTokens.brick900,
                  fontWeight: TypographyTokens.medium,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.spaceMD),
        SizedBox(
          height: 280,
          child: (_planLoading || _recipesLoading)
              ? const Center(child: CircularProgressIndicator())
              : Builder(builder: (ctx) {
                  final today = DateTime.now();
                  final todayKey = DateTime(today.year, today.month, today.day);
                  final upcomingEntries = _plan.where((e){
                    final d = DateTime(e.date.year, e.date.month, e.date.day);
                    return e.mealType==MealType.dinner && d.isAfter(todayKey);
                  }).toList()
                    ..sort((a,b)=> a.date.compareTo(b.date));
                  final recipes = <Recipe>[];
                  for (final entry in upcomingEntries) {
                    final r = _recipeMap[entry.recipeId];
                    if (r != null) recipes.add(r);
                  }
                  if (recipes.isEmpty) {
                    return Row(children:[
                      Expanded(child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(RadiusTokens.lg),
                          border: Border.all(color: DesignTokens.gray300),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Text('Plan dinners to see upcoming meals', style: TextStyles.body85),
                      )),
                    ]);
                  }
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (c, i) {
                      final r = recipes[i];
                      final assetFallback = i.isEven ? 'assets/images/meal-spagetti.png' : 'assets/images/meal-taco-2.png';
                      return _buildUpcomingMealCard(
                        r.name,
                        assetFallback,
                        (r.servings ?? 0) > 0 ? r.servings.toString() : '—',
                        (r.totalMinutes ?? r.cookingTimeMinutes) != null ? '${r.totalMinutes ?? r.cookingTimeMinutes}m' : '—',
                        hasRefreshIcon: false,
                        recipe: r,
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: SpacingTokens.spaceMD),
                    itemCount: recipes.length.clamp(0, 10),
                  );
                }),
        ),
      ],
    );
  }

  void _openRecipe(Recipe r) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipeId: r.id, initial: r)));
  }

  Widget _buildUpcomingMealCard(
    String title,
    String imagePath,
    String servings,
    String time, {
    bool hasRefreshIcon = false,
    Recipe? recipe,
  }) {
    final cookedTime = recipe != null
        ? (recipe.totalMinutes ?? recipe.cookingTimeMinutes)
        : null;
    return GestureDetector(
      onTap: recipe == null ? null : () => _openRecipe(recipe),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(RadiusTokens.lg),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.gray400.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 108,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(RadiusTokens.lg),
                    ),
                    image: recipe?.imageUrl != null && recipe!.imageUrl!.isNotEmpty
                        ? DecorationImage(image: NetworkImage(recipe.imageUrl!), fit: BoxFit.cover)
                        : DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
                  ),
                ),
                if (hasRefreshIcon)
                  Positioned(
                    top: SpacingTokens.spaceSM,
                    right: SpacingTokens.spaceSM,
                    child: Container(
                      padding: const EdgeInsets.all(SpacingTokens.spaceXS),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(RadiusTokens.full),
                      ),
                      child: const Icon(
                        Icons.refresh,
                        size: 16,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SpacingTokens.spaceMD,
                SpacingTokens.spaceSM,
                SpacingTokens.spaceMD,
                SpacingTokens.spaceSM,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe?.name ?? title,
                    style: TextStyles.body100.copyWith(fontWeight: TypographyTokens.semibold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: SpacingTokens.spaceXS),
                  Wrap(
                    spacing: SpacingTokens.spaceLG,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildRecipeDetail(Icons.people, recipe?.servings?.toString() ?? servings),
                      _buildRecipeDetail(Icons.access_time, cookedTime != null ? '${cookedTime}m' : time),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.spaceXS),
                  Wrap(
                    spacing: SpacingTokens.spaceSM,
                    runSpacing: 4,
                    children: [
                      if (recipe?.mealType != null) _buildRecipeTag(recipe!.mealType!.name),
                      if (cookedTime != null) _buildRecipeTag('${cookedTime}m'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCookingJourneySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(builder: (ctx, constraints) {
          final narrow = constraints.maxWidth < 360;
          final title = Text('Your Cooking Journey', style: TextStyles.heading150.copyWith(fontWeight: TypographyTokens.bold));
          final review = GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeReviewScreen())),
            child: Text('Review', style: TextStyles.body85.copyWith(color: DesignTokens.brick900, fontWeight: TypographyTokens.medium)),
          );
          final seeAll = GestureDetector(
            onTap: () {},
            child: Text('See all', style: TextStyles.body85.copyWith(color: DesignTokens.brick900, fontWeight: TypographyTokens.medium)),
          );
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 4),
                Row(children: [review, const SizedBox(width: 12), seeAll]),
              ],
            );
          }
          return Row(children: [
            Expanded(child: title),
            review,
            const SizedBox(width: 12),
            seeAll,
          ]);
        }),
        const SizedBox(height: SpacingTokens.spaceMD),
        Row(
          children: [
            Expanded(
              child: _buildJourneyCard(
                Icons.local_fire_department,
                'Streak',
                '4 days',
                'This Week',
                Colors.orange,
              ),
            ),
            const SizedBox(width: SpacingTokens.spaceMD),
            Expanded(
              child: _buildJourneyCard(
                Icons.bookmark,
                'Recipes',
                '12 cooked',
                'This Month',
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJourneyCard(
    IconData icon,
    String title,
    String value,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.spaceLG),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.gray400.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: SpacingTokens.spaceSM),
          Text(
            title,
            style: TextStyles.body85.copyWith(
              fontWeight: TypographyTokens.medium,
            ),
          ),
          const SizedBox(height: SpacingTokens.spaceXS),
          Text(
            value,
            style: TextStyles.heading125.copyWith(
              fontWeight: TypographyTokens.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyles.body75.copyWith(
              color: DesignTokens.gray600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPantryStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Pantry Status',
              style: TextStyles.heading150.copyWith(
                fontWeight: TypographyTokens.bold,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {},
              child: Text(
                'See all →',
                style: TextStyles.body85.copyWith(
                  color: DesignTokens.brick900,
                  fontWeight: TypographyTokens.medium,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.spaceMD),
        Row(
          children: [
            Expanded(
              child: _buildPantryStatusCard(
                Icons.warning,
                'Low Stock',
                '5 Items',
                Colors.orange,
              ),
            ),
            const SizedBox(width: SpacingTokens.spaceMD),
            Expanded(
              child: _buildPantryStatusCard(
                Icons.access_time,
                'Expiring Soon',
                '5 Items',
                Colors.red,
              ),
            ),
            const SizedBox(width: SpacingTokens.spaceMD),
            Expanded(
              child: _buildPantryStatusCard(
                Icons.shopping_cart,
                'Shopping List',
                '5 Items',
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPantryStatusCard(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.spaceMD),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.gray400.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: SpacingTokens.spaceSM),
          Text(
            title,
            style: TextStyles.body75.copyWith(
              fontWeight: TypographyTokens.medium,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SpacingTokens.spaceXS),
          Text(
            value,
            style: TextStyles.body85.copyWith(
              fontWeight: TypographyTokens.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

}