import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../services/supabase_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _completed = const [];
  List<Map<String, dynamic>> _inProgress = const [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAchievements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            backgroundColor: AppColors.creamWhisk,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text(
                    '🏆',
                    style: TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Achievements',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        // Design keeps header clean; errors show inside tabs
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF059669),
                unselectedLabelColor: const Color(0xFF6B7280),
                indicatorColor: const Color(0xFF059669),
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(
                    icon: Text('🎯'),
                    text: 'In Progress',
                  ),
                  Tab(
                    icon: Text('✨'),
                    text: 'Completed',
                  ),
                ],
              ),
            ),
            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInProgressTab(),
                  _buildRecentlyCompletedTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentlyCompletedTab() {
    if (_loading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(24.0),
        child: CircularProgressIndicator(),
      ));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
        ),
      );
    }
    if (_completed.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No achievements completed yet.'),
        ),
      );
    }
    final palette = _colorPalette();
    return RefreshIndicator(
      onRefresh: _fetchAchievements,
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
                childAspectRatio: 0.92,
              ),
              itemBuilder: (context, i) {
                final r = _completed[i];
                final (bg, fg) = palette[i % palette.length];
                return _CompletedCard(
                  iconUrl: r['icon_url'] as String?,
                  period: r['period']?.toString() ?? '',
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

  Widget _buildInProgressTab() {
    if (_loading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(24.0),
        child: CircularProgressIndicator(),
      ));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
        ),
      );
    }
    final palette = _colorPalette();
    return RefreshIndicator(
      onRefresh: _fetchAchievements,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildWeeklyCookingStreak(),
            const SizedBox(height: 20),
            _buildWeeklyChallengesSection(),
            const SizedBox(height: 20),
            // Monthly header (static demo label; can be made dynamic from period)
            Row(
              children: const [
                Text(
                  'September Challenges',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _inProgress.length; i++) ...[
              _buildProgressAchievement(
                icon: '🎯',
                title: _inProgress[i]['name']?.toString() ?? 'Achievement',
                description: _inProgress[i]['description']?.toString() ?? '',
                progress: (_inProgress[i]['progress_value'] as num?)?.toInt() ?? 0,
                total: (_inProgress[i]['target_value'] as num?)?.toInt() ?? 0,
                progressPercentage: _computePercent(_inProgress[i]),
                backgroundColor: palette[i % palette.length].$1,
                iconBackgroundColor: palette[i % palette.length].$2,
              ),
              if (i < _inProgress.length - 1) const SizedBox(height: 16),
            ],
            if (_inProgress.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('No in-progress achievements yet.'),
              ),
          ],
        ),
      ),
    );
  }

  // Old completed card removed (replaced by grid card component below).

  // Data
  Future<void> _fetchAchievements() async {
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

  List<(Color, Color)> _colorPalette() => const [
        (Color(0xFFD1FAE5), Color(0xFF059669)),
        (Color(0xFFFCE7F3), Color(0xFFEC4899)),
        (Color(0xFFE0F2FE), Color(0xFF0EA5E9)),
        (Color(0xFFFEF3C7), Color(0xFFF59E0B)),
        (Color(0xFFDDD6FE), Color(0xFF7C3AED)),
      ];

  Widget _buildProgressAchievement({
    required String icon,
    required String title,
    required String description,
    required int progress,
    required int total,
    required int progressPercentage,
    required Color backgroundColor,
    required Color iconBackgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconBackgroundColor.withAlpha((255 * 0.2).round()),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$progressPercentage%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: iconBackgroundColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$progress / $total',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: iconBackgroundColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((255 * 0.5).round()),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progressPercentage / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: iconBackgroundColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCookingStreak() {
  const cookingDays = [true, true, false, true, true, false, false]; // Mon-Sun
  const daysLeft = 2; // demo
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF059669).withAlpha((255 * 0.2).round()),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF059669),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🔥', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cooking Streak',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      'You\'ve cooked 4x this week! 🍳',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$daysLeft days left',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'This Week',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
              final isCompleted = cookingDays[index];
              final isToday = index == 5; // Saturday (demo to match screenshot ring)
              
              return Column(
                children: [
                  Text(
                    days[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isToday 
                          ? const Color(0xFF059669) 
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCompleted 
                          ? const Color(0xFF059669)
                          : isToday
                              ? const Color(0xFF059669).withAlpha((255 * 0.2).round())
                              : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(16),
                      border: isToday 
                          ? Border.all(color: const Color(0xFF059669), width: 2)
                          : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : isToday
                              ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF059669),
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChallengesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This Weeks Challenges',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Small steps to explore and grow 🌱',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 16),
        _buildChallengeCard(
          emoji: '🥬',
          title: 'Cook with something green',
          description: 'Use leafy greens or green vegetables in 2 meals',
          progress: 1,
          total: 2,
          isCompleted: false,
        ),
        const SizedBox(height: 12),
        _buildChallengeCard(
          emoji: '🏺',
          title: 'Pantry rescue mission',
          description: 'Use 3 pantry items that are older than 5 days',
          progress: 2,
          total: 3,
          isCompleted: false,
        ),
        const SizedBox(height: 12),
        _buildChallengeCard(
          emoji: '🌍',
          title: 'Explore new cuisines',
          description: 'Try a recipe from a cuisine you haven\'t cooked before',
          progress: 1,
          total: 1,
          isCompleted: true,
        ),
      ],
    );
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$progress/$total',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(999),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: total > 0 ? (progress / total).clamp(0, 1) : 0,
              child: Container(
                decoration: BoxDecoration(
                  color: isCompleted ? const Color(0xFF10B981) : const Color(0xFF7C3AED),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Completed grid card matching design
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: iconUrl != null && iconUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(iconUrl!, width: 44, height: 44, fit: BoxFit.cover),
                        )
                      : Text('🏆', style: TextStyle(fontSize: 22, color: accentFg)),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  period,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
