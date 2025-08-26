import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';

// Rounded underline indicator to match design
class RoundedUnderlineTabIndicator extends Decoration {
  final Color color;
  final double thickness;
  final double radius;
  const RoundedUnderlineTabIndicator({
    required this.color,
    this.thickness = 4,
    this.radius = 4,
  });
  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _RoundedUnderlinePainter(this);
}

class _RoundedUnderlinePainter extends BoxPainter {
  final RoundedUnderlineTabIndicator d;
  _RoundedUnderlinePainter(this.d);
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null) return;
    final rect = offset & size;
    final rrect = RRect.fromRectAndCorners(
      Rect.fromLTWH(rect.left, rect.bottom - d.thickness, rect.width, d.thickness),
      topLeft: Radius.circular(d.radius),
      topRight: Radius.circular(d.radius),
    );
    final paint = Paint()..color = d.color..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, paint);
  }
}

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});
  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> with TickerProviderStateMixin {
  late final TabController _tabs;
  bool _loading = true;
  String? _error;
  // Mutable lists (avoid const so incremental mutation is safe before full reload)
  List<Map<String, dynamic>> _completed = [];
  List<Map<String, dynamic>> _inProgress = [];
  bool _expandCurrentMonth = true;
  bool _expandOngoing = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _fetch();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F6), // gray-200
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _buildInProgressTab(),
                  _buildCompletedTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(width: 1, color: Color(0xFFE8EAED))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Your Achievements',
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    height: 1.36,
                    color: Colors.black,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 23),
          Center(
            child: TabBar(
              controller: _tabs,
              isScrollable: true,
              labelPadding: const EdgeInsets.symmetric(horizontal: 19), // 38px gap
              indicator: const RoundedUnderlineTabIndicator(
                color: Color(0xFF2A8469), // sage-1100
                thickness: 4,
                radius: 4,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: const Color(0xFF2A8469),
              unselectedLabelColor: const Color(0xFF596573),
              labelStyle: const TextStyle(fontSize: 16, fontFamily: 'Manrope', fontWeight: FontWeight.w700, height: 1.38),
              unselectedLabelStyle: const TextStyle(fontSize: 16, fontFamily: 'Manrope', fontWeight: FontWeight.w500, height: 1.38),
              tabs: const [Tab(text: 'In Progress'), Tab(text: 'Completed')],
            ),
          ),
        ],
      ),
    );
  }

  // In Progress
  Widget _buildInProgressTab() {
    if (_loading) {
      return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: const TextStyle(color: Colors.redAccent))));
    }

    return RefreshIndicator(
      onRefresh: _fetch,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCookingStreak(),
            const SizedBox(height: 20),
            _buildSectionHeader(
              title: '${DateFormat('MMMM').format(DateTime.now())} Challenges',
              subtitle: 'Habits grow over time',
              expanded: _expandCurrentMonth,
              onToggle: () => setState(() => _expandCurrentMonth = !_expandCurrentMonth),
            ),
            const SizedBox(height: 8),
            if (_expandCurrentMonth) _buildChallengesList(_currentMonthChallenges()),
            const SizedBox(height: 20),
            _buildSectionHeader(
              title: 'Ongoing',
              subtitle: 'Habits grow over time',
              expanded: _expandOngoing,
              onToggle: () => setState(() => _expandOngoing = !_expandOngoing),
            ),
            const SizedBox(height: 8),
            if (_expandOngoing) _buildChallengesList(_ongoingChallenges()),
          ],
        ),
      ),
    );
  }

  // Completed
  Widget _buildCompletedTab() {
    if (_loading) {
      return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: const TextStyle(color: Colors.redAccent))));
    }
    if (_completed.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No achievements completed yet.')));
    }

    final palette = _palette();
    return RefreshIndicator(
      onRefresh: _fetch,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = width > 480 ? 3 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _completed.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, i) {
                final r = _completed[i];
                final (bg, fg) = palette[i % palette.length];
                return _CompletedCard(
                  iconUrl: r['icon_url'] as String?,
                  period: _completionTag(r),
                  title: r['name']?.toString() ?? 'Achievement',
                  subtitle: r['description']?.toString() ?? '',
                  accentBg: bg,
                  accentFg: fg,
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Cooking streak card
  Widget _buildCookingStreak() {
    const cookingDays = [true, true, false, true, true, false, false];

    const sageFill = Color(0xFF2A8469);
    const sageRing = Color(0xFF37AE8B);
    const sagePillBg = Color(0xFFF0FAF7);
    const sagePillText = Color(0xFF319B7B);
    const gray300 = Color(0xFFE8EAED);
    const textDark = Color(0xFF1D2126);
    const textMedium = Color(0xFF353C45);
    const textLight = Color(0xFF596573);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: gray300),
          borderRadius: BorderRadius.circular(12),
        ),
        shadows: const [BoxShadow(color: Color(0x0C000000), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Image.asset('assets/images/flame.png', fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Text('🔥', style: TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Cooking Streak', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textDark, height: 1.33)),
              Text("You've cooked 4x this week! 🍳", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textMedium, height: 1.33)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: ShapeDecoration(color: sagePillBg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
            child: const Text('2 days left', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sagePillText, height: 1.33)),
          ),
        ]),
        const SizedBox(height: 16),
        const Text('This Week', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textMedium, height: 1.43)),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          // Target 7 dots + minimal spacing; adapt down to avoid overflow
          final dot = (maxW / 9).clamp(24.0, 32.0);
          final radius = dot / 2;
          final checkSize = (dot * 0.5).clamp(12.0, 18.0);
          final dotlet = (dot * 0.25).clamp(6.0, 10.0);
          final labelSize = (dot * 0.375).clamp(10.0, 12.0);
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
              final isCompleted = cookingDays[index];
              final isToday = index == 5; // demo
              return Column(children: [
                Text(
                  days[index],
                  style: TextStyle(
                    fontSize: labelSize,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                    color: isToday ? textDark : textLight,
                    height: 1.33,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  width: dot,
                  height: dot,
                  decoration: BoxDecoration(
                    color: isCompleted ? sageFill : (isToday ? Colors.white : gray300),
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(color: isToday ? sageRing : gray300, width: 1),
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(Icons.check, color: Colors.white, size: checkSize)
                        : isToday
                            ? Container(width: dotlet, height: dotlet, decoration: const BoxDecoration(color: sageRing, shape: BoxShape.circle))
                            : null,
                  ),
                ),
              ]);
            }),
          );
        }),
      ]),
    );
  }

  // Section headers and lists
  Widget _buildSectionHeader({required String title, required String subtitle, bool? expanded, VoidCallback? onToggle}) {
    final isCollapsible = onToggle != null && expanded != null;
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.27, color: Color(0xFF1D2126))),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.3)),
      ],
    );

    if (!isCollapsible) {
      return SizedBox(width: double.infinity, child: header);
    }
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: header),
            Padding(
              padding: const EdgeInsets.only(top: 2.0, left: 8),
              child: Icon(expanded == true ? Icons.expand_less : Icons.expand_more, color: const Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengesList(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Align(alignment: Alignment.centerLeft, child: Text('No challenges yet.')));
    }
    return Column(children: [
      for (var i = 0; i < rows.length; i++) ...[
        _buildChallengeCard(
          emoji: _emojiForTitle(rows[i]['name']?.toString()),
          title: rows[i]['name']?.toString() ?? 'Challenge',
          description: rows[i]['description']?.toString() ?? '',
          progress: (rows[i]['progress_value'] as num?)?.toInt() ?? 0,
          total: (rows[i]['target_value'] as num?)?.toInt() ?? 0,
          isCompleted: _computePercent(rows[i]) >= 100,
        ),
        if (i < rows.length - 1) const SizedBox(height: 12),
      ],
    ]);
  }

  Widget _buildChallengeCard({
    required String emoji,
    required String title,
    required String description,
    required int progress,
    required int total,
    required bool isCompleted,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFF0FAF7) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAED), width: 1),
        boxShadow: const [BoxShadow(color: Color(0x0C000000), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1D2126))),
              const SizedBox(height: 4),
              Text(description, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.3)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFE6F0FF), borderRadius: BorderRadius.circular(12)),
            child: Text('$progress/$total', style: const TextStyle(color: Color(0xFF1D75FF), fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 12),
        Container(
          height: 10,
          decoration: BoxDecoration(color: const Color(0xFFE5F6F2), borderRadius: BorderRadius.circular(999)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: total > 0 ? (progress / total).clamp(0, 1) : 0,
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFF2A8469), borderRadius: BorderRadius.circular(999)),
            ),
          ),
        ),
      ]),
    );
  }

  // Data helpers
  List<(Color, Color)> _palette() => const [
        (Color(0xFFD1FAE5), Color(0xFF059669)),
        (Color(0xFFFCE7F3), Color(0xFFEC4899)),
        (Color(0xFFE0F2FE), Color(0xFF0EA5E9)),
        (Color(0xFFFEF3C7), Color(0xFFF59E0B)),
        (Color(0xFFDDD6FE), Color(0xFF7C3AED)),
      ];

  int _computePercent(Map<String, dynamic> row) {
    final ratio = (row['progress_ratio'] as num?)?.toDouble();
    if (ratio != null) {
      final pct = (ratio * 100).clamp(0, 100);
      return pct.round();
    }
    final progress = (row['progress_value'] as num?)?.toDouble() ?? 0;
    final target = (row['target_value'] as num?)?.toDouble() ?? 0;
    if (target <= 0) return 0;
    return ((progress / target) * 100).clamp(0, 100).round();
  }

  String _completionTag(Map<String, dynamic> r) {
    String? tryFormat(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      if (s.isEmpty) return null;
      DateTime? dt = DateTime.tryParse(s);
      if (dt == null) {
        final ym = RegExp(r'^\d{4}-\d{2}$');
        final ymd = RegExp(r'^\d{4}-\d{2}-\d{2}');
        if (ym.hasMatch(s)) {
          dt = DateTime.tryParse('$s-01');
        } else if (ymd.hasMatch(s)) {
          dt = DateTime.tryParse(s.substring(0, 10));
        }
      }
      if (dt == null) return null;
      return DateFormat('MMMM yyyy').format(dt.toLocal());
    }
    const keys = ['completed_at', 'achieved_at', 'unlocked_at', 'updated_at', 'created_at'];
    for (final k in keys) {
      final label = tryFormat(r[k]);
      if (label != null) return label;
    }
    final label = tryFormat(r['period']);
    return label ?? '';
  }

  List<Map<String, dynamic>> _currentMonthChallenges() {
    return _inProgress.where((r) => !_isWeekly(r) && _isCurrentMonth(r)).toList();
  }

  List<Map<String, dynamic>> _ongoingChallenges() {
    return _inProgress.where((r) => !_isWeekly(r) && !_isCurrentMonth(r)).toList();
  }

  bool _isWeekly(Map<String, dynamic> r) {
    final p = (r['period'] ?? '').toString().toLowerCase();
    return p.contains('week');
  }

  bool _isCurrentMonth(Map<String, dynamic> r) {
    final p = (r['period'] ?? '').toString();
    final now = DateTime.now();
    final pl = p.toLowerCase();
    if (pl.contains('monthly') || pl == 'month') return true;
    DateTime? dt = DateTime.tryParse(p);
    if (dt == null) {
      final m = RegExp(r'^(\d{4})-(\d{2})').firstMatch(p);
      if (m != null) {
        final y = int.tryParse(m.group(1)!);
        final mm = int.tryParse(m.group(2)!);
        if (y != null && mm != null) dt = DateTime(y, mm, 1);
      }
    }
    return dt != null && dt.year == now.year && dt.month == now.month;
  }

  String _emojiForTitle(String? title) {
    final t = (title ?? '').toLowerCase();
    if (t.contains('flavor') || t.contains('explorer')) return '📘';
    if (t.contains('skill') || t.contains('knife')) return '🔪';
    if (t.contains('speed') || t.contains('supper')) return '⏱️';
    if (t.contains('month')) return '🦊';
    return '🎯';
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        setState(() {
          _loading = false;
          _error = 'Not signed in';
        });
        return;
      }
      final data = await SupabaseService.client
          .from('v_user_achievements')
          .select('*')
          .eq('user_id', user.id)
          .order('status', ascending: true)
          .order('period', ascending: true)
          .order('name', ascending: true);
      final rows = List<Map<String, dynamic>>.from(data as List);
      final completed = <Map<String, dynamic>>[];
      final inProgress = <Map<String, dynamic>>[];
      for (final r in rows) {
        final status = r['status']?.toString().toLowerCase();
        if (status == 'completed') {
          completed.add(r);
        } else {
          inProgress.add(r);
        }
      }
      if (!mounted) return;
      setState(() {
        _completed = completed;
        _inProgress = inProgress;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load: $e';
      });
    }
  }
}

