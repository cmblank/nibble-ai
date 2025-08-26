import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/shopping_list_item.dart';
import 'supabase_service.dart';
import 'household_service.dart';

class ShoppingListService {
  final SupabaseClient _client = SupabaseService.client;

  ShoppingListService();

  Future<List<ShoppingListItem>> getShoppingList({bool mergeDuplicates = false}) async {
    final user = SupabaseService.currentUser;
    var builder = _client.from('shopping_list').select();
    if (user != null) {
      final hid = await HouseholdService.ensureHousehold();
      if (hid == null) return [];
      builder = builder.eq('household_id', hid);
    }
    final response = await builder.order('created_at', ascending: false);
    final list = response.map<ShoppingListItem>((item) => ShoppingListItem.fromJson(Map<String,dynamic>.from(item))).toList();
    if (!mergeDuplicates) return list;

    return _mergeWithConversions(list);
  }

  Future<List<ShoppingListItem>> addItems(List<ShoppingListItem> items) async {
  final user = SupabaseService.currentUser;
  if (user == null) throw Exception('User not authenticated');

    final itemsToAdd = items.map((item) => {
      'name': item.name,
      'quantity': item.quantity,
      'unit': item.unit,
      'category': item.category,
  'user_id': user.id,
  'source': item.source,
  'note': item.note,
  'is_purchased': false,
  'created_at': DateTime.now().toIso8601String(),
    }).toList();

  final hid = await HouseholdService.ensureHousehold();
  if (hid == null) { throw Exception('Household not established'); }
  for (final m in itemsToAdd) { m['household_id'] = hid; m['added_by'] = user.id; }
  final inserted = await _client.from('shopping_list').insert(itemsToAdd).select();
  return (inserted as List)
    .map((row) => ShoppingListItem.fromJson(Map<String, dynamic>.from(row)))
    .toList();
  }

  Future<ShoppingListItem?> addItem(ShoppingListItem item) async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('User not authenticated');

  final itemToAdd = {
      'name': item.name,
      'quantity': item.quantity,
      'unit': item.unit,
      'category': item.category,
      'user_id': user.id,
      'source': item.source,
      'note': item.note,
  'is_purchased': item.isChecked,
      'created_at': DateTime.now().toIso8601String(),
    };
  final hid = await HouseholdService.ensureHousehold();
  if (hid == null) { throw Exception('Household not established'); }
  itemToAdd['household_id'] = hid; itemToAdd['added_by'] = user.id;

