import 'package:flutter/material.dart';
import 'package:nibble_ai/services/recipe_service.dart';
import 'package:nibble_ai/services/suggestion_engine.dart';
import 'package:nibble_ai/services/user_profile_service.dart';
import 'package:nibble_ai/services/recipe_event_service.dart';
import 'package:nibble_ai/services/weekly_planner_service.dart';
import 'package:nibble_ai/models/weekly_plan.dart';
import 'package:nibble_ai/models/recipe_enums.dart';
import 'package:nibble_ai/services/pantry_service.dart';
import 'package:nibble_ai/services/adaptive_weight_service.dart';
import 'meal_planner_screen.dart';

/// Planning Swipe Screen (MVP) — dinners only.
/// Swipe right = plan_add (assign to next unfilled dinner slot this week).
/// Swipe left = skip (logged as dislike if double-tapped reject in future; for now skip).
class PlanningSwipeScreen extends StatefulWidget {
  final DateTime? anchorMonday; // if provided, use this week instead of current
  const PlanningSwipeScreen({super.key, this.anchorMonday});

  @override
  State<PlanningSwipeScreen> createState() => _PlanningSwipeScreenState();
}

class _PlanningSwipeScreenState extends State<PlanningSwipeScreen> with SingleTickerProviderStateMixin {
  final List<ScoredRecipe> _stack = [];
  int _index = 0;
  bool _loading = true;
  Offset _drag = Offset.zero;
  late AnimationController _rebound;
  Animation<Offset>? _reboundAnim;
  late DateTime _monday;
  final Set<String> _plannedIds = {};
  int _nextSlot = 0; // 0..6 for dinners Mon..Sun

  @override
  void initState() {
    super.initState();
    _rebound = AnimationController(vsync: this, duration: const Duration(milliseconds: 200))..addListener(()=> setState(()=> _drag = _reboundAnim?.value ?? _drag));
    _init();
  }

  Future<void> _init() async {
    final now = DateTime.now();
    _monday = widget.anchorMonday ?? now.subtract(Duration(days: now.weekday - 1));
    await WeeklyPlannerService.init();
    final existing = WeeklyPlannerService.loadWeek(_monday).where((e)=> e.mealType==MealType.dinner).toList();
    existing.sort((a,b)=> a.date.compareTo(b.date));
    for (final e in existing) { _plannedIds.add(e.recipeId); _nextSlot++; }
    await _load();
  }

  Future<void> _load() async {
    setState(()=> _loading = true);
    const userId = 'demo-user';
    final profile = await UserProfileService.getOrCreate(userId);
    final recipes = await RecipeService.fetchAll();
    final pantry = await PantryService.fetchItems();
    final ctx = SuggestionContext(timeAvailableMinutes: 45, desiredServings: profile.baseHouseholdSize, pantryItems: pantry.map((p)=>p.name).toSet());
    var weights = const SuggestionEngineWeights();
    try { weights = await AdaptiveWeightService.load(userId);} catch(_){}
    final ranked = SuggestionEngine.rank(pool: recipes, profile: profile, ctx: ctx, weights: weights)
      .where((sr)=> !_plannedIds.contains(sr.recipe.id))
      .toList();
    setState(() {
      _stack
        ..clear()
        ..addAll(ranked.take(30));
      _index = 0;
      _loading = false;
      _drag = Offset.zero;
    });
  }

  Future<void> _swipe(bool like) async {
    if (_index >= _stack.length) return;
    final sr = _stack[_index];
    if (like) {
      // Assign to next dinner slot if available
      if (_nextSlot < 7) {
        final date = _monday.add(Duration(days: _nextSlot));
        final entry = PlanEntry(date: date, mealType: MealType.dinner, recipeId: sr.recipe.id, servings: null);
        await WeeklyPlannerService.saveEntry(entry);
        await RecipeEventService.log(RecipeEvent(recipeId: sr.recipe.id, userId: 'demo-user', type: 'plan_add', meta: {'slot': _nextSlot}));
        _plannedIds.add(sr.recipe.id);
        _nextSlot++;
      } else {
        // All slots filled: treat as extra like (still plan_add)
        await RecipeEventService.log(RecipeEvent(recipeId: sr.recipe.id, userId: 'demo-user', type: 'plan_add', meta: {'slot': 'overflow'}));
      }
    } else {
      await RecipeEventService.log(RecipeEvent(recipeId: sr.recipe.id, userId: 'demo-user', type: 'skip', meta: {'planning': true}));
    }
    setState(() { _index++; _drag = Offset.zero; });
  }

