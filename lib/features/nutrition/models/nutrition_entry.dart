import 'package:equatable/equatable.dart';

class NutritionEntry extends Equatable {
  final String id;
  final String userId;
  final String imageUrl;
  final List<DishMetadata> dishes;
  final String notes;
  final DateTime createdAt;

  const NutritionEntry({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.dishes,
    this.notes = '',
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, userId, imageUrl, dishes, notes, createdAt];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'imageUrl': imageUrl,
      'dishes': dishes.map((d) => d.toJson()).toList(),
      'notes': notes,
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
