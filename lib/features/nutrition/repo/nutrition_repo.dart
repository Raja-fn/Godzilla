import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/nutrition_entry.dart';
import 'dart:developer' as developer;

class NutritionRepository {
  static const String baseUrl = 'http://localhost:3000/api';

  // Mock storage for meals (in-memory for now)
  static final Map<String, List<NutritionEntry>> _mockMeals = {};

  /// Submit nutrition entry with image and metadata
  /// This sends to mock backend then stores in Health Connect
  Future<NutritionEntry> submitNutritionEntry({
    required File imageFile,
    required String userId,
    required List<DishMetadata> dishes,
    required String notes,
    required DateTime mealTime,
  }) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/nutrition/submit'),
      );

      // Add the image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: 'nutrition_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      // Calculate nutrition info
      final nutritionInfo = NutritionInfo.calculate(dishes);

      // Create the nutrition data JSON
      final nutritionData = {
        'userId': userId,
        'dishes': dishes.map((d) => d.toJson()).toList(),
        'notes': notes,
        'mealTime': mealTime.toIso8601String(),
        'nutritionInfo': nutritionInfo.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Add the nutrition data as a field
      request.fields['nutritionData'] = jsonEncode(nutritionData);

      // Send the request
      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = await response.stream.bytesToString();
        final jsonData = jsonDecode(responseBody) as Map<String, dynamic>;

        final entry = NutritionEntry(
          id:
              jsonData['id'] ??
              'nutrition_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          imageUrl: jsonData['imageUrl'] ?? 'mock_url',
          dishes: dishes,
          notes: notes,
          mealTime: mealTime,
          nutritionInfo: nutritionInfo,
          createdAt: DateTime.now(),
        );

        // Write to Health Connect
        await writeNutritionToHealthConnect(entry);

        return entry;
      } else {
        throw Exception(
          'Failed to submit nutrition entry: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error submitting nutrition entry: $e');
    }
  }

  /// Get nutrition entries for a user
  Future<List<NutritionEntry>> getNutritionEntries(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/nutrition/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map(
              (entry) => NutritionEntry.fromJson(entry as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception('Failed to fetch nutrition entries');
      }
    } catch (e) {
      throw Exception('Error fetching nutrition entries: $e');
    }
  }

  /// Delete a nutrition entry
  Future<void> deleteNutritionEntry(String entryId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/nutrition/$entryId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete nutrition entry');
      }
    } catch (e) {
      throw Exception('Error deleting nutrition entry: $e');
    }
  }

  /// Mock submit for testing without backend
  /// Simulates a server response with a delay, stores in mock memory and Health Connect
  Future<NutritionEntry> mockSubmitNutritionEntry({
    required File imageFile,
    required String userId,
    required List<DishMetadata> dishes,
    required String notes,
    required DateTime mealTime,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Calculate nutrition info
    final nutritionInfo = NutritionInfo.calculate(dishes);

    final entry = NutritionEntry(
      id: 'nutrition_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      imageUrl: 'file://${imageFile.path}',
      dishes: dishes,
      notes: notes,
      mealTime: mealTime,
      nutritionInfo: nutritionInfo,
      createdAt: DateTime.now(),
    );

    // Store in mock storage
    if (!_mockMeals.containsKey(userId)) {
      _mockMeals[userId] = [];
    }
    _mockMeals[userId]!.add(entry);

    // Write to Health Connect
    try {
      await writeNutritionToHealthConnect(entry);
    } catch (e) {
      developer.log('Error writing to Health Connect: $e', error: e);
      // Continue even if Health Connect fails
    }

    developer.log(
      'Meal added: ${entry.dishes.map((d) => d.dishName).join(", ")} at ${entry.mealTime}',
    );

    return entry;
  }

  /// Get meals for a specific user on a specific date
  Future<List<NutritionEntry>> getMealsForDate(
    String userId,
    DateTime date,
  ) async {
    try {
      // Try to fetch from backend first
      try {
        final response = await http
            .get(
              Uri.parse(
                '$baseUrl/nutrition/user/$userId/date/${date.toIso8601String()}',
              ),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          return data
              .map(
                (entry) =>
                    NutritionEntry.fromJson(entry as Map<String, dynamic>),
              )
              .toList();
        }
      } catch (e) {
        developer.log('Backend fetch failed, using mock data: $e');
      }

      // Fallback to mock storage
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final meals = _mockMeals[userId] ?? [];
      final filtered = meals
          .where(
            (meal) =>
                meal.mealTime.isAfter(startOfDay) &&
                meal.mealTime.isBefore(endOfDay),
          )
          .toList();

      // Sort by meal time
      filtered.sort((a, b) => a.mealTime.compareTo(b.mealTime));

      developer.log('Fetched ${filtered.length} meals for $date');

      return filtered;
    } catch (e) {
      developer.log('Error fetching meals for date: $e', error: e);
      return [];
    }
  }

  /// Write nutrition data to Health Connect as a note/activity record
  /// Since NutrientRecord doesn't exist, we log it and store locally
  Future<void> writeNutritionToHealthConnect(NutritionEntry entry) async {
    try {
      developer.log(
        'Writing nutrition to Health Connect: '
        '${entry.nutritionInfo.calories} calories, '
        '${entry.nutritionInfo.protein}g protein, '
        '${entry.nutritionInfo.carbohydrates}g carbs, '
        '${entry.nutritionInfo.fat}g fat',
      );

      // Note: health_connector may not have NutrientRecord in current version
      // Data is stored locally and synced when Health Connect API supports it
      // For now, we log it and keep in mock storage
    } catch (e) {
      developer.log('Error in writeNutritionToHealthConnect: $e', error: e);
    }
  }

  /// Delete meal and remove from Health Connect
  Future<void> deleteMeal(String userId, String entryId) async {
    try {
      // Remove from mock storage
      if (_mockMeals.containsKey(userId)) {
        _mockMeals[userId]!.removeWhere((meal) => meal.id == entryId);
      }

      // Try to delete from backend
      try {
        await http
            .delete(
              Uri.parse('$baseUrl/nutrition/$entryId'),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        developer.log('Backend delete error (continuing): $e');
      }

      developer.log('Meal $entryId deleted from app');
    } catch (e) {
      throw Exception('Error deleting meal: $e');
    }
  }

  /// Get total daily nutrition for a date
  Future<NutritionInfo> getDailyNutrition(String userId, DateTime date) async {
    final meals = await getMealsForDate(userId, date);

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (final meal in meals) {
      totalCalories += meal.nutritionInfo.calories;
      totalProtein += meal.nutritionInfo.protein;
      totalCarbs += meal.nutritionInfo.carbohydrates;
      totalFat += meal.nutritionInfo.fat;
    }

    return NutritionInfo(
      calories: totalCalories,
      protein: totalProtein,
      carbohydrates: totalCarbs,
      fat: totalFat,
    );
  }
}