// Completed grid card
class _CompletedCard extends StatelessWidget {
  final String? iconUrl;
  final String period;
  final String title;
  final String subtitle;
  final Color accentBg;
  final Color accentFg;
  const _CompletedCard({
    required this.iconUrl,
    required this.period,
    required this.title,
    required this.subtitle,
    required this.accentBg,
    required this.accentFg,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(builder: (context, constraints) {
          final side = constraints.biggest.shortestSide;
          double scale(double x) => x * (side / 164.0);
          final pad = scale(16).clamp(12.0, 20.0);
          final radius = scale(12).clamp(8.0, 16.0);
          final iconTile = scale(40).clamp(28.0, 64.0);
          final innerIcon = (iconTile * 0.8).clamp(20.0, 48.0);
          final gap = scale(8).clamp(6.0, 14.0);
          final infoHeight = scale(50).clamp(42.0, 96.0);
          final titleSize = scale(14).clamp(12.0, 20.0);
          final subtitleSize = scale(10).clamp(10.0, 16.0);
          final chipFont = scale(10).clamp(9.0, 14.0);
          final chipRadius = scale(4).clamp(4.0, 8.0);

          return Container(
            padding: EdgeInsets.all(pad),
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: const BorderSide(width: 1, color: Color(0xFFE8EAED)),
                borderRadius: BorderRadius.circular(radius),
              ),
              shadows: const [BoxShadow(color: Color(0x0C000000), blurRadius: 2, offset: Offset(0, 1))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              SizedBox(
                width: iconTile,
                height: iconTile,
                child: Center(
                  child: iconUrl != null && iconUrl!.isNotEmpty
                      ? Image.network(iconUrl!, width: innerIcon, height: innerIcon, fit: BoxFit.contain)
                      : Text('🏆', style: TextStyle(fontSize: innerIcon * 0.65, color: const Color(0xFF353C45))),
                ),
              ),
              SizedBox(height: gap),
              Container(
                padding: EdgeInsets.symmetric(horizontal: scale(4).clamp(4.0, 10.0), vertical: scale(2).clamp(2.0, 6.0)),
                decoration: ShapeDecoration(color: const Color(0xFFF3F5F6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(chipRadius))),
                child: Text(
                  period.isEmpty ? '—' : period,
                  style: TextStyle(color: const Color(0xFF596573), fontSize: chipFont, fontFamily: 'Manrope', fontWeight: FontWeight.w700, height: 1.4),
                ),
              ),
              SizedBox(height: gap),
              SizedBox(
                width: double.infinity,
                height: infoHeight,
                child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Text(title, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: const Color(0xFF353C45), fontSize: titleSize, fontFamily: 'Manrope', fontWeight: FontWeight.w700, height: 1.43)),
                  SizedBox(height: scale(2).clamp(2.0, 6.0)),
                  Text(subtitle, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: const Color(0xFF596573), fontSize: subtitleSize, fontFamily: 'Manrope', fontWeight: FontWeight.w500, height: 1.4)),
                ]),
              ),
            ]),
          );
        }),
      ),
    );
  }
}
