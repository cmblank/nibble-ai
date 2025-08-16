import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_tokens/color_tokens.dart';
import '../widgets/nibble_app_bar.dart' show NibbleTab; // reuse enum

/// NibbleTabBar — persistent bottom navigation per spec.
/// - Always shows labels
/// - Badge support for Pantry and Planning
/// - Uses Material 3 NavigationBar under the hood
class NibbleTabBar extends StatelessWidget {
  final NibbleTab current;
  final ValueChanged<NibbleTab> onSelect;
  final int pantryBadgeCount; // 0 = hidden
  final int planningBadgeCount; // 0 = hidden

  const NibbleTabBar({
    super.key,
    required this.current,
    required this.onSelect,
    this.pantryBadgeCount = 0,
    this.planningBadgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final selectedIndex = NibbleTab.values.indexOf(current);

    // Ensure proper safe areas and elevated surface look
  final theme = Theme.of(context);

    Widget assetIcon(String assetPath, {required bool selected, int badgeCount = 0}) {
      final img = Image.asset(
        assetPath,
        width: 24,
        height: 24,
        color: selected ? DesignTokens.brick900 : DesignTokens.brick1400,
      );
      if (badgeCount <= 0) return img;
      return Badge.count(
        count: badgeCount,
        alignment: Alignment.topRight,
        child: img,
      );
    }

    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: DesignTokens.brick900.withValues(alpha: 0.12),
        elevation: theme.bottomNavigationBarTheme.elevation ?? 3,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
          final isSelected = states.contains(WidgetState.selected);
          // Spec: font size 10, line-height 14, center, weight: Medium (rest) / Bold (selected)
          final base = theme.textTheme.labelSmall?.copyWith(fontSize: 10, height: 14 / 10);
          return base?.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? DesignTokens.brick900 : DesignTokens.brick1400,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? DesignTokens.brick900 : DesignTokens.brick1400,
          );
        }),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          // Add subtle top border per spec (gray-300)
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
              top: BorderSide(color: DesignTokens.gray300, width: 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: NavigationBar(
          height: 56,
          selectedIndex: selectedIndex,
          destinations: [
            NavigationDestination(
              icon: assetIcon('assets/images/icon-home.png', selected: false),
              selectedIcon: assetIcon('assets/images/icon-home.png', selected: true),
              label: 'Home',
            ),
            NavigationDestination(
              icon: assetIcon('assets/images/icon-open-book.png', selected: false),
              selectedIcon: assetIcon('assets/images/icon-open-book.png', selected: true),
              label: 'Recipes',
            ),
            NavigationDestination(
              icon: assetIcon('assets/images/icon-note-book.png', selected: false, badgeCount: pantryBadgeCount),
              selectedIcon: assetIcon('assets/images/icon-note-book.png', selected: true, badgeCount: pantryBadgeCount),
              label: 'Pantry',
            ),
            NavigationDestination(
              icon: assetIcon('assets/images/icon-calendar-date.png', selected: false, badgeCount: planningBadgeCount),
              selectedIcon: assetIcon('assets/images/icon-calendar-date.png', selected: true, badgeCount: planningBadgeCount),
              label: 'Planning',
            ),
            NavigationDestination(
              icon: assetIcon('assets/images/icon-menu-hamburger.png', selected: false),
              selectedIcon: assetIcon('assets/images/icon-menu-hamburger.png', selected: true),
              label: 'More',
            ),
          ],
          onDestinationSelected: (i) {
            final tab = NibbleTab.values[i];
            HapticFeedback.selectionClick();
            onSelect(tab);
          },
        ),
        ),
      ),
    );
  }
}
