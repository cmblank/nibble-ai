import 'dart:developer' as developer;
import '../services/supabase_service.dart';

class NibbleFunctions {
  // Helper to get current user ID
  static String? get _currentUserId => SupabaseService.currentUser?.id;

  // Log user's mood for daily check-ins
  static Future<bool> logMood({
    required String mood,
    int? energyLevel,
    String? notes,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final response = await SupabaseService.saveDailyCheckIn(
        userId: userId,
        mood: mood,
        checkInData: {
          'energy_level': energyLevel,
          'notes': notes,
          'check_in_type': 'mood',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      return response;
    } catch (e) {
  developer.log('Error logging mood', error: e, name: 'NibbleFunctions');
      return false;
    }
  }

  // Get user's current pantry items
  static Future<List<Map<String, dynamic>>> getPantry() async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      return await SupabaseService.getUserPantryItems(userId);
    } catch (e) {
  developer.log('Error getting pantry', error: e, name: 'NibbleFunctions');
      return [];
    }
  }

  // Add item to pantry
  static Future<bool> addToPantry({
    required String itemName,
    String? category,
    String? quantity,
    DateTime? expiryDate,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final response = await SupabaseService.addPantryItem(
        userId: userId,
        itemName: itemName,
        expiryDate: expiryDate ?? DateTime.now().add(const Duration(days: 7)),
      );
      return response;
    } catch (e) {
  developer.log('Error adding to pantry', error: e, name: 'NibbleFunctions');
      return false;
    }
  }

  // Suggest meals based on user preferences and pantry
  static Future<List<Map<String, dynamic>>> suggestMeals({
    List<String>? dietaryRestrictions,
    List<String>? preferredCuisines,
    int? cookingTime,
    String? mealType,
  }) async {
    try {
      // Get user's pantry items (for future pantry-based suggestions)
      // final pantryItems = await getPantry();
      
      // For now, return sample recipes that match criteria
      // In production, this would query your recipes database
      final allRecipes = await _getSampleRecipes();
      
      return allRecipes.where((recipe) {
        // Filter by dietary restrictions
        if (dietaryRestrictions != null) {
          final recipeTags = List<String>.from(recipe['tags'] ?? []);
          if (!dietaryRestrictions.every((restriction) => 
              recipeTags.contains(restriction))) {
            return false;
          }
        }

        // Filter by cuisine preference
        if (preferredCuisines != null) {
          final recipeCuisine = recipe['cuisine'] as String?;
          if (recipeCuisine != null && 
              !preferredCuisines.contains(recipeCuisine)) {
            return false;
          }
        }

        // Filter by cooking time
        if (cookingTime != null) {
          final recipeTime = recipe['cooking_time_minutes'] as int?;
          if (recipeTime != null && recipeTime > cookingTime) {
            return false;
          }
        }

        // Filter by meal type
        if (mealType != null) {
          final recipeMealType = recipe['meal_type'] as String?;
          if (recipeMealType != mealType) {
            return false;
          }
        }

        return true;
      }).toList();
    } catch (e) {
  developer.log('Error suggesting meals', error: e, name: 'NibbleFunctions');
      return [];
    }
  }

  // Log cooking activity
  static Future<bool> logCookingActivity({
    required String recipeId,
    required String recipeName,
    int? rating,
    String? notes,
    List<String>? modifications,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final response = await SupabaseService.saveDailyCheckIn(
        userId: userId,
        mood: 'cooking', // Use cooking as mood indicator
        checkInData: {
          'check_in_type': 'cooking',
          'recipe_id': recipeId,
          'recipe_name': recipeName,
          'rating': rating,
          'notes': notes,
          'modifications': modifications,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      return response;
    } catch (e) {
  developer.log('Error logging cooking activity', error: e, name: 'NibbleFunctions');
      return false;
    }
  }

  // Get user's cooking streak
  static Future<int> getCookingStreak() async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final checkIns = await SupabaseService.getUserDailyCheckIns(userId);
      
      // Filter cooking activities
      final cookingActivities = checkIns
          .where((checkIn) => 
              checkIn['check_in_data'] != null &&
              checkIn['check_in_data']['check_in_type'] == 'cooking')
          .toList();

      if (cookingActivities.isEmpty) return 0;

      // Sort by date (most recent first)
      cookingActivities.sort((a, b) => 
          DateTime.parse(b['created_at'])
              .compareTo(DateTime.parse(a['created_at'])));

      int streak = 0;
      DateTime currentDate = DateTime.now();
      
      for (final activity in cookingActivities) {
        final activityDate = DateTime.parse(activity['created_at']);
        final daysDifference = currentDate.difference(activityDate).inDays;
        
        if (daysDifference == streak) {
          streak++;
          currentDate = activityDate;
        } else {
          break;
        }
      }
      
      return streak;
    } catch (e) {
  developer.log('Error getting cooking streak', error: e, name: 'NibbleFunctions');
      return 0;
    }
  }

  // Get user preferences from profile
  static Future<Map<String, dynamic>?> getUserPreferences() async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      return await SupabaseService.getUserProfile(userId);
    } catch (e) {
  developer.log('Error getting user preferences', error: e, name: 'NibbleFunctions');
      return null;
    }
  }

  // Sample recipes for demonstration
  static Future<List<Map<String, dynamic>>> _getSampleRecipes() async {
    return [
      {
        'id': '1',
        'name': 'Mediterranean Chickpea Salad',
        'cuisine': 'Mediterranean',
        'meal_type': 'lunch',
        'cooking_time_minutes': 15,
        'tags': ['vegetarian', 'vegan', 'gluten-free'],
        'ingredients': ['chickpeas', 'cucumber', 'tomatoes', 'olive oil'],
        'difficulty': 'easy',
      },
      {
        'id': '2',
        'name': 'Thai Green Curry',
        'cuisine': 'Thai',
        'meal_type': 'dinner',
        'cooking_time_minutes': 30,
        'tags': ['gluten-free'],
        'ingredients': ['coconut milk', 'green curry paste', 'chicken', 'vegetables'],
        'difficulty': 'medium',
      },
      {
        'id': '3',
        'name': 'Italian Pasta Primavera',
        'cuisine': 'Italian',
        'meal_type': 'dinner',
        'cooking_time_minutes': 25,
        'tags': ['vegetarian'],
        'ingredients': ['pasta', 'zucchini', 'bell peppers', 'parmesan'],
        'difficulty': 'easy',
      },
      {
        'id': '4',
        'name': 'Mexican Black Bean Tacos',
        'cuisine': 'Mexican',
        'meal_type': 'lunch',
        'cooking_time_minutes': 20,
        'tags': ['vegetarian', 'vegan'],
        'ingredients': ['black beans', 'corn tortillas', 'avocado', 'lime'],
        'difficulty': 'easy',
      },
      {
        'id': '5',
        'name': 'Japanese Miso Soup',
        'cuisine': 'Japanese',
        'meal_type': 'breakfast',
        'cooking_time_minutes': 10,
        'tags': ['vegetarian', 'vegan', 'low-carb'],
        'ingredients': ['miso paste', 'tofu', 'seaweed', 'scallions'],
        'difficulty': 'easy',
      },
    ];
  }
}
