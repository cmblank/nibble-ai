import 'dart:developer' as developer;

import '../models/pantry_enums.dart';
import 'supabase_service.dart';

/// Reads onboarding/setup preferences from the profiles table (profile_data JSON).
class ProfilePrefsService {
  /// Attempts to read a default storage location from profile_data JSON.
  /// Returns null if unavailable or Supabase is not initialized.
  static Future<StorageLocation?> getDefaultStorageLocation() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return null;
      final profile = await SupabaseService.getUserProfile(user.id);
      if (profile == null) return null;

      // Handle flexible shapes of profile_data
      final data = profile['profile_data'];
      if (data is Map<String, dynamic>) {
        final loc = _extractLocationFromProfileData(data);
        return loc;
      }
      return null;
    } catch (e, st) {
      developer.log('getDefaultStorageLocation failed', error: e, stackTrace: st, name: 'ProfilePrefsService');
      return null;
    }
  }

  static StorageLocation? _extractLocationFromProfileData(Map<String, dynamic> data) {
    // Common possible keys
    final candidates = <String?>[
      data['default_storage_location'] as String?,
      data['storage_location'] as String?,
      (data['defaults'] is Map<String, dynamic>) ? (data['defaults']['storage_location'] as String?) : null,
      (data['kitchen'] is Map<String, dynamic>) ? (data['kitchen']['default_storage'] as String?) : null,
    ];
    for (final val in candidates) {
      if (val == null) continue;
      final loc = _tryParseLocation(val);
      if (loc != null) return loc;
    }
    return null;
  }

  static StorageLocation? _tryParseLocation(String s) {
    final lower = s.toLowerCase();
    if (lower.contains('fridge') || lower.contains('refrigerator')) return StorageLocation.fridge;
    if (lower.contains('freezer')) return StorageLocation.freezer;
    if (lower.contains('pantry') || lower.contains('cupboard') || lower.contains('cabinet')) return StorageLocation.pantry;
    return null;
  }
}
