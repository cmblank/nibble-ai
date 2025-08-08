import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  
  // Getter for the Supabase client
  static SupabaseClient get client => _client;
  
  // Authentication methods
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }
  
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
  
  // Get current user
  static User? get currentUser => _client.auth.currentUser;
  
  // Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;
  
  // User profile methods (example)
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }
  
  static Future<bool> updateUserProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _client
          .from('profiles')
          .update(data)
          .eq('id', userId);
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }
  
  // Cooking data methods (examples for your app)
  static Future<List<Map<String, dynamic>>> getUserRecipes(String userId) async {
    try {
      final response = await _client
          .from('user_recipes')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching user recipes: $e');
      return [];
    }
  }
  
  static Future<bool> saveUserRecipe({
    required String userId,
    required Map<String, dynamic> recipeData,
  }) async {
    try {
      await _client
          .from('user_recipes')
          .insert({
        'user_id': userId,
        ...recipeData,
      });
      return true;
    } catch (e) {
      print('Error saving user recipe: $e');
      return false;
    }
  }
  
  // Daily check-in methods
  static Future<bool> saveDailyCheckIn({
    required String userId,
    required String mood,
    required Map<String, dynamic> checkInData,
  }) async {
    try {
      await _client
          .from('daily_checkins')
          .insert({
        'user_id': userId,
        'mood': mood,
        'check_in_data': checkInData,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error saving daily check-in: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserDailyCheckIns(String userId) async {
    try {
      final response = await _client
          .from('daily_checkins')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching daily check-ins: $e');
      return [];
    }
  }
  
  // Pantry management methods
  static Future<List<Map<String, dynamic>>> getUserPantryItems(String userId) async {
    try {
      final response = await _client
          .from('user_pantry')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching pantry items: $e');
      return [];
    }
  }
  
  static Future<bool> addPantryItem({
    required String userId,
    required String itemName,
    required DateTime expiryDate,
  }) async {
    try {
      await _client
          .from('user_pantry')
          .insert({
        'user_id': userId,
        'item_name': itemName,
        'expiry_date': expiryDate.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error adding pantry item: $e');
      return false;
    }
  }
  
  // Real-time subscriptions (example)
  static RealtimeChannel subscribeToUserData(String userId, Function(Map<String, dynamic>) onData) {
    return _client
        .channel('user_data_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) {
            onData(payload.newRecord);
          },
        )
        .subscribe();
  }
}
