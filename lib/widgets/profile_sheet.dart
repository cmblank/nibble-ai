import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../utils/profile_storage.dart';
import '../screens/onboarding_screen.dart';
import '../screens/main_app.dart';

/// Shows the reusable Profile bottom sheet.
Future<void> showProfileSheet(BuildContext context) async {
  final rootCtx = context;
  await showModalBottomSheet(
    context: rootCtx,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (sheetContext, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24.0),
                children: [
                  const Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(0xFF059669),
                        child: Text('👤', style: TextStyle(fontSize: 20, color: Colors.white)),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Profile',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              'Manage your cooking preferences',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _ProfileMenuItem(
                    icon: '🐛',
                    title: 'Test Onboarding',
                    subtitle: 'Preview the welcome flow',
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        rootCtx,
                        MaterialPageRoute(
                          builder: (context) => CookingProfileOnboarding(
                            onFinish: () {
                              Navigator.pop(rootCtx);
                              ScaffoldMessenger.of(rootCtx).showSnackBar(
                                const SnackBar(content: Text('Onboarding completed!')),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _ProfileMenuItem(
                    icon: '🗂️',
                    title: 'Show Stored Profile (Supabase)',
                    subtitle: 'View profile_data JSON saved to the cloud',
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      final userId = SupabaseService.currentUser?.id;
                      if (userId == null) {
                        ScaffoldMessenger.of(rootCtx).showSnackBar(
                          const SnackBar(content: Text('Not signed in.')),
                        );
                        return;
                      }
                      try {
                        final profile = await SupabaseService.getUserProfile(userId);
                        final jsonObj = profile?['profile_data'];
                        final pretty = const JsonEncoder.withIndent('  ').convert(jsonObj ?? {'note': 'profile_data is null'});
                        final localProfile = await ProfileStorage.loadProfile();
                        if (!rootCtx.mounted) return;
                        showDialog(
                          context: rootCtx,
                          builder: (ctx) => AlertDialog(
                            title: const Text('profiles.profile_data'),
                            content: SizedBox(
                              width: 600,
                              child: SingleChildScrollView(
                                child: SelectableText(pretty),
                              ),
                            ),
                            actions: [
                              if (jsonObj == null && localProfile.isNotEmpty)
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    final ok = await SupabaseService.upsertProfileJson(
                                      userId: userId,
                                      profileJson: localProfile,
                                    );
                                    if (!rootCtx.mounted) return;
                                    ScaffoldMessenger.of(rootCtx).showSnackBar(
                                      SnackBar(content: Text(ok ? 'Synced local profile to Supabase.' : 'Failed to sync profile.')),
                                    );
                                  },
                                  child: const Text('Sync from device'),
                                ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      } catch (e) {
                        if (!rootCtx.mounted) return;
                        ScaffoldMessenger.of(rootCtx).showSnackBar(
                          SnackBar(content: Text('Failed to load profile: $e')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _ProfileMenuItem(
                    icon: '🍽️',
                    title: 'Edit Cooking Profile',
                    subtitle: 'Update your cooking preferences',
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      final currentProfile = await ProfileStorage.loadProfile();
                      if (rootCtx.mounted) {
                        Navigator.push(
                          rootCtx,
                          MaterialPageRoute(
                            builder: (context) => CookingProfileOnboarding(
                              initialData: currentProfile,
                              onFinish: () {
                                Navigator.pop(rootCtx);
                                ScaffoldMessenger.of(rootCtx).showSnackBar(
                                  const SnackBar(content: Text('Profile updated!')),
                                );
                              },
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _ProfileMenuItem(
                    icon: '⚙️',
                    title: 'Settings',
                    subtitle: 'App preferences and notifications',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      ScaffoldMessenger.of(rootCtx).showSnackBar(
                        const SnackBar(content: Text('Settings coming soon!')),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _ProfileMenuItem(
                    icon: '❓',
                    title: 'Help & Support',
                    subtitle: 'Get help or send feedback',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      ScaffoldMessenger.of(rootCtx).showSnackBar(
                        const SnackBar(content: Text('Help & Support coming soon!')),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _ProfileMenuItem(
                    icon: '🔄',
                    title: 'Reset App',
                    subtitle: 'Clear profile and restart onboarding',
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      _showResetConfirmation(rootCtx);
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showResetConfirmation(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Reset App?'),
        content: const Text(
          'This will clear all your preferences and restart the onboarding flow. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ProfileStorage.clearProfile();
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MainApp()),
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      );
    },
  );
}

class _ProfileMenuItem extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 20)),
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
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}
