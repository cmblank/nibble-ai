import 'package:flutter/material.dart';
import '../widgets/nibble_app_bar.dart';
import 'chatbot_screen.dart';
import 'achievements_screen.dart';
import '../widgets/profile_sheet.dart';

class MealPlannerScreen extends StatelessWidget {
  const MealPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NibbleAppBar(
        currentTab: NibbleTab.planning,
        showAchievements: true,
        showBack: true,
        onChatTap: (_) => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatbotScreen()),
        ),
        onAchievementsTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AchievementsScreen()),
        ),
        onProfileTap: () => showProfileSheet(context),
      ),
      body: const Center(
        child: Text('Meal planning coming soon'),
      ),
    );
  }
}
