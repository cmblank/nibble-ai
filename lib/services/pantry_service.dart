import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pantry_enums.dart';
import '../models/pantry_item.dart';
import 'supabase_service.dart';
import 'household_service.dart';

/// PantryService provides CRUD operations for pantry items using Supabase.
/// It maps between the app's PantryItem model and the `user_pantry` table.
class PantryService {
  static SupabaseClient get _client => SupabaseService.client;

  static String? get _userId {
    try {
      return SupabaseService.currentUser?.id;
    } catch (_) {
      // In tests, Supabase may not be initialized yet
      return null;
    }
  }

  /// Returns true when a user is signed in and we can call RLS-protected endpoints.
  static bool get isAuthenticated {
    try {
      return SupabaseService.isAuthenticated;
    } catch (_) {
      // During tests or early app startup before Supabase.initialize
      return false;
    }
  }

  /// Fetch pantry rows for current household (household_id now required).
  static Future<List<PantryItem>> fetchItems() async {
    final uid = _userId;
    if (uid == null) return [];
    final hid = await HouseholdService.ensureHousehold();
    try {
      if (hid == null) return [];
      final response = await _client.from('user_pantry').select().eq('household_id', hid).order('created_at', ascending: false);
      final rows = List<Map<String, dynamic>>.from(response);
      return rows.map(_fromRow).toList();
    } catch (e, st) {
      developer.log('fetchItems failed', error: e, stackTrace: st, name: 'PantryService');
      return [];
    }
  }

  /// Insert a new pantry item for the current user. Returns the inserted item with id.
  static Future<PantryItem?> addItem(PantryItem item) async {
    final uid = _userId;
    if (uid == null) return null;
    try {
  final hid = await HouseholdService.ensureHousehold();
      final payload = _toRow(uid, item);
  if (hid == null) return null; // strict requirement
  payload['household_id'] = hid; payload['added_by'] = uid;
      final rows = await _client.from('user_pantry').insert(payload).select().limit(1);
      if (rows.isNotEmpty) {
        return _fromRow(Map<String,dynamic>.from(rows.first));
      }
      return null;
    } catch (e, st) {
      developer.log('addItem failed', error: e, stackTrace: st, name: 'PantryService');
      return null;
    }
  }

  /// Update fields on an existing pantry item row.
  static Future<bool> updateItem(PantryItem item) async {
    final uid = _userId;
    if (uid == null || item.id == null) return false;
    try {
  final payload = _toRow(uid, item)..remove('user_id')..remove('household_id')..remove('added_by');
      await _client.from('user_pantry').update(payload).eq('id', item.id!);
      return true;
    } catch (e, st) {
      developer.log('updateItem failed', error: e, stackTrace: st, name: 'PantryService');
      return false;
    }
  }

  /// Delete an item from the user's pantry.
  static Future<bool> deleteItem(String id) async {
    if (_userId == null) return false;
    try {
      await _client
          .from('user_pantry')
          .delete()
          .eq('id', id);
      return true;
    } catch (e, st) {
      developer.log('deleteItem failed', error: e, stackTrace: st, name: 'PantryService');
      return false;
    }
  }

  // Mapping helpers
  static PantryItem _fromRow(Map<String, dynamic> row) {
    // user_pantry schema: id, user_id, item_name, category, quantity, expiry_date, created_at
    // Optional fields we intend to add: details, opened_date, purchase_date, storage_location
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    final createdAt = row['created_at'] as String?;
  final expiryDate = parseDate(row['expiry_date']);
    final purchaseDate = parseDate(row['purchase_date']) ??
        (createdAt != null ? DateTime.tryParse(createdAt) : null) ??
        DateTime.now();

    final categoryStr = (row['category'] as String?) ?? FoodCategory.other.display;
    final quantity = row['quantity'] as String?;
    final details = row['details'] as String?;
    final storageStr = row['storage_location'] as String?;
    final storage = storageStr != null
        ? StorageLocation.fromString(storageStr)
        : StorageLocation.pantry; // fallback for current schema

    return PantryItem(
      id: row['id']?.toString(),
      name: (row['item_name'] as String?) ?? 'Item',
      details: details,
      size: quantity, // map `quantity` into size string
      purchaseDate: purchaseDate,
  openedDate: null,
      expirationDate: expiryDate,
      category: FoodCategory.fromString(categoryStr),
      storageLocation: storage,
      isLowStock: false,
      lowStockThreshold: null,
    );
  }

