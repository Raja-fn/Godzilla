import 'package:equatable/equatable.dart';

class NutritionEntry extends Equatable {
  final String id;
  final String userId;
  final String imageUrl;
  final List<DishMetadata> dishes;
  final String notes;
  final DateTime createdAt;
  final DateTime mealTime; // When the meal was eaten
  final NutritionInfo nutritionInfo; // Calculated calories and macros

  const NutritionEntry({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.dishes,
    required this.mealTime,
    required this.nutritionInfo,
    this.notes = '',
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    imageUrl,
    dishes,
    notes,
    createdAt,
    mealTime,
    nutritionInfo,
  ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'imageUrl': imageUrl,
      'dishes': dishes.map((d) => d.toJson()).toList(),
      'notes': notes,
      'mealTime': mealTime.toIso8601String(),
      'nutritionInfo': nutritionInfo.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory NutritionEntry.fromJson(Map<String, dynamic> json) {
    return NutritionEntry(
      id: json['id'] as String,
      userId: json['userId'] as String,
      imageUrl: json['imageUrl'] as String,
      dishes: (json['dishes'] as List)
          .map((d) => DishMetadata.fromJson(d as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String? ?? '',
      mealTime: DateTime.parse(json['mealTime'] as String),
      nutritionInfo: NutritionInfo.fromJson(
        json['nutritionInfo'] as Map<String, dynamic>,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class DishMetadata extends Equatable {
  final String dishName;
  final int numberOfRots;
  final double chawalWeight;
  final List<VegetableMetadata> vegetables;

  const DishMetadata({
    required this.dishName,
    required this.numberOfRots,
    required this.chawalWeight,
    required this.vegetables,
  });

  @override
  List<Object?> get props => [dishName, numberOfRots, chawalWeight, vegetables];

  Map<String, dynamic> toJson() {
    return {
      'dishName': dishName,
      'numberOfRots': numberOfRots,
      'chawalWeight': chawalWeight,
      'vegetables': vegetables.map((v) => v.toJson()).toList(),
    };
  }

  factory DishMetadata.fromJson(Map<String, dynamic> json) {
    return DishMetadata(
      dishName: json['dishName'] as String,
      numberOfRots: json['numberOfRots'] as int,
      chawalWeight: (json['chawalWeight'] as num).toDouble(),
      vegetables: (json['vegetables'] as List)
          .map((v) => VegetableMetadata.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }
}

class VegetableMetadata extends Equatable {
  final String name;
  final double weight;
  final String unit;

  const VegetableMetadata({
    required this.name,
    required this.weight,
    this.unit = 'grams',
  });

  @override
  List<Object?> get props => [name, weight, unit];

  Map<String, dynamic> toJson() {
    return {'name': name, 'weight': weight, 'unit': unit};
  }

  factory VegetableMetadata.fromJson(Map<String, dynamic> json) {
    return VegetableMetadata(
      name: json['name'] as String,
      weight: (json['weight'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'grams',
    );
  }
}

/// Nutrition information calculated from dishes
class NutritionInfo extends Equatable {
  final double calories;
  final double protein; // grams
  final double carbohydrates; // grams
  final double fat; // grams

  const NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
  });

  @override
  List<Object?> get props => [calories, protein, carbohydrates, fat];

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
    };
  }

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    return NutritionInfo(
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbohydrates: (json['carbohydrates'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
    );
  }

  /// Calculate nutrition info from dishes
  static NutritionInfo calculate(List<DishMetadata> dishes) {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (final dish in dishes) {
      // Roti calculations: 1 roti ≈ 100 cal, 3g protein, 20g carbs, 1g fat
      totalCalories += dish.numberOfRots * 100;
      totalProtein += dish.numberOfRots * 3;
      totalCarbs += dish.numberOfRots * 20;
      totalFat += dish.numberOfRots * 1;

      // Chawal (rice) calculations: 1.3 cal/g, 0.025g protein/g, 0.28g carbs/g, 0.003g fat/g
      totalCalories += dish.chawalWeight * 1.3;
      totalProtein += dish.chawalWeight * 0.025;
      totalCarbs += dish.chawalWeight * 0.28;
      totalFat += dish.chawalWeight * 0.003;

      // Vegetables: average 30 cal/100g
      for (final veg in dish.vegetables) {
        final vegCalories = (veg.weight / 100) * 30;
        totalCalories += vegCalories;
        // Rough estimates for vegetables
        totalProtein += (veg.weight / 100) * 1; // ~1g protein per 100g
        totalCarbs += (veg.weight / 100) * 5; // ~5g carbs per 100g
        totalFat += (veg.weight / 100) * 0.2; // ~0.2g fat per 100g
      }
    }

    return NutritionInfo(
      calories: totalCalories,
      protein: totalProtein,
      carbohydrates: totalCarbs,
      fat: totalFat,
    );
  }
}
