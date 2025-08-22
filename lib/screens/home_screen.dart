import 'package:flutter/material.dart';
import '../design_tokens/color_tokens.dart';
import '../design_tokens/typography_tokens.dart';
import '../design_tokens/spacing_tokens.dart';
import '../design_tokens/component_tokens.dart';
import '../widgets/nibble_app_bar.dart';
import 'achievements_screen.dart';
import 'chatbot_screen.dart';
import '../widgets/profile_sheet.dart';
import 'shopping_list_screen.dart';
import 'pantry_screen_clean.dart';

class HomeScreen extends StatelessWidget {
  final void Function(NibbleTab tab)? onNavigateToTab;
  const HomeScreen({super.key, this.onNavigateToTab});

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
                    // Tonight Section
                    _buildTonightSection(),
                    const SizedBox(height: SpacingTokens.spaceLG),
                    // Spacer before upcoming meals
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
        onNavigateToTab?.call(NibbleTab.planning);
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
                child: _buildWelcomeButton(
                  'Grocery List',
      Icons.shopping_cart,
      () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ShoppingListScreen()),
        );
      },
      assetName: 'assets/images/icon-cart.png',
                  badge: '24',
                  // Move badge up and right; set orange/1000 tone
                  badgeColor: DesignTokens.flameOrange,
                  badgeTop: -6,
                  badgeRight: -6,
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

  // ignore: unused_element

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