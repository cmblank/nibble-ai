import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/nibble_app_bar.dart';
import 'chatbot_screen.dart';
import 'achievements_screen.dart';
import '../widgets/profile_sheet.dart';
import '../services/weekly_planner_service.dart';
import '../services/recipe_service.dart';
import '../services/sync_service.dart';
import '../models/weekly_plan.dart';
import '../models/recipe_model.dart';
import '../models/recipe_enums.dart';
import '../services/user_profile_service.dart';
import '../services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/suggestion_engine.dart';
import '../services/pantry_service.dart';
import '../services/adaptive_weight_service.dart';
import '../services/recipe_event_service.dart';
import '../services/settings_service.dart';
import '../models/user_profile.dart';
import '../design_tokens/color_tokens.dart';
import '../design_tokens/typography_tokens.dart';
import 'recipe_detail_screen.dart';
import 'planning_swipe_screen.dart';

class MealPlannerScreen extends StatelessWidget {
  const MealPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MealPlanner();
  }
}

class _MealPlanner extends StatefulWidget {
  const _MealPlanner();
  @override
  State<_MealPlanner> createState() => _MealPlannerState();
}

class _MealPlannerState extends State<_MealPlanner> {
  bool _loading = true;
  List<PlanEntry> _plan = [];
  List<Recipe> _recipes = [];
  List<ShoppingListItem> _shopping = [];
  DateTime _anchor = DateTime.now();
  final Set<String> _acquired = {}; // local acquired ingredients
  static const _acquiredKeyPrefix = 'acquired_';
  int _breakfasts = 0;
  int _lunches = 0;
  DateTime? _lastSync;
  // Autosync state
  final List<PlanEntry> _pendingQueue = []; // local edits awaiting push
  Timer? _debounce; // debounce timer for autosync
  bool _syncInFlight = false; // guard concurrent sync
  static const Duration _autosyncDebounce = Duration(seconds: 4);
  static const Duration _maxSilentPullAge = Duration(minutes: 5); // after this, pull remote during autosync flush
  static const String _pendingQueueKey = 'pending_plan_queue';
  // Connectivity & backoff
  int _consecutiveFailures = 0;
  StreamSubscription<dynamic>? _connSub; // handles API returning List<ConnectivityResult>
  bool _online = true;
  Timer? _backoffTimer;
  // Swap undo stack: list of (oldEntry, newEntry)
  final List<Map<String,PlanEntry>> _swapHistory = [];
  // Suggestions
  List<ScoredRecipe> _dinnerSuggestions = [];
  UserProfile? _profile;
  int _desiredDinnersCache = 7; // snapshot of settings at last load

