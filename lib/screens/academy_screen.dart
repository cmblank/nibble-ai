import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class AcademyScreen extends StatelessWidget {
  const AcademyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              floating: true,
              title: const Text(
                'Cooking Academy',
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeaturedCourse(),
                    const SizedBox(height: 24),
                    const Text(
                      'Essential Skills',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildSkillCard(
                    _essentialSkills[index]['title']!,
                    _essentialSkills[index]['icon']!,
                    _essentialSkills[index]['lessons']!,
                  ),
                  childCount: _essentialSkills.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCourse() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.gardenHerb,
        image: const DecorationImage(
          colorFilter: ColorFilter.mode(Colors.black38, BlendMode.darken),
          image: AssetImage('assets/images/chef_mascot.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 16,
            bottom: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mastering the Basics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '12 Essential Lessons for Every Home Chef',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.gardenHerb,
                  ),
                  child: const Text('Start Learning'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillCard(String title, IconData icon, int lessons) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: AppColors.gardenHerb,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$lessons Lessons',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gardenHerb,
                side: BorderSide(color: AppColors.gardenHerb),
              ),
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

final List<Map<String, dynamic>> _essentialSkills = [
  {
    'title': 'Knife Skills',
    'icon': Icons.restaurant,
    'lessons': 5,
  },
  {
    'title': 'Heat Control',
    'icon': Icons.local_fire_department,
    'lessons': 4,
  },
  {
    'title': 'Seasoning',
    'icon': Icons.spa,
    'lessons': 3,
  },
  {
    'title': 'Sauces',
    'icon': Icons.water_drop,
    'lessons': 6,
  },
  {
    'title': 'Meal Planning',
    'icon': Icons.event_note,
    'lessons': 3,
  },
  {
    'title': 'Food Safety',
    'icon': Icons.security,
    'lessons': 4,
  },
];
