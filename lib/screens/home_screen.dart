import 'package:flutter/material.dart';
import '../design_tokens/color_tokens.dart';
import '../design_tokens/typography_tokens.dart';
import '../design_tokens/spacing_tokens.dart';
import '../design_tokens/component_tokens.dart';
import '../widgets/nibble_app_bar.dart';
import 'achievements_screen.dart';
import 'chatbot_screen.dart';
import '../widgets/profile_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.gray100,
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
          child: Padding(
            padding: const EdgeInsets.all(SpacingTokens.spaceLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: SpacingTokens.spaceSM),
                
                // Welcome Banner
                _buildWelcomeBanner(),
                const SizedBox(height: SpacingTokens.spaceXL),
                
                // Tonight Section
                _buildTonightSection(),
                const SizedBox(height: SpacingTokens.spaceLG),
                
                // Weekly Recipe Review
                _buildWeeklyRecipeReview(),
                const SizedBox(height: SpacingTokens.spaceXL),
                
                // Upcoming Meals
                _buildUpcomingMealsSection(),
                const SizedBox(height: SpacingTokens.spaceXL),
                
                // Cooking Journey
                _buildCookingJourneySection(),
                const SizedBox(height: SpacingTokens.spaceXL),
                
                // Pantry Status
                _buildPantryStatusSection(),
                const SizedBox(height: 100), // Extra space for bottom nav
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SpacingTokens.spaceMD), // 16px padding
      decoration: BoxDecoration(
        color: const Color(0xFF319B7B), // sage/1000 color from design tokens
        borderRadius: BorderRadius.circular(RadiusTokens.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Center alignment
        children: [
          // Text section with 2px spacing between lines
          Column(
            children: [
              Text(
                'Welcome, Courtney',
                style: TextStyles.heading200.copyWith(
                  color: Colors.white,
                  fontWeight: TypographyTokens.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2), // 2px spacing between text lines
              Text(
                'Let\'s cook something delicious.',
                style: TextStyles.body85.copyWith(
                  color: Colors.white,
                  fontWeight: TypographyTokens.medium,
                  fontSize: 14,
                  height: 20 / 14, // line height 20px
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
                  () {},
                ),
              ),
              const SizedBox(width: SpacingTokens.spaceSM), // 8px gap between buttons
              Expanded(
                child: _buildWelcomeButton(
                  'Add Pantry Item',
                  Icons.check,
                  () {},
                ),
              ),
              const SizedBox(width: SpacingTokens.spaceSM), // 8px gap between buttons
              Expanded(
                child: _buildWelcomeButton(
                  'Grocery List',
                  Icons.shopping_cart,
                  () {},
                  badge: '24',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

    Widget _buildWelcomeButton(String text, IconData icon, VoidCallback onTap, {String? badge}) {
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
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: DesignTokens.gray600, // Dark gray icon
                  size: 20,
                ),
                const SizedBox(height: SpacingTokens.spaceXS),
                Text(
                  text,
                  style: TextStyles.body75.copyWith(
                    color: DesignTokens.gray600, // Medium gray text
                    fontWeight: TypographyTokens.semibold,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.brick900, // Use brand red for badge
                    borderRadius: BorderRadius.circular(RadiusTokens.full),
                  ),
                  child: Text(
                    badge,
                    style: TextStyles.body75.copyWith(
                      color: Colors.white,
                      fontWeight: TypographyTokens.semibold,
                      fontSize: 8,
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
              onTap: () {},
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
        _buildTonightRecipeCard(),
      ],
    );
  }

  Widget _buildTonightRecipeCard() {
    return Container(
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
              image: const DecorationImage(
                image: AssetImage('assets/images/meal-salad.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(SpacingTokens.spaceLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Creamy Lemon Orzo',
                  style: TextStyles.heading125.copyWith(
                    fontWeight: TypographyTokens.bold,
                  ),
                ),
                const SizedBox(height: SpacingTokens.spaceSM),
                Row(
                  children: [
                    _buildRecipeDetail(Icons.people, '4'),
                    const SizedBox(width: SpacingTokens.spaceLG),
                    _buildRecipeDetail(Icons.access_time, '15m'),
                  ],
                ),
                const SizedBox(height: SpacingTokens.spaceMD),
                Row(
                  children: [
                    _buildRecipeTag('Quick'),
                    const SizedBox(width: SpacingTokens.spaceSM),
                    _buildRecipeTag('Medium'),
                  ],
                ),
                const SizedBox(height: SpacingTokens.spaceLG),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
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
                        onPressed: () {},
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

  Widget _buildWeeklyRecipeReview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.spaceLG,
        vertical: SpacingTokens.spaceMD,
      ),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(RadiusTokens.full),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(RadiusTokens.full),
            ),
            child: const Center(
              child: Text(
                '👨‍🍳',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: SpacingTokens.spaceMD),
          Expanded(
            child: Text(
              'Weekly Recipe Review',
              style: TextStyles.body100.copyWith(
                fontWeight: TypographyTokens.medium,
              ),
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingMealsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Upcoming Meals',
              style: TextStyles.heading150.copyWith(
                fontWeight: TypographyTokens.bold,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {},
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
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildUpcomingMealCard(
                'Creamy Mushroom Risotto',
                'assets/images/meal-spagetti.png',
                '4',
                '30m',
                hasRefreshIcon: true,
              ),
              const SizedBox(width: SpacingTokens.spaceMD),
              _buildUpcomingMealCard(
                'Sausage & Peppers',
                'assets/images/meal-taco-2.png',
                '4',
                '30m',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingMealCard(
    String title,
    String imagePath,
    String servings,
    String time, {
    bool hasRefreshIcon = false,
  }) {
    return Container(
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
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(RadiusTokens.lg),
                  ),
                  image: DecorationImage(
                    image: AssetImage(imagePath),
                    fit: BoxFit.cover,
                  ),
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
            padding: const EdgeInsets.all(SpacingTokens.spaceMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyles.body100.copyWith(
                    fontWeight: TypographyTokens.semibold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: SpacingTokens.spaceSM),
                Row(
                  children: [
                    _buildRecipeDetail(Icons.people, servings),
                    const SizedBox(width: SpacingTokens.spaceLG),
                    _buildRecipeDetail(Icons.access_time, time),
                  ],
                ),
                const SizedBox(height: SpacingTokens.spaceSM),
                Row(
                  children: [
                    _buildRecipeTag('Quick'),
                    const SizedBox(width: SpacingTokens.spaceSM),
                    _buildRecipeTag('Medium'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCookingJourneySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Your Cooking Journey',
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