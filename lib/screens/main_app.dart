import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'onboarding_screen.dart';
import '../utils/profile_storage.dart';
import '../services/supabase_service.dart';
import '../widgets/nibble_tab_scaffold.dart';

// Debug helper: set to false to allow entering the app after onboarding.
const bool kForceOnboarding = false;

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _hasProfile = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
    final profile = await ProfileStorage.loadProfile();
    setState(() {
      _hasProfile = profile.isNotEmpty && profile['name'] != null;
      _isLoading = false;
    });

    // Auto-sync local onboarding JSON to Supabase if cloud profile_data is missing
    if (profile.isNotEmpty) {
      // Run without blocking UI
      _maybeSyncCloud(profile);
    }
  }

  Future<void> _maybeSyncCloud(Map<String, dynamic> localProfile) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return;
      final cloud = await SupabaseService.getUserProfile(userId);
      final hasCloudJson = (cloud != null && cloud['profile_data'] != null);
      if (!hasCloudJson) {
        final ok = await SupabaseService.upsertProfileJson(
          userId: userId,
          profileJson: localProfile,
        );
        developer.log('Auto-sync profile_data to Supabase: ${ok ? 'success' : 'failed'}', name: 'MainApp');
      }
    } catch (e) {
      developer.log('Auto-sync error: $e', name: 'MainApp', error: e);
    }
  }

  void _onOnboardingFinished() {
    setState(() {
      _hasProfile = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kForceOnboarding) {
      return CookingProfileOnboarding(onFinish: _onOnboardingFinished);
    }

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAFBFC),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
          ),
        ),
      );
    }

    if (!_hasProfile) {
      return CookingProfileOnboarding(onFinish: _onOnboardingFinished);
    }

    return const NibbleTabScaffold();
  }
}