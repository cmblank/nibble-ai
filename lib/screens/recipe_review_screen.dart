import 'package:flutter/material.dart';
import 'package:nibble_ai/services/recipe_service.dart';
import 'package:nibble_ai/services/suggestion_engine.dart';
import 'package:nibble_ai/services/user_profile_service.dart';
import 'package:nibble_ai/services/recipe_event_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nibble_ai/services/pantry_service.dart';

/// Tinder/Stitch-Fix style review of recipe suggestions.
class RecipeReviewScreen extends StatefulWidget {
  const RecipeReviewScreen({super.key});

  @override
  State<RecipeReviewScreen> createState() => _RecipeReviewScreenState();
}

class _RecipeReviewScreenState extends State<RecipeReviewScreen> with SingleTickerProviderStateMixin {
  // Current batch of recipes displayed as swipe stack.
  final List<ScoredRecipe> _stack = [];
  // Remaining ranked recipes not yet shown (to avoid repeats when loading more).
  final List<ScoredRecipe> _remaining = [];
  static const int _batchSize = 10;
  bool _loading = true;
  int _index = 0; // points to current top card
  int _timeAvailable = 40;
  int _desiredServings = 2;
  bool _quickMode = false;
  Offset _dragOffset = Offset.zero;
  late AnimationController _reboundCtrl;
  Animation<Offset>? _reboundAnim;

