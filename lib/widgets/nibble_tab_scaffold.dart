import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/recipes_screen.dart';
import '../screens/pantry_screen_clean.dart';
import '../screens/cook_screen.dart';
import '../screens/more_panel.dart';
import '../screens/chatbot_screen.dart';
import '../screens/achievements_screen.dart';
import '../widgets/profile_sheet.dart';
import 'nibble_app_bar.dart';
import 'nibble_tab_bar.dart';

class NibbleTabScaffold extends StatefulWidget {
  final NibbleTab initialTab;
  final int pantryBadgeCount;
  final int planningBadgeCount;

  const NibbleTabScaffold({
    super.key,
    this.initialTab = NibbleTab.home,
    this.pantryBadgeCount = 0,
    this.planningBadgeCount = 0,
  });

  @override
  State<NibbleTabScaffold> createState() => _NibbleTabScaffoldState();
}

class _NibbleTabScaffoldState extends State<NibbleTabScaffold> {
  late NibbleTab _current = widget.initialTab;

  final _navKeys = {
    for (final t in NibbleTab.values) t: GlobalKey<NavigatorState>(),
  };

  void _onSelect(NibbleTab tab) {
    // Intercept More tab to open a panel instead of switching tabs
    if (tab == NibbleTab.more) {
      _openMorePanel();
      return; // keep current tab selected
    }

    if (_current == tab) {
      final nav = _navKeys[tab]!.currentState!;
      if (nav.canPop()) nav.popUntil((r) => r.isFirst);
      // Try scroll-to-top via PrimaryScrollController
      final primary = PrimaryScrollController.of(context);
      if (primary.hasClients) {
        primary.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
      developer.log('tab_reselect_scroll_top', name: 'Tabs', error: {'tab': tab.name});
      return;
    }
    setState(() => _current = tab);
    developer.log('tab_select', name: 'Tabs', error: {'tab': tab.name});
  }

  Future<void> _openMorePanel() async {
    developer.log('open_more_panel', name: 'Tabs');
    final mq = MediaQuery.of(context);
  await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SizedBox(
          height: mq.size.height * 0.9,
      child: MorePanel(rootContext: context),
        );
      },
    );
  }

  Widget _buildTabNavigator(NibbleTab tab, Widget child) {
    return Navigator(
      key: _navKeys[tab],
      onGenerateRoute: (settings) => MaterialPageRoute(builder: (_) => child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final index = NibbleTab.values.indexOf(_current);
    final nav = _navKeys[_current]!.currentState;
    final atRoot = nav == null ? true : !nav.canPop();
    return PopScope(
      canPop: _current == NibbleTab.home && atRoot,
      onPopInvoked: (didPop) {
        if (didPop) return;
        final navState = _navKeys[_current]!.currentState!;
        if (navState.canPop()) {
          navState.pop();
          return;
        }
        if (_current != NibbleTab.home) {
          setState(() => _current = NibbleTab.home);
          developer.log('tab_back_to_home_from_root', name: 'Tabs', error: {'from_tab': _current.name});
        }
      },
      child: Scaffold(
    appBar: (_current == NibbleTab.pantry || _current == NibbleTab.home || _current == NibbleTab.recipes || _current == NibbleTab.planning)
      ? null // These screens provide a sliver app bar that hides on scroll
            : NibbleAppBar(
                currentTab: _current,
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
                onWordmarkTap: () => _onSelect(NibbleTab.home),
              ),
        body: IndexedStack(
          index: index,
          children: [
            _buildTabNavigator(NibbleTab.home, const HomeScreen()),
            _buildTabNavigator(NibbleTab.recipes, const RecipesScreen()),
            _buildTabNavigator(NibbleTab.pantry, const PantryScreen()),
            _buildTabNavigator(NibbleTab.planning, const CookScreen()),
            // More tab opens a panel; keep a lightweight placeholder here
            _buildTabNavigator(NibbleTab.more, const SizedBox.shrink()),
          ],
        ),
        bottomNavigationBar: NibbleTabBar(
          current: _current,
          onSelect: _onSelect,
          pantryBadgeCount: widget.pantryBadgeCount,
          planningBadgeCount: widget.planningBadgeCount,
        ),
      ),
    );
  }
}