    try {
      final rows = await _client
        .from('shopping_list')
        .insert(itemToAdd)
        .select()
        .limit(1);
      if (rows.isNotEmpty) {
        return ShoppingListItem.fromJson(Map<String,dynamic>.from(rows.first));
      }
      return null;
    } catch (e) {
      debugPrint('Error adding item to shopping list: $e');
      return null;
    }
  }

  Future<void> removeItem(int itemId) async {
    await _client.from('shopping_list').delete().eq('id', itemId);
  }

  Future<void> updateItem(ShoppingListItem item) async {
  if (item.id == null) throw ArgumentError('Cannot update item without id');
    await _client
        .from('shopping_list')
        .update({
          'name': item.name,
          'quantity': item.quantity,
          'unit': item.unit,
          'category': item.category,
          'is_purchased': item.isChecked,
          'note': item.note,
          'source': item.source,
        })
    .eq('id', item.id!);
  }

  Future<void> togglePurchased(int id, bool purchased) async {
    await _client
        .from('shopping_list')
        .update({'is_purchased': purchased})
        .eq('id', id);
  }

  Future<int> clearPurchased() async {
    final deleted = await _client
        .from('shopping_list')
        .delete()
        .eq('is_purchased', true)
        .select();
    return (deleted as List).length;
  }

  // --- Merging / Unit Conversion Logic ---
  List<ShoppingListItem> _mergeWithConversions(List<ShoppingListItem> items) {
    // Key: name|category|group
    final Map<String, _MergedBucket> buckets = {};
    for (final item in items) {
      final nameKey = item.name.toLowerCase().trim();
      final category = item.category;
      final conv = _convertToCanonical(item.quantity, item.unit.toLowerCase());
      final key = '$nameKey|$category|${conv.group}';
      final bucket = buckets.putIfAbsent(key, () => _MergedBucket(name: item.name, category: category, group: conv.group));
      bucket.baseQuantity += conv.baseQuantity;
      bucket.sources.add(item.source);
      bucket.notes.add(item.note);
      bucket.originalUnits.add(item.unit.toLowerCase());
    }

    final results = <ShoppingListItem>[];
    for (final b in buckets.values) {
      final display = _canonicalToDisplay(b.baseQuantity, b.group);
      final source = b.sources.length == 1 ? b.sources.first : 'mixed';
      final note = b.notes.whereType<String>().join(' | ');
      results.add(ShoppingListItem(
        name: b.name,
        category: b.category,
        quantity: display.quantity,
        unit: display.unit,
        source: source,
        note: note.isEmpty ? null : note,
      ));
    }
    results.sort((a,b)=> a.category == b.category ? a.name.compareTo(b.name) : a.category.compareTo(b.category));
    return results;
  }

  _CanonicalConversion _convertToCanonical(double quantity, String unit) {
    if (unit.isEmpty) {
      return _CanonicalConversion(group: 'each', baseQuantity: quantity);
    }
    // Volume (spoons/cups) -> base tsp
    const volSpoonFactors = {'tsp':1.0, 'tbsp':3.0, 'cup':48.0};
    if (volSpoonFactors.containsKey(unit)) {
      return _CanonicalConversion(group: 'vol_tsp', baseQuantity: quantity * volSpoonFactors[unit]!);
    }
    // Metric volume -> base ml
    const volMetricFactors = {'ml':1.0, 'l':1000.0};
    if (volMetricFactors.containsKey(unit)) {
      return _CanonicalConversion(group: 'vol_ml', baseQuantity: quantity * volMetricFactors[unit]!);
    }
    // Mass -> base g (accept imperial)
    const massFactors = {'g':1.0, 'kg':1000.0, 'oz':28.3495, 'lb':453.592};
    if (massFactors.containsKey(unit)) {
      return _CanonicalConversion(group: 'mass_g', baseQuantity: quantity * massFactors[unit]!);
    }
    // Fallback: treat as each with unit label preserved later
    return _CanonicalConversion(group: 'unit:$unit', baseQuantity: quantity, passthroughUnit: unit);
  }

  _DisplayQuantity _canonicalToDisplay(double baseQty, String group) {
    switch(group) {
      case 'vol_tsp':
        if (baseQty >= 48) { // cups
          return _DisplayQuantity(quantity: baseQty/48.0, unit: 'cup');
        } else if (baseQty >= 3) { // tbsp
          return _DisplayQuantity(quantity: baseQty/3.0, unit: 'tbsp');
        }
        return _DisplayQuantity(quantity: baseQty, unit: 'tsp');
      case 'vol_ml':
        if (baseQty >= 1000) {
          return _DisplayQuantity(quantity: baseQty/1000.0, unit: 'L');
        }
        return _DisplayQuantity(quantity: baseQty, unit: 'ml');
      case 'mass_g':
        if (baseQty >= 1000) {
          return _DisplayQuantity(quantity: baseQty/1000.0, unit: 'kg');
        } else if (baseQty >= 453.592) {
          return _DisplayQuantity(quantity: baseQty/453.592, unit: 'lb');
        } else if (baseQty >= 28.3495) {
          return _DisplayQuantity(quantity: baseQty/28.3495, unit: 'oz');
        }
        return _DisplayQuantity(quantity: baseQty, unit: 'g');
      default:
        if (group.startsWith('unit:')) {
          return _DisplayQuantity(quantity: baseQty, unit: group.substring(5));
        }
        return _DisplayQuantity(quantity: baseQty, unit: '');
    }
  }
}

class _CanonicalConversion {
  final String group; // e.g., vol_tsp, vol_ml, mass_g, each, unit:xyz
  final double baseQuantity;
  final String? passthroughUnit;
  _CanonicalConversion({required this.group, required this.baseQuantity, this.passthroughUnit});
}

class _DisplayQuantity {
  final double quantity;
  final String unit;
  _DisplayQuantity({required this.quantity, required this.unit});
}

class _MergedBucket {
  final String name;
  final String category;
  final String group;
  double baseQuantity = 0;
  final Set<String> sources = {};
  final Set<String?> notes = {};
  final Set<String> originalUnits = {};
  _MergedBucket({required this.name, required this.category, required this.group});
}