  static Map<String, dynamic> _toRow(String userId, PantryItem item) {
    // Only include columns that exist on the current schema:
    // user_pantry(user_id, item_name, category, quantity, expiry_date)
    // Note: expiry_date is a DATE column, so send YYYY-MM-DD
    final String expiryDateStr = item.expirationDate.toIso8601String().split('T').first;
    return {
      'user_id': userId,
      'item_name': item.name,
      'category': item.category.display,
      'quantity': item.size,
      'expiry_date': expiryDateStr,
    };
  }

  /// Import pantry items from onboarding profile_data when the pantry is empty.
  /// Returns the number of items inserted. Safe to call multiple times; it
  /// will no-op if any pantry rows already exist for the user.
  static Future<int> importOnboardingPantryIfEmpty() async {
    final uid = _userId;
    if (uid == null) return 0;
    try {
      // If user already has pantry items, don't import.
      final existing = await fetchItems();
      if (existing.isNotEmpty) return 0;

      final profile = await SupabaseService.getUserProfile(uid);
      if (profile == null) return 0;
      final data = profile['profile_data'];
      if (data is! Map<String, dynamic>) return 0;
      final pantry = data['pantry'];
      if (pantry is! Map<String, dynamic>) return 0;

      // Gather candidate item names from known onboarding lists.
      List<String> list(dynamic v) => v is List ? List<String>.from(v) : <String>[];
      final names = <String>{
        ...list(pantry['pantryStaples']),
        ...list(pantry['grainsPasta']),
        ...list(pantry['condiments']),
        ...list(pantry['dairyAlternatives']),
        ...list(pantry['proteins']),
        ...list(pantry['veggies']),
        ...list(pantry['fruits']),
      }..removeWhere((e) => e.trim().isEmpty);

      if (names.isEmpty) return 0;

      // Build items with simple heuristics for category and storage.
      final now = DateTime.now();
      FoodCategory guessCategory(String n) {
        final s = n.toLowerCase();
        if (s.contains('flour') || s.contains('sugar') || s.contains('baking') || s.contains('yeast') || s.contains('bicarb')) {
          return FoodCategory.baking;
        }
        if (s.contains('cumin') || s.contains('pepper') || s.contains('chili') || s.contains('oregano') || s.contains('paprika') || s.contains('spice')) {
          return FoodCategory.herbsAndSpices;
        }
        if (s.contains('oil') || s.contains('vinegar') || s.contains('sauce') || s.contains('ketchup') || s.contains('mustard') || s.contains('mayo')) {
          return FoodCategory.condiments;
        }
        if (s.contains('milk') || s.contains('cheese') || s.contains('yogurt') || s.contains('butter')) {
          return FoodCategory.dairy;
        }
        if (s.contains('rice') || s.contains('pasta') || s.contains('noodle') || s.contains('grain') || s.contains('oats')) {
          return FoodCategory.grains;
        }
        if (s.contains('chicken') || s.contains('beef') || s.contains('pork') || s.contains('tofu') || s.contains('egg')) {
          return FoodCategory.protein;
        }
        if (s.contains('apple') || s.contains('banana') || s.contains('berry') || s.contains('lettuce') || s.contains('spinach') || s.contains('carrot') || s.contains('tomato')) {
          return FoodCategory.produce;
        }
        return FoodCategory.other;
      }

      StorageLocation defaultStorage(FoodCategory c) {
        switch (c) {
          case FoodCategory.produce:
          case FoodCategory.dairy:
          case FoodCategory.protein:
            return StorageLocation.fridge;
          case FoodCategory.frozenFoods:
            return StorageLocation.freezer;
          default:
            return StorageLocation.pantry;
        }
      }

      DateTime computeExpiry(FoodCategory c, StorageLocation s, DateTime purchase) {
        return purchase.add(c.getShelfLife(s));
      }

      final items = names.map((n) {
        final cat = guessCategory(n);
        final loc = defaultStorage(cat);
        final expiry = computeExpiry(cat, loc, now);
        return PantryItem(
          name: n,
          details: null,
          size: null,
          purchaseDate: now,
          expirationDate: expiry,
          category: cat,
          storageLocation: loc,
        );
      }).toList();

      // Insert in one batch.
      final payload = items.map((i) => _toRow(uid, i)).toList();
      await _client.from('user_pantry').insert(payload);
      developer.log('Imported ${items.length} onboarding pantry items', name: 'PantryService');
      return items.length;
    } catch (e, st) {
      developer.log('importOnboardingPantryIfEmpty failed', error: e, stackTrace: st, name: 'PantryService');
      return 0;
    }
  }