  void _onDragUpdate(DragUpdateDetails d) { setState(()=> _drag += d.delta); }
  void _onDragEnd(DragEndDetails d) {
    const threshold = 120.0;
    if (_drag.dx.abs() > threshold) {
      _swipe(_drag.dx > 0);
    } else {
      _reboundAnim = Tween(begin: _drag, end: Offset.zero).animate(CurvedAnimation(parent: _rebound, curve: Curves.easeOut));
      _rebound.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filled = _nextSlot.clamp(0,7);
    return Scaffold(
      appBar: AppBar(title: const Text('Plan Dinners')),
      body: SafeArea(
        child: _loading 
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(builder: (ctx, constraints){
                final content = Column(
                  children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16,12,16,4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Week ${_monday.month}/${_monday.day}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('$filled / 7 planned', style: const TextStyle(fontSize: 12)),
                        TextButton(onPressed: _load, child: const Text('Refresh')),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _index >= _stack.length ? _empty() : Stack(
                      alignment: Alignment.center,
                      children: () {
                        const maxVisible = 4;
                        final remaining = _stack.length - _index;
                        final count = remaining > maxVisible ? maxVisible : remaining;
                        final cards = <Widget>[];
                        for (int depth = count -1; depth >=0; depth--) {
                          final sr = _stack[_index + depth];
                          cards.add(_card(sr, depth));
                        }
                        // Progress badge
                        cards.add(Positioned(top: 8, right: 8, child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(12)),
                          child: Text('Slots: $filled/7', style: const TextStyle(fontSize: 11, color: Colors.white)),
                        )));
                        return cards;
                      }(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24,8,24,8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _circleBtn(Icons.close, Colors.red, ()=> _swipe(false)),
                        _circleBtn(Icons.check, Colors.green, ()=> _swipe(true)),
                      ],
                    ),
                  ),
                  if (filled >=7)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ElevatedButton(onPressed: () async {
                        if (!mounted) return; 
                        await Navigator.push(context, MaterialPageRoute(builder: (_)=> const MealPlannerScreen()));
                      }, child: const Text('View Plan')),
                    ),
                  ],
                );
                if (constraints.maxHeight < 620) {
                  return SingleChildScrollView(child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(child: content),
                  ));
                }
                return content;
              }),
      ),
    );
  }

  Widget _empty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children:[
    const Text('No more suggestions'),
    const SizedBox(height: 8),
    ElevatedButton(onPressed: _load, child: const Text('Reload'))
  ]));

  Widget _card(ScoredRecipe sr, int depth) {
    final offset = depth * 10.0;
    final isTop = depth == 0;
    final drag = isTop ? _drag : Offset.zero;
    final rotation = isTop ? (drag.dx / 300) * 0.2 : 0.0;
    return Positioned(
      top: offset, left: offset, right: offset, bottom: offset,
      child: IgnorePointer(
        ignoring: !isTop,
        child: Transform.translate(
          offset: drag,
          child: Transform.rotate(
            angle: rotation,
            child: GestureDetector(
              onPanUpdate: _onDragUpdate,
              onPanEnd: _onDragEnd,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(sr.recipe.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 4, children: sr.reasons.take(6).map((r)=> _chip(r)).toList()),
                    const SizedBox(height: 12),
                    Text('Score: ${sr.score.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const Spacer(),
                    Row(children:[
                      if (sr.recipe.cookingTimeMinutes != null) _info(Icons.access_time, '${sr.recipe.cookingTimeMinutes}m'),
                      if (sr.recipe.mealType != null) ...[
                        const SizedBox(width: 12), _info(Icons.restaurant, sr.recipe.mealType!.name)
                      ]
                    ])
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blueGrey.shade100)),
    child: Text(text, style: const TextStyle(fontSize: 11)),
  );

  Widget _info(IconData icon, String text) => Row(children:[Icon(icon, size: 14, color: Colors.grey.shade700), const SizedBox(width:4), Text(text, style: TextStyle(fontSize:12, color: Colors.grey.shade700))]);
  Widget _circleBtn(IconData icon, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(width:64,height:64, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.15)), child: Icon(icon, color: color, size: 30)),
  );
}