  @override
  void initState() {
    super.initState();
    _reboundCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220))
      ..addListener(() {
        if (_reboundAnim != null) setState(() => _dragOffset = _reboundAnim!.value);
      });
    _restoreAndLoad();
  }

  Future<void> _restoreAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _timeAvailable = prefs.getInt('rev_time') ?? _timeAvailable;
      _desiredServings = prefs.getInt('rev_servings') ?? _desiredServings;
      _quickMode = prefs.getBool('rev_quick') ?? _quickMode;
    });
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    const userId = 'demo-user';
    final profile = await UserProfileService.getOrCreate(userId);
    final recipes = await RecipeService.fetchAll();
  final pantryItems = await PantryService.fetchItems();
  final pantryNames = pantryItems.map((p) => p.name).toSet();
  final ctx = SuggestionContext(timeAvailableMinutes: _timeAvailable, desiredServings: _desiredServings, quickMode: _quickMode, pantryItems: pantryNames);
    final ranked = SuggestionEngine.rank(pool: recipes, profile: profile, ctx: ctx);
    setState(() {
      _stack.clear();
      _remaining.clear();
      _stack.addAll(ranked.take(_batchSize));
      _remaining.addAll(ranked.skip(_batchSize));
      _index = 0; // always top of current batch
      _loading = false;
      _dragOffset = Offset.zero;
    });
  }

  /// Load next batch of recipes (if any) keeping previously swiped ones excluded.
  void _loadMore() {
    if (_remaining.isEmpty) return;
    setState(() {
      _stack
        ..clear()
        ..addAll(_remaining.take(_batchSize));
      _remaining.removeRange(0, _remaining.length < _batchSize ? _remaining.length : _batchSize);
      _index = 0;
      _dragOffset = Offset.zero;
    });
  }

  Future<void> _swipe(bool like) async {
    if (_index >= _stack.length) return;
    final current = _stack[_index];
    await RecipeEventService.log(RecipeEvent(recipeId: current.recipe.id, userId: 'demo-user', type: like ? 'cook_soon' : 'skip', meta: {'score': current.score}));
    setState(() {
      _index++;
      _dragOffset = Offset.zero;
    });
  }

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() => _dragOffset += d.delta);
  }

  void _onDragEnd(DragEndDetails d) {
    final dx = _dragOffset.dx;
    const threshold = 120.0;
    if (dx.abs() > threshold) {
      _swipe(dx > 0);
    } else {
      _reboundAnim = Tween(begin: _dragOffset, end: Offset.zero).animate(CurvedAnimation(parent: _reboundCtrl, curve: Curves.easeOut));
      _reboundCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipe Review')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
      : (_index >= _stack.length)
              ? _emptyState(hasMore: _remaining.isNotEmpty)
              : Column(children: [
                  _controlsBar(),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: () {
                        const maxVisible = 4; // top + 3 previews
                        final remaining = _stack.length - _index;
                        final count = remaining > maxVisible ? maxVisible : remaining;
                        final cards = <Widget>[];
                        // Paint deeper cards first so depth 0 (current) is on top.
                        for (int depth = count - 1; depth >= 0; depth--) {
                          final sr = _stack[_index + depth];
                          cards.add(_buildCard(sr, depth));
                        }
                        // Debug overlay (tap to hide/show?) simple always-on small badge
                        final events = RecipeEventService.all();
                        final positives = events.where((e)=> e.type=='cook_soon' || e.type=='fav').length;
                        final negatives = events.where((e)=> e.type=='skip' || e.type=='dislike').length;
                        cards.add(Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(12)),
                            child: Text('👍 $positives  👎 $negatives', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                        ));
                        return cards;
                      }(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _circleBtn(Icons.close, Colors.red, () => _swipe(false)),
                        _circleBtn(Icons.favorite, Colors.green, () => _swipe(true)),
                      ],
                    ),
                  )
                ]),
    );
  }

  Widget _controlsBar() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Time (min)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              Slider(
                min: 10,
                max: 120,
                divisions: 11,
                label: _timeAvailable.toString(),
                value: _timeAvailable.toDouble(),
                onChanged: (v) async {
                  final val = v.round();
                  setState(() => _timeAvailable = val);
                  final prefs = await SharedPreferences.getInstance();
                  prefs.setInt('rev_time', val);
                },
              )
            ]),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Servings', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            Row(mainAxisSize: MainAxisSize.min, children: [
              _incBtn('-', () async {
                if (_desiredServings > 1) {
                  setState(() => _desiredServings--);
                  final prefs = await SharedPreferences.getInstance();
                  prefs.setInt('rev_servings', _desiredServings);
                }
              }),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text(_desiredServings.toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
              _incBtn('+', () async {
                setState(() => _desiredServings++);
                final prefs = await SharedPreferences.getInstance();
                prefs.setInt('rev_servings', _desiredServings);
              }),
            ]),
            Row(children: [
              Checkbox(value: _quickMode, onChanged: (v) async {
                setState(() => _quickMode = v ?? false);
                final prefs = await SharedPreferences.getInstance();
                prefs.setBool('rev_quick', _quickMode);
              }),
              const Text('Quick', style: TextStyle(fontSize: 12)),
            ])
          ]),
          const SizedBox(width: 12),
          ElevatedButton(onPressed: _load, child: const Text('Refresh'))
        ]),
      );

  Widget _incBtn(String t, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
            alignment: Alignment.center,
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(6)),
          child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      );

  Widget _emptyState({required bool hasMore}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(hasMore ? 'Great swiping!' : 'All caught up', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(hasMore ? 'Load a fresh batch of new suggestions.' : 'Adjust filters or refresh for more.'),
            const SizedBox(height: 16),
            hasMore
                ? ElevatedButton(onPressed: _loadMore, child: const Text('Load More'))
                : ElevatedButton(onPressed: _load, child: const Text('Reload Suggestions')),
          ]),
        ),
      );

  Widget _buildCard(ScoredRecipe sr, int depth) {
    final offset = depth * 10.0;
    final isTop = depth == 0;
    final drag = isTop ? _dragOffset : Offset.zero;
    final rotation = isTop ? (drag.dx / 300) * 0.2 : 0.0;
    return Positioned(
      top: offset,
      left: offset,
      right: offset,
      bottom: offset,
      child: IgnorePointer(
        ignoring: !isTop,
        child: Transform.translate(
          offset: drag,
          child: Transform.rotate(
            angle: rotation,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.95, end: isTop ? 1 : 0.95),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) => Transform.scale(scale: 1 - (depth * 0.02), child: child),
              child: GestureDetector(
                onPanUpdate: _onDragUpdate,
                onPanEnd: _onDragEnd,
                child: Stack(children: [
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(sr.recipe.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 6, runSpacing: 4, children: sr.reasons.map((r) => _reasonChip(r)).toList()),
                        const SizedBox(height: 12),
                        Text('Score: ${sr.score.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const Spacer(),
                        Row(children: [
                          if (sr.recipe.cookingTimeMinutes != null)
                            _infoIcon(Icons.access_time, '${sr.recipe.cookingTimeMinutes}m'),
                          if (sr.recipe.mealType != null) ...[
                            const SizedBox(width: 12),
                            _infoIcon(Icons.restaurant, sr.recipe.mealType!.name),
                          ],
                        ]),
                      ]),
                    ),
                  ),
                  if (isTop && drag.dx.abs() > 30)
                    Positioned(
                      top: 16,
                      left: drag.dx > 0 ? 16 : null,
                      right: drag.dx < 0 ? 16 : null,
                      child: Opacity(
                        opacity: (drag.dx.abs() / 120).clamp(0, 1),
                        child: drag.dx > 0 ? _decisionLabel('COOK', Colors.green) : _decisionLabel('PASS', Colors.red),
                      ),
                    ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _decisionLabel(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.1),
        ),
        child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 1)),
      );

  Widget _reasonChip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.blueGrey.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.blueGrey.shade100),
    ),
    child: Text(label, style: const TextStyle(fontSize: 11)),
  );

  Widget _infoIcon(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: Colors.grey.shade700),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
    ],
  );

  Widget _circleBtn(IconData icon, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.15),
      ),
      child: Icon(icon, color: color, size: 30),
    ),
  );
}