  /// Import onboarding pantry items, merging with any existing items.
  /// Dedupes by case-insensitive item_name. Returns number of inserted rows.
  static Future<int> importOnboardingPantryMerge() async {
    final uid = _userId;
    if (uid == null) return 0;
    try {
      final profile = await SupabaseService.getUserProfile(uid);
      if (profile == null) return 0;
      final data = profile['profile_data'];
      if (data is! Map<String, dynamic>) return 0;
      final pantry = data['pantry'];
      if (pantry is! Map<String, dynamic>) return 0;

      List<String> list(dynamic v) => v is List ? List<String>.from(v) : <String>[];
      final names = <String>{
        ...list(pantry['pantryStaples']),
        ...list(pantry['grainsPasta']),
        ...list(pantry['condiments']),
        ...list(pantry['dairyAlternatives']),
        ...list(pantry['proteins']),
        ...list(pantry['veggies']),
        ...list(pantry['fruits']),
      }..removeWhere((e) => e.trim().isEmpty);
      if (names.isEmpty) return 0;

      final existing = await fetchItems();
      final existingNames = existing.map((e) => e.name.trim().toLowerCase()).toSet();
      final now = DateTime.now();

      FoodCategory guessCategory(String n) {
        final s = n.toLowerCase();
        if (s.contains('flour') || s.contains('sugar') || s.contains('baking') || s.contains('yeast') || s.contains('bicarb')) {
          return FoodCategory.baking;
        }
        if (s.contains('cumin') || s.contains('pepper') || s.contains('chili') || s.contains('oregano') || s.contains('paprika') || s.contains('spice')) {
          return FoodCategory.herbsAndSpices;
        }
        if (s.contains('oil') || s.contains('vinegar') || s.contains('sauce') || s.contains('ketchup') || s.contains('mustard') || s.contains('mayo')) {
          return FoodCategory.condiments;
        }
        if (s.contains('milk') || s.contains('cheese') || s.contains('yogurt') || s.contains('butter')) {
          return FoodCategory.dairy;
        }
        if (s.contains('rice') || s.contains('pasta') || s.contains('noodle') || s.contains('grain') || s.contains('oats')) {
          return FoodCategory.grains;
        }
        if (s.contains('chicken') || s.contains('beef') || s.contains('pork') || s.contains('tofu') || s.contains('egg')) {
          return FoodCategory.protein;
        }
        if (s.contains('apple') || s.contains('banana') || s.contains('berry') || s.contains('lettuce') || s.contains('spinach') || s.contains('carrot') || s.contains('tomato')) {
          return FoodCategory.produce;
        }
        return FoodCategory.other;
      }

      StorageLocation defaultStorage(FoodCategory c) {
        switch (c) {
          case FoodCategory.produce:
          case FoodCategory.dairy:
          case FoodCategory.protein:
            return StorageLocation.fridge;
          case FoodCategory.frozenFoods:
            return StorageLocation.freezer;
          default:
            return StorageLocation.pantry;
        }
      }

      DateTime computeExpiry(FoodCategory c, StorageLocation s, DateTime purchase) {
        return purchase.add(c.getShelfLife(s));
      }

      final toInsert = <PantryItem>[];
      for (final raw in names) {
        final key = raw.trim().toLowerCase();
        if (existingNames.contains(key)) continue; // skip duplicates
        final cat = guessCategory(raw);
        final loc = defaultStorage(cat);
        toInsert.add(PantryItem(
          name: raw,
          details: null,
          size: null,
          purchaseDate: now,
          expirationDate: computeExpiry(cat, loc, now),
          category: cat,
          storageLocation: loc,
        ));
      }
      if (toInsert.isEmpty) return 0;
      final payload = toInsert.map((i) => _toRow(uid, i)).toList();
      await _client.from('user_pantry').insert(payload);
      developer.log('Merged ${toInsert.length} onboarding pantry items', name: 'PantryService');
      return toInsert.length;
    } catch (e, st) {
      developer.log('importOnboardingPantryMerge failed', error: e, stackTrace: st, name: 'PantryService');
      return 0;
    }
  }
}
