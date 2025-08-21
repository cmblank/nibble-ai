import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/shopping_list_item.dart';
import 'supabase_service.dart';

class ShoppingListService {
  final SupabaseClient _client = SupabaseService.client;

  ShoppingListService();

  Future<List<ShoppingListItem>> getShoppingList() async {
    final response = await _client
        .from('shopping_list')
        .select()
        .order('created_at', ascending: false);
    
  return response.map<ShoppingListItem>((item) => ShoppingListItem.fromJson(Map<String,dynamic>.from(item))).toList();
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
      'added_from_receipt': true,
      'created_at': DateTime.now().toIso8601String(),
    }).toList();

  final inserted = await _client
    .from('shopping_list')
    .insert(itemsToAdd)
    .select(); // returns inserted rows including IDs
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
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      final inserted = await _client
        .from('shopping_list')
        .insert(itemToAdd)
        .select()
        .single();
      
      return ShoppingListItem.fromJson(Map<String, dynamic>.from(inserted));
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
        })
    .eq('id', item.id!);
  }
}
