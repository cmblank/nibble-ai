import 'package:flutter/material.dart';
import '../widgets/nibble_app_bar.dart';
import '../widgets/profile_sheet.dart';
import 'achievements_screen.dart';

class PantryScreen extends StatelessWidget {
  const PantryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NibbleAppBar(
        currentTab: NibbleTab.pantry,
        showAchievements: true,
        onAchievementsTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AchievementsScreen()),
        ),
        onProfileTap: () => showProfileSheet(context),
      ),
      body: Center(
        child: Text(
          'Pantry Screen',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