  @override
  void initState() {
    super.initState();
    _load();
    _connSub = Connectivity().onConnectivityChanged.listen((res){
      final wasOnline = _online;
      // Treat emission as List<ConnectivityResult> (connectivity_plus v6)
      try {
        final list = res.cast<ConnectivityResult>();
        _online = list.any((r) => r != ConnectivityResult.none);
      } catch (_) { _online = true; }
      if (_online && !wasOnline) {
        // Came online: attempt immediate flush (respect backoff cancellation)
        _backoffTimer?.cancel();
        _scheduleAutosync();
      }
      if (mounted) setState((){});
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
  final userId = SupabaseService.currentUser?.id ?? 'anon';
  await UserProfileService.getOrCreate(userId); // ensure profile cached
    final pool = await RecipeService.fetchAll();
    await WeeklyPlannerService.init();
    var plan = WeeklyPlannerService.loadWeek(_anchor);
    // Desired dinners from settings (if loaded); fallback to 7
    final settings = SettingsService();
    if(!settings.isLoaded){ await settings.load(); }
    final desiredDinners = settings.plannedDinners;
  _desiredDinnersCache = desiredDinners;
    if (plan.isEmpty) {
      plan = await WeeklyPlannerService.generateWeek(userId: userId, pool: pool, anchor: _anchor, breakfasts: _breakfasts, lunches: _lunches, dinners: desiredDinners);
    }
    // Pull remote and merge
    final remote = await SyncService.pullPlan(userId);
    if (remote.isNotEmpty) {
      final merged = SyncService.mergePlan(local: plan, remote: remote);
      // Save merged locally & push diff
      for (final e in merged) { await WeeklyPlannerService.saveEntry(e); }
      // fire-and-forget push
      // ignore: unawaited_futures
      SyncService.pushPlanEntries(merged, userId);
      plan = merged;
      _lastSync = DateTime.now();
    }
    final shopping = await WeeklyPlannerService.buildShoppingList(plan, pool);
    // Load acquired set for this week from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final key = _acquiredStorageKey();
    final stored = prefs.getStringList(key) ?? const [];
    if (!mounted) return;
    setState(() {
      _recipes = pool;
      _plan = plan;
      _shopping = shopping;
      _acquired
        ..clear()
        ..addAll(stored);
      _loading = false;
    });
  await _computeDinnerSuggestions();
  // Load any persisted pending queue (best effort)
  _restorePendingQueue();
  }

  // Primary build already exists earlier; suggestions row is injected elsewhere.

  Future<void> _computeDinnerSuggestions() async {
    try {
      final userId = SupabaseService.currentUser?.id ?? 'anon';
      final profile = await UserProfileService.getOrCreate(userId);
      _profile = profile;
      final pantryItems = await PantryService.fetchItems();
      final ctx = SuggestionContext(
        timeAvailableMinutes: 45,
        desiredServings: profile.baseHouseholdSize,
        pantryItems: pantryItems.map((p)=> p.name).toSet(),
      );
      SuggestionEngineWeights weights = const SuggestionEngineWeights();
      try { weights = await AdaptiveWeightService.load(userId); } catch(_){ }
      final plannedIds = _plan.map((e)=> e.recipeId).toSet();
      final suggestions = SuggestionEngine.suggestDinnerRow(
        pool: _recipes,
        profile: profile,
        ctx: ctx,
        plannedRecipeIds: plannedIds,
        limit: 15,
        weights: weights,
      );
      if (!mounted) return;
      setState(()=> _dinnerSuggestions = suggestions);
    } catch(e) {
      // silent
    }
  }

  int get _plannedDinnerCount {
    final todayWeekMonday = _anchor.subtract(Duration(days: _anchor.weekday - 1));
    final weekEnd = todayWeekMonday.add(const Duration(days:7));
    return _plan.where((e)=> e.mealType==MealType.dinner && e.date.isAfter(todayWeekMonday.subtract(const Duration(milliseconds:1))) && e.date.isBefore(weekEnd)).length;
  }

  Future<void> _addDinnerToNextOpen(Recipe r) async {
    // find first unplanned dinner day this week; else replace furthest future
    final monday = _anchor.subtract(Duration(days: _anchor.weekday - 1));
    final plannedDays = {for (final e in _plan.where((e)=> e.mealType==MealType.dinner)) DateTime(e.date.year,e.date.month,e.date.day)};
    DateTime? target;
    for (int i=0;i<7;i++) {
      final d = DateTime(monday.year,monday.month,monday.day).add(Duration(days:i));
      if (!plannedDays.contains(d)) { target = d; break; }
    }
    target ??= monday.add(const Duration(days:6));
    final entry = PlanEntry(date: target, mealType: MealType.dinner, recipeId: r.id, servings: _profile?.baseHouseholdSize);
    await WeeklyPlannerService.saveEntry(entry);
    setState(() {
      _plan.removeWhere((e)=> e.date==entry.date && e.mealType==entry.mealType);
      _plan.add(entry); _plan.sort((a,b)=> a.date.compareTo(b.date));
    });
    // log event
    // ignore: unawaited_futures
    RecipeEventService.log(RecipeEvent(recipeId: r.id, userId: SupabaseService.currentUser?.id ?? 'anon', type: 'plan_add'));
    await _computeDinnerSuggestions();
  }


  Future<void> _shuffleSpecific(DateTime date, MealType meal) async {
  final userId = SupabaseService.currentUser?.id ?? 'anon';
    final entry = await WeeklyPlannerService.shuffleDay(date, userId: userId, pool: _recipes, mealType: meal);
    if (entry != null) {
      await _refreshShopping();
      setState(() {
        _plan.removeWhere((e) => e.date.year==date.year && e.date.month==date.month && e.date.day==date.day && e.mealType==entry.mealType);
        _plan.add(entry);
        _plan.sort((a,b)=> a.date.compareTo(b.date));
      });
    }
  }

  Widget _suggestionsSection() {
    if (_dinnerSuggestions.isEmpty) return const SizedBox.shrink();
    final cats = _categorizedSuggestions();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Suggestions', style: TextStyles.heading125.copyWith(fontWeight: TypographyTokens.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: DesignTokens.gray200, borderRadius: BorderRadius.circular(20)),
              child: Text('$_plannedDinnerCount / 7 dinners planned', style: TextStyles.body75),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final entry in cats.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Row(
              children: [
                Text(entry.key, style: TextStyles.body100.copyWith(fontWeight: TypographyTokens.bold)),
                const SizedBox(width: 6),
                Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('${entry.value.length}', style: TextStyles.body75.copyWith(color: Colors.black54)),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: entry.value.length.clamp(0, 12),
              separatorBuilder: (_, __)=> const SizedBox(width: 16),
              itemBuilder: (c,i)=> _suggestionCard(entry.value[i]),
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Map<String,List<ScoredRecipe>> _categorizedSuggestions() {
    final map = <String,List<ScoredRecipe>>{};
    for (final sr in _dinnerSuggestions) {
      final r = sr.reasons;
      String cat;
      if (r.any((s)=> s.contains('Pantry') || s.contains('ingredients'))) {
        cat = 'Pantry Friendly';
      } else if (r.any((s)=> s.contains('Quick'))) {
        cat = 'Quick & Easy';
      } else if (r.any((s)=> s.contains('liked'))) {
        cat = 'Favorites Revisited';
      } else if (r.any((s)=> s.contains('New'))) {
        cat = 'New This Month';
      } else if (r.any((s)=> s.contains('Variety'))) {
        cat = 'Adds Variety';
      } else {
        cat = 'Recommended';
      }
      map.putIfAbsent(cat, ()=> []).add(sr);
    }
    // Simple ordering
    final order = ['Pantry Friendly','Quick & Easy','Favorites Revisited','New This Month','Adds Variety','Recommended'];
    final sorted = <String,List<ScoredRecipe>>{};
    for (final k in order) { if (map.containsKey(k)) sorted[k] = map[k]!; }
    for (final k in map.keys) { sorted.putIfAbsent(k, ()=> map[k]!); }
    return sorted;
  }

  Widget _weekTabs() {
    final monday = _anchor.subtract(Duration(days: _anchor.weekday - 1));
    final weeks = List.generate(6, (i)=> monday.add(Duration(days: 7*i)));
    final dinnerCount = _plan.where((e)=> e.mealType==MealType.dinner).length;
    final showRebalance = dinnerCount != _desiredDinnersCache;
    return SizedBox(
      height: 100, // increased to prevent RenderFlex overflow after adding Plan button
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Week Dinners: $dinnerCount / $_desiredDinnersCache', style: TextStyles.body75.copyWith(fontWeight: TypographyTokens.medium)),
              if (showRebalance) const SizedBox(width: 8),
              if (showRebalance) TextButton.icon(
                onPressed: _rebalanceWeek,
                icon: const Icon(Icons.sync, size: 16),
                label: const Text('Adjust'),
              ),
              const Spacer(),
              // Quick access to swipe planning for current week only
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_)=> const PlanningSwipeScreen()));
                  // Reload after returning to reflect any new dinners
                  if (mounted) { _load(); }
                },
                icon: const Icon(Icons.view_carousel, size: 16),
                label: const Text('Plan Dinners'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (c,i) {
                final wStart = weeks[i];
                final wEnd = wStart.add(const Duration(days:6));
                final selected = wStart.year==monday.year && wStart.month==monday.month && wStart.day==monday.day;
                final label = '${_shortMonth(wStart.month)} ${wStart.day}-${wEnd.day}';
                return GestureDetector(
                  onTap: () { setState(()=> _anchor = wStart); _load(); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? DesignTokens.white : DesignTokens.gray200,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: selected ? DesignTokens.sage1000 : Colors.transparent),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(label, style: TextStyles.body75.copyWith(fontWeight: selected ? TypographyTokens.bold : TypographyTokens.medium, color: selected ? DesignTokens.sage1000 : Colors.black87)),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_)=> PlanningSwipeScreen(anchorMonday: wStart)));
                            if (mounted) { _load(); }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: selected ? DesignTokens.sage1000 : Colors.black54, borderRadius: BorderRadius.circular(4)),
                            child: Text('Plan', style: TextStyles.caption.copyWith(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __)=> const SizedBox(width: 8),
              itemCount: weeks.length,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _rebalanceWeek() async {
    // Recompute desired from settings
    final settings = SettingsService();
    if(!settings.isLoaded){ await settings.load(); }
    final desired = settings.plannedDinners;
    final dinners = _plan.where((e)=> e.mealType==MealType.dinner).toList()..sort((a,b)=> a.date.compareTo(b.date));
    if (dinners.length == desired) return; // nothing
    if (dinners.length > desired) {
      // Remove extra dinners: remove from end by default
      final toRemove = dinners.sublist(desired);
      for (final e in toRemove) {
        _plan.removeWhere((p)=> p.date==e.date && p.mealType==e.mealType);
        await WeeklyPlannerService.saveEntry(e.copyWith(recipeId: '')); // mark empty or consider delete mechanism
      }
    } else {
      // Need more dinners: generate additional suggestions distinct from existing
      final userId = SupabaseService.currentUser?.id ?? 'anon';
      final pool = _recipes;
      final existingIds = _plan.map((e)=> e.recipeId).toSet();
      final profile = _profile ?? await UserProfileService.getOrCreate(userId);
      final pantryItems = await PantryService.fetchItems();
      final ctx = SuggestionContext(timeAvailableMinutes: 45, desiredServings: profile.baseHouseholdSize, pantryItems: pantryItems.map((p)=>p.name).toSet());
      SuggestionEngineWeights weights = const SuggestionEngineWeights();
      try { weights = await AdaptiveWeightService.load(userId); } catch(_){}
      final ranked = SuggestionEngine.rank(pool: pool, profile: profile, ctx: ctx, weights: weights)
        .where((sr)=> !existingIds.contains(sr.recipe.id))
        .toList();
      final monday = _anchor.subtract(Duration(days: _anchor.weekday - 1));
      int added = 0;
      for (int i=0; i<7 && dinners.length + added < desired && i<ranked.length; i++) {
        final date = monday.add(Duration(days: i));
        final alreadyHas = _plan.any((p)=> p.date.year==date.year && p.date.month==date.month && p.date.day==date.day && p.mealType==MealType.dinner);
        if (alreadyHas) continue;
        final sr = ranked[added];
        final entry = PlanEntry(date: date, mealType: MealType.dinner, recipeId: sr.recipe.id, servings: profile.baseHouseholdSize);
        _plan.add(entry);
        await WeeklyPlannerService.saveEntry(entry);
        added++;
      }
    }
    setState((){});
  }

  String _shortMonth(int m) {
    const names = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return names[m-1];
  }

  Widget _suggestionCard(ScoredRecipe sr) {
    final r = sr.recipe;
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.gray300),
        boxShadow: [BoxShadow(color: DesignTokens.gray400.withValues(alpha:0.08), blurRadius:6, offset: const Offset(0,2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> RecipeDetailScreen(recipeId: r.id, initial: r))),
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                image: r.imageUrl!=null && r.imageUrl!.isNotEmpty
                  ? DecorationImage(image: NetworkImage(r.imageUrl!), fit: BoxFit.cover)
                  : const DecorationImage(image: AssetImage('assets/images/meal-salad.png'), fit: BoxFit.cover),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyles.body100.copyWith(fontWeight: TypographyTokens.semibold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: -4,
                  children: sr.reasons.take(2).map((reason)=> _reasonChip(reason)).toList(),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: ()=> _addDinnerToNextOpen(r),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6), side: BorderSide(color: DesignTokens.gardenHerb)),
                    child: const Text('Add to Week'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reasonChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: DesignTokens.sage100, borderRadius: BorderRadius.circular(12), border: Border.all(color: DesignTokens.sage1000.withOpacity(0.4))),
  child: Text(text, style: TextStyles.body75.copyWith(color: DesignTokens.sage1000)),
    );
  }

  Future<void> _refreshShopping() async {
    final shopping = await WeeklyPlannerService.buildShoppingList(_plan, _recipes);
    if (mounted) setState(()=> _shopping = shopping);
  }

  Future<void> _syncNow() async {
  final userId = SupabaseService.currentUser?.id ?? 'anon';
    // Try to flush any pending local edits first (best-effort)
    await _flushPending(pushOnly: true);
    final remote = await SyncService.pullPlan(userId);
    if (remote.isEmpty) {
      // No remote data (first time or offline). If we have a full local plan, push it (fire & forget)
      if (_plan.isNotEmpty) {
        // ignore: unawaited_futures
        SyncService.pushPlanEntries(_plan, userId);
      }
      setState(()=> _lastSync = DateTime.now());
      return;
    }
    final merged = SyncService.mergePlan(local: _plan, remote: remote);
    bool changed = false;
    if (merged.length != _plan.length) {
      changed = true;
    } else {
      for (int i=0;i<merged.length;i++) {
        final a = merged[i];
        final b = _plan[i];
        if (a.recipeId!=b.recipeId || a.cooked!=b.cooked || a.servings!=b.servings) { changed = true; break; }
      }
    }
    for (final e in merged) { await WeeklyPlannerService.saveEntry(e); }
    // ignore: unawaited_futures
    SyncService.pushPlanEntries(merged, userId);
    if (changed) {
      final shopping = await WeeklyPlannerService.buildShoppingList(merged, _recipes);
      if (!mounted) return;
      setState(() {
        _plan = merged;
        _shopping = shopping;
        _lastSync = DateTime.now();
      });
    } else {
      setState(()=> _lastSync = DateTime.now());
    }
  }

  String _sinceSync() {
    if (_lastSync == null) return '';
    final diff = DateTime.now().difference(_lastSync!);
    if (diff.inMinutes < 1) return 'Synced now';
    if (diff.inMinutes < 60) return 'Synced ${diff.inMinutes}m ago';
    return 'Synced ${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NibbleAppBar(
        currentTab: NibbleTab.planning,
        showAchievements: true,
        showBack: true,
        onChatTap: (_) => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatbotScreen())),
        onAchievementsTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementsScreen())),
        onProfileTap: () => showProfileSheet(context),
        actions: [
          _mealCountSelector('B', _breakfasts, (v){ setState(()=> _breakfasts = v); }),
          const SizedBox(width: 4),
            _mealCountSelector('L', _lunches, (v){ setState(()=> _lunches = v); }),
          const SizedBox(width: 8),
          if (_lastSync != null)
            Padding(
              padding: const EdgeInsets.only(right:8),
              child: Text(_sinceSync(), style: const TextStyle(fontSize: 11, color: Colors.white70)),
            ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync now',
            onPressed: () async {
              await _syncNow();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Regenerate Week',
            onPressed: _load,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_pendingQueue.isNotEmpty)
                  Material(
                    color: Colors.orange.shade700,
                    child: InkWell(
                      onTap: _flushPending,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.sync_problem, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Unsynced changes (${_pendingQueue.length}) – tap to sync now', style: const TextStyle(color: Colors.white, fontSize: 12))),
                            TextButton(onPressed: _flushPending, child: const Text('Sync', style: TextStyle(color: Colors.white)))
                          ],
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
          child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _weekTabs(),
                        const SizedBox(height: 12),
                        _suggestionsSection(),
                        const SizedBox(height: 12),
                        _planTable(),
                        const SizedBox(height: 24),
                        _shoppingHeader(),
                        const SizedBox(height: 8),
                        ..._shopping.map(_shoppingTile),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }


  Widget _planTable() {
    final days = List.generate(7, (i){ final d = _anchor.subtract(Duration(days: _anchor.weekday - 1 - i)); return DateTime(d.year,d.month,d.day);});
    _plan.sort((a,b)=> a.date.compareTo(b.date));
    return Card(
      child: Table(
        columnWidths: const {0: FixedColumnWidth(90)},
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(children: [
            const Padding(padding: EdgeInsets.all(8), child: Text('Day', style: TextStyle(fontWeight: FontWeight.bold))),
            if (_breakfasts>0) const Padding(padding: EdgeInsets.all(8), child: Text('Breakfast', style: TextStyle(fontWeight: FontWeight.bold))),
            if (_lunches>0) const Padding(padding: EdgeInsets.all(8), child: Text('Lunch', style: TextStyle(fontWeight: FontWeight.bold))),
            const Padding(padding: EdgeInsets.all(8), child: Text('Dinner', style: TextStyle(fontWeight: FontWeight.bold))),
            const Padding(padding: EdgeInsets.all(8), child: Text('Cooked', style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(),
          ]),
          for (final day in days) _rowFor(day),
        ],
      ),
    );
  }

  TableRow _rowFor(DateTime day) {
    PlanEntry lookup(MealType m) => _plan.firstWhere(
      (e) => e.date.year==day.year && e.date.month==day.month && e.date.day==day.day && e.mealType==m,
      orElse: () => PlanEntry(date: day, mealType: m, recipeId: ''),
    );
    final dinner = lookup(MealType.dinner);
    final breakfast = _breakfasts>0 ? lookup(MealType.breakfast) : null;
    final lunch = _lunches>0 ? lookup(MealType.lunch) : null;
    final cookedEntry = dinner.recipeId.isNotEmpty ? dinner : (lunch?.recipeId.isNotEmpty == true ? lunch! : (breakfast?.recipeId.isNotEmpty == true ? breakfast! : dinner));
    return TableRow(children: [
      Padding(padding: const EdgeInsets.all(8), child: Text(_weekdayLabel(day.weekday))),
  if (_breakfasts>0) Padding(padding: const EdgeInsets.all(8), child: _mealCell(breakfast!)),
  if (_lunches>0) Padding(padding: const EdgeInsets.all(8), child: _mealCell(lunch!)),
  Padding(padding: const EdgeInsets.all(8), child: _mealCell(dinner)),
      Center(
        child: cookedEntry.recipeId.isEmpty ? const SizedBox() : Checkbox(
          value: cookedEntry.cooked,
          onChanged: (v) async {
            if (cookedEntry.recipeId.isEmpty) return;
            await WeeklyPlannerService.setCooked(cookedEntry, SupabaseService.currentUser?.id ?? 'anon', v ?? false);
            final idx = _plan.indexWhere((p)=> p.date==cookedEntry.date && p.mealType==cookedEntry.mealType);
            if (idx != -1) {
              setState(()=> _plan[idx] = _plan[idx].copyWith(cooked: v ?? false));
              _pendingQueue.add(_plan[idx]);
              _scheduleAutosync();
            }
          },
        ),
      ),
      Row(children: [
        if (_breakfasts>0) IconButton(onPressed: () => _shuffleSpecific(day, MealType.breakfast), icon: const Icon(Icons.shuffle, size: 20), tooltip: 'Shuffle breakfast'),
        if (_lunches>0) IconButton(onPressed: () => _shuffleSpecific(day, MealType.lunch), icon: const Icon(Icons.shuffle, size: 20), tooltip: 'Shuffle lunch'),
        IconButton(onPressed: () => _shuffleSpecific(day, MealType.dinner), icon: const Icon(Icons.shuffle, size: 20), tooltip: 'Shuffle dinner'),
        if (dinner.recipeId.isNotEmpty)
          IconButton(
            onPressed: () => _openSwapModal(dinner),
            icon: const Icon(Icons.swap_horiz, size: 20),
            tooltip: 'Swap dinner',
          ),
      ]),
    ]);
  }

  Widget _mealCell(PlanEntry e) {
    if (e.recipeId.isEmpty) return const Text('—');
    final name = _recipeName(e.recipeId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        Row(children:[
          Text('${e.servings ?? ''} serv', style: const TextStyle(fontSize: 11, color: Colors.black54)),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            icon: const Icon(Icons.edit, size: 14),
            tooltip: 'Edit servings',
            onPressed: () => _editServings(e),
          ),
        ])
      ],
    );
  }

  void _editServings(PlanEntry entry) {
    final ctrl = TextEditingController(text: (entry.servings ?? '').toString());
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Set Servings'),
      content: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Servings'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          final v = int.tryParse(ctrl.text.trim());
          if (v!=null && v>0) {
            final idx = _plan.indexWhere((p)=> p.date==entry.date && p.mealType==entry.mealType);
            if (idx!=-1) {
              setState(()=> _plan[idx] = _plan[idx].copyWith(servings: v));
              await WeeklyPlannerService.saveEntry(_plan[idx]);
              await _refreshShopping();
              _pendingQueue.add(_plan[idx]);
              _scheduleAutosync();
            }
          }
          if (context.mounted) Navigator.pop(context);
        }, child: const Text('Save')),
      ],
    ));
  }

  Future<void> _openSwapModal(PlanEntry entry) async {
    final userId = SupabaseService.currentUser?.id ?? 'anon';
    final alternatives = await WeeklyPlannerService.suggestAlternatives(entry: entry, userId: userId);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Swap Dinner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (alternatives.isEmpty) const Text('No alternatives found.'),
              ...alternatives.map((r) => ListTile(
                title: Text(r.name),
                subtitle: Text('${r.cuisine ?? ''} ${(r.cookingTimeMinutes ?? 0)}m'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  // Compute diff preview
                  final diff = await WeeklyPlannerService.simulateSwapDiff(entry: entry, newRecipeId: r.id, currentPlan: _plan, recipes: _recipes);
                  if (!mounted) return;
                  await showDialog(context: context, builder: (_) => AlertDialog(
                    title: const Text('Confirm Swap'),
                    content: SizedBox(
                      width: 340,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Replace with: ${r.name}'),
                            const SizedBox(height: 12),
                            _diffSection('Added', (diff['added'] as Set<String>).toList()),
                            _diffSection('Removed', (diff['removed'] as Set<String>).toList()),
                            _qtyChangesSection(diff['changed'] as List<Map<String,dynamic>>),
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Cancel')),
                      ElevatedButton(onPressed: () async {
                        Navigator.pop(context); // close dialog
                        final updated = await WeeklyPlannerService.swapEntry(entry: entry, newRecipeId: r.id, userId: userId, meta: {'added': (diff['added'] as Set<String>).length, 'removed': (diff['removed'] as Set<String>).length});
                        if (updated != null) {
                          final idx = _plan.indexWhere((p)=> p.date==entry.date && p.mealType==entry.mealType);
                          if (idx!=-1) {
                            setState(()=> _plan[idx] = updated);
                            _swapHistory.add({'old': entry, 'new': updated});
                            await _refreshShopping();
                          }
                        }
                        if (context.mounted) Navigator.pop(context); // close bottom sheet
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Dinner swapped'), action: SnackBarAction(label: 'UNDO', onPressed: _undoLastSwap)));
                      }, child: const Text('Swap')),
                    ],
                  ));
                },
              )),
              const SizedBox(height: 8),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _diffSection(String label, List<String> items) {
    if (items.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Wrap(spacing: 6, runSpacing: 4, children: items.take(20).map((e)=> Chip(label: Text(e, style: const TextStyle(fontSize: 11)))).toList()),
      ]),
    );
  }

  Widget _qtyChangesSection(List<Map<String,dynamic>> changes) {
    if (changes.isEmpty) return const SizedBox();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      const Text('Quantity Changes', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      ...changes.take(20).map((c) => Text("${c['ingredient']}: ${c['from'].toStringAsFixed(2)} → ${c['to'].toStringAsFixed(2)}", style: const TextStyle(fontSize: 12))),
    ]);
  }

  void _undoLastSwap() async {
    if (_swapHistory.isEmpty) return;
    final last = _swapHistory.removeLast();
    final oldEntry = last['old']!;
    final idx = _plan.indexWhere((p)=> p.date==oldEntry.date && p.mealType==oldEntry.mealType);
    if (idx!=-1) {
      setState(()=> _plan[idx] = oldEntry);
      await WeeklyPlannerService.saveEntry(oldEntry);
      await _refreshShopping();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Swap undone')));
      }
    }
  }

  Widget _mealCountSelector(String label, int value, ValueChanged<int> onChanged) {
    return Row(children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      SizedBox(
        width: 40,
        child: TextField(
          decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical:4,horizontal:6), border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
          controller: TextEditingController(text: value.toString()),
          onSubmitted: (s){ final v = int.tryParse(s)??0; onChanged(v.clamp(0,7)); },
        ),
      ),
    ]);
  }

  String _recipeName(String id) => _recipes.firstWhere((r) => r.id == id, orElse: () => Recipe(id: id, name: 'Recipe', createdAt: DateTime.now())).name;

  String _weekdayLabel(int wd) => const ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][wd-1];

  Widget _shoppingHeader() => Row(
    children: [
      const Text('Shopping List (Pantry Gaps)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const Spacer(),
      IconButton(onPressed: _refreshShopping, icon: const Icon(Icons.refresh)),
    ],
  );

  Widget _shoppingTile(ShoppingListItem item) {
    final acquired = _acquired.contains(item.ingredient);
    return ListTile(
      leading: GestureDetector(
        onTap: () {
          setState(() {
            if (acquired) {
              _acquired.remove(item.ingredient);
            } else {
              _acquired.add(item.ingredient);
            }
          });
      _persistAcquired();
        },
        child: CircleAvatar(
          radius: 16,
          backgroundColor: acquired ? Colors.green : Colors.grey.shade300,
          child: Text(
            item.summedQuantity != null
                ? (item.summedQuantity! >= 10 ? item.summedQuantity!.round().toString() : item.summedQuantity!.toStringAsFixed(1))
                : item.count.toString(),
            style: TextStyle(fontSize: 12, color: acquired ? Colors.white : Colors.black87),
          ),
        ),
      ),
      title: Text(
        item.ingredient,
        style: TextStyle(
          decoration: acquired ? TextDecoration.lineThrough : null,
          color: acquired ? Colors.grey : null,
        ),
      ),
  subtitle: Text('Used in ${item.recipeIds.length} recipe${item.recipeIds.length==1?'':'s'}${item.summedQuantity!=null ? ' · ~${item.summedQuantity!.toStringAsFixed(2)} qty' : ''}${item.examples.isNotEmpty ? ' · e.g. ${item.examples.take(2).join(', ')}' : ''}'),
      trailing: IconButton(
        icon: const Icon(Icons.info_outline, size: 20),
        onPressed: () => _showIngredientUsage(item),
        tooltip: 'Show recipes',
      ),
      onTap: () => _showIngredientUsage(item),
    );
  }

  void _showIngredientUsage(ShoppingListItem item) {
    final recipeNames = item.recipeIds.map((id)=> _recipeName(id)).toList();
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.ingredient, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (item.examples.isNotEmpty) ...[
              Wrap(spacing: 8, runSpacing: 4, children: [
                for (final ex in item.examples.take(6)) Chip(label: Text(ex))
              ]),
              const SizedBox(height: 12),
            ],
            ...recipeNames.map((n) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children:[const Icon(Icons.restaurant_menu, size:16), const SizedBox(width:8), Expanded(child: Text(n))]),
                )),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            )
          ],
        ),
      ),
    );
  }

  String _acquiredStorageKey() {
    final monday = _anchor.subtract(Duration(days: _anchor.weekday - 1));
    return '$_acquiredKeyPrefix${monday.year}-${monday.month}-${monday.day}';
  }

  Future<void> _persistAcquired() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_acquiredStorageKey(), _acquired.toList());
  }

  // Schedules a debounced autosync of pending queue; will also pull remote occasionally.
  void _scheduleAutosync() {
    _debounce?.cancel();
    _debounce = Timer(_autosyncDebounce, () async {
      await _flushPending();
    });
  _persistPendingQueue();
  }

  // Flush pending edits to remote. If pushOnly=true, skip remote pull/merge.
  Future<void> _flushPending({bool pushOnly = false}) async {
    if (!mounted) return;
    if (_syncInFlight) return; // avoid overlap
  if (!_online) { _scheduleRetryBackoff(); return; }
    if (_pendingQueue.isEmpty) {
      if (pushOnly) return; // nothing to do
      // Optionally perform a silent pull if stale
      if (_lastSync == null || DateTime.now().difference(_lastSync!) > _maxSilentPullAge) {
        _syncInFlight = true;
        try {
          await _syncNow();
        } finally {
          _syncInFlight = false;
        }
      }
      return;
    }
    _syncInFlight = true;
    try {
      // Deduplicate pending by (date, mealType)
      final Map<String, PlanEntry> latest = {};
      for (final e in _pendingQueue) {
        final key = '${e.date.year}-${e.date.month}-${e.date.day}-${e.mealType.name}';
        latest[key] = e;
      }
      final edits = latest.values.toList();
      // Fire push (await to know success)
      final ok = await SyncService.pushPlanEntriesSafe(edits, SupabaseService.currentUser?.id ?? 'anon');
      if (!ok) {
        _consecutiveFailures++;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync failed – retrying (attempt $_consecutiveFailures)')));
        }
        _scheduleRetryBackoff();
        return; // keep queue for retry
      } else {
        _consecutiveFailures = 0;
      }
      _pendingQueue.clear();
  _persistPendingQueue();
      _lastSync = DateTime.now();
      if (!pushOnly) {
        // Optionally pull remote if stale
        if (_lastSync == null || DateTime.now().difference(_lastSync!) > _autosyncDebounce) {
          final remote = await SyncService.pullPlan(SupabaseService.currentUser?.id ?? 'anon');
          if (remote.isNotEmpty) {
            final merged = SyncService.mergePlan(local: _plan, remote: remote);
            bool changed = merged.length != _plan.length;
            if (!changed) {
              for (int i=0;i<merged.length;i++) {
                final a = merged[i]; final b = _plan[i];
                if (a.recipeId!=b.recipeId || a.cooked!=b.cooked || a.servings!=b.servings) { changed = true; break; }
              }
            }
            if (changed) {
              for (final e in merged) { await WeeklyPlannerService.saveEntry(e); }
              final shopping = await WeeklyPlannerService.buildShoppingList(merged, _recipes);
              if (mounted) setState(() { _plan = merged; _shopping = shopping; });
            }
          }
        }
      }
    } catch (_) {
      // Leave queue intact for retry.
    } finally {
      _syncInFlight = false;
    }
    if (mounted) setState((){}); // update sync indicator
  }

  void _scheduleRetryBackoff() {
    _backoffTimer?.cancel();
    final delaySeconds = _consecutiveFailures==0 ? 2 : (1 << (_consecutiveFailures-1)).clamp(2, 64);
    _backoffTimer = Timer(Duration(seconds: delaySeconds), () {
      if (mounted) _flushPending();
    });
  }

  Future<void> _persistPendingQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _pendingQueue.map((e)=> e.toJson()).toList();
      prefs.setString(_pendingQueueKey, list.toString());
    } catch(_){/* ignore */}
  }

  Future<void> _restorePendingQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_pendingQueueKey);
      if (raw == null || raw.isEmpty) return;
      // crude parse: expect list of map-like strings; reuse WeeklyPlannerService parser approach
      final items = raw.substring(1, raw.length-1).split('},');
      for (var part in items) {
        if (!part.trim().endsWith('}')) part = '$part}';
        final cleaned = part.replaceAll(RegExp(r'^{|}$'), '');
        final map = <String,dynamic>{};
        for (final seg in cleaned.split(',')) {
          final i = seg.indexOf(':');
          if (i==-1) continue;
          final k = seg.substring(0,i).trim().replaceAll("'", '').replaceAll('"','');
          final v = seg.substring(i+1).trim().replaceAll("'", '');
          map[k]= v;
        }
        try { _pendingQueue.add(PlanEntry.fromJson(map)); } catch(_){}
      }
      if (_pendingQueue.isNotEmpty) _scheduleAutosync();
    } catch(_){/* ignore */}
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _backoffTimer?.cancel();
    _debounce?.cancel();
    super.dispose();
  }
}
