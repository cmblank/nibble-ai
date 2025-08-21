import 'package:flutter/material.dart';
import '../design_tokens/color_tokens.dart';
import '../widgets/profile_sheet.dart';
import 'academy_screen.dart';
import 'achievements_screen.dart';
import 'kitchen_screen.dart';
import 'onboarding_screen.dart';
import '../utils/profile_storage.dart';
import 'stored_profile_screen.dart';
import 'help_support_screen.dart';

/// Bottom sheet content for the More tab: list of navigation/action cards
class MorePanel extends StatelessWidget {
  final BuildContext rootContext; // to navigate after closing the sheet
  const MorePanel({super.key, required this.rootContext});

  void _navigateAfterClose(Widget page) {
    // Capture navigator synchronously, then close sheet and navigate next microtask
    final nav = Navigator.of(rootContext);
    nav.pop();
    Future.microtask(() {
      nav.push(MaterialPageRoute(builder: (_) => page));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _dragHandle(),
            const SizedBox(height: 8),
            _header(context, 'More'),
            const SizedBox(height: 12),

            _card(
              context,
              icon: const Icon(Icons.school_outlined, color: DesignTokens.brick900),
              title: 'Nibble Academy',
              subtitle: 'Learn new techniques, skills & more',
              onTap: () => _navigateAfterClose(const AcademyScreen()),
            ),
            _card(
              context,
              icon: const Icon(Icons.emoji_events_outlined, color: DesignTokens.brick900),
              title: 'Achievements',
              subtitle: 'Track your wins and accomplishments',
              onTap: () => _navigateAfterClose(const AchievementsScreen()),
            ),
            _card(
              context,
              icon: const Icon(Icons.groups_outlined, color: DesignTokens.brick900),
              title: 'Kitchen Table',
              subtitle: 'Post to the community',
              onTap: () => _navigateAfterClose(const KitchenScreen()),
            ),
            _card(
              context,
              icon: const Icon(Icons.settings_outlined, color: DesignTokens.brick900),
              title: 'Settings',
              subtitle: 'App preferences and notifications',
              onTap: () {
                final nav = Navigator.of(rootContext);
                nav.pop();
                // ignore: use_build_context_synchronously
                Future.microtask(() => showProfileSheet(nav.context));
              },
            ),
            _card(
              context,
              icon: const Icon(Icons.help_outline, color: DesignTokens.brick900),
              title: 'Help & Support',
              subtitle: 'Get help or send feedback',
              onTap: () => _navigateAfterClose(const HelpSupportScreen()),
            ),
            _card(
              context,
              icon: const Icon(Icons.restore_outlined, color: DesignTokens.brick900),
              title: 'Reset App',
              subtitle: 'Clear profile and restart onboarding',
              onTap: () async {
                final nav = Navigator.of(rootContext);
                final messenger = ScaffoldMessenger.of(rootContext);
                // ignore: use_build_context_synchronously
                final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Reset App'),
                        content: const Text('This will clear your local profile and restart onboarding.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    ) ??
                    false;
                if (!ok) return;
                await ProfileStorage.clearProfile();
                nav.pop();
                Future.microtask(() {
                  nav.push(
                    MaterialPageRoute(
                      builder: (_) => CookingProfileOnboarding(
                        onFinish: () {
                          nav.popUntil((r) => r.isFirst);
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Onboarding completed!')),
                          );
                        },
                      ),
                    ),
                  );
                });
              },
            ),
            _card(
              context,
              icon: const Icon(Icons.play_circle_outline, color: DesignTokens.brick900),
              title: 'Test Onboarding',
              subtitle: 'Preview the welcome flow',
              onTap: () {
                final nav = Navigator.of(rootContext);
                final messenger = ScaffoldMessenger.of(rootContext);
                final messengerState = messenger;
                _navigateAfterClose(
                  CookingProfileOnboarding(
                    onFinish: () {
                      nav.popUntil((r) => r.isFirst);
                      messengerState.showSnackBar(
                        const SnackBar(content: Text('Onboarding completed!')),
                      );
                    },
                  ),
                );
              },
            ),
            _card(
              context,
              icon: const Icon(Icons.account_circle_outlined, color: DesignTokens.brick900),
              title: 'Show Stored Profile',
              subtitle: 'View stored profile JSON',
              onTap: () => _navigateAfterClose(const StoredProfileScreen()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dragHandle() => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: DesignTokens.gray400,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _header(BuildContext context, String title) => Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: TextColors.primary),
        ),
      );

  Widget _card(
    BuildContext context, {
    required Widget icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: BackgroundColors.primary,
          border: Border.all(color: BorderColors.primary),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1))],
        ),
        child: ListTile(
          leading: icon,
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: TextColors.primary)),
          subtitle: Text(subtitle, style: const TextStyle(color: TextColors.secondary)),
          trailing: const Icon(Icons.chevron_right, color: TextColors.secondary),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }
}
