import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/nutrition_entry.dart';

class NutritionRepository {
  static const String baseUrl = 'http://localhost:3000/api';

  /// Submit nutrition entry with image and metadata
  /// This sends a multipart request with the image file and JSON metadata
  Future<NutritionEntry> submitNutritionEntry({
    required File imageFile,
    required String userId,
    required List<DishMetadata> dishes,
    required String notes,
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

      // Create the nutrition data JSON
      final nutritionData = {
        'userId': userId,
        'dishes': dishes.map((d) => d.toJson()).toList(),
        'notes': notes,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Add the nutrition data as a field
      request.fields['nutritionData'] = jsonEncode(nutritionData);

      // Send the request
      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = await response.stream.bytesToString();
        final jsonData = jsonDecode(responseBody) as Map<String, dynamic>;

        // Mock: In real scenario, backend will return the created entry
        return NutritionEntry(
          id:
              jsonData['id'] ??
              'nutrition_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          imageUrl: jsonData['imageUrl'] ?? 'mock_url',
          dishes: dishes,
          notes: notes,
          createdAt: DateTime.now(),
        );
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
  /// Simulates a server response with a delay
  Future<NutritionEntry> mockSubmitNutritionEntry({
    required File imageFile,
    required String userId,
    required List<DishMetadata> dishes,
    required String notes,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    return NutritionEntry(
      id: 'nutrition_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      imageUrl: 'file://${imageFile.path}',
      dishes: dishes,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }
}
