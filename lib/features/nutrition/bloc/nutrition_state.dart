import 'dart:io';
import 'package:ai_health/features/nutrition/models/nutrition_entry.dart';
import 'package:equatable/equatable.dart';

abstract class NutritionState extends Equatable {
  const NutritionState();

  @override
  List<Object?> get props => [];
}

class NutritionInitial extends NutritionState {}

class NutritionLoading extends NutritionState {}

class NutritionImageSelectedState extends NutritionState {
  final File selectedImage;

  const NutritionImageSelectedState(this.selectedImage);

  @override
  List<Object?> get props => [selectedImage];
}

class NutritionFormUpdated extends NutritionState {
  final File? image;
  final List<DishMetadata> dishes;
  final String notes;
  final DateTime mealTime;

  const NutritionFormUpdated({
    required this.image,
    required this.dishes,
    required this.notes,
    required this.mealTime,
  });

  @override
  List<Object?> get props => [image, dishes, notes, mealTime];
}

class NutritionSubmitSuccess extends NutritionState {
  final NutritionEntry entry;

  const NutritionSubmitSuccess(this.entry);

  @override
  List<Object?> get props => [entry];
}

class NutritionEntriesFetched extends NutritionState {
  final List<NutritionEntry> entries;

  const NutritionEntriesFetched(this.entries);

  @override
  List<Object?> get props => [entries];
}

class NutritionDeleteSuccess extends NutritionState {
  const NutritionDeleteSuccess();
}

class NutritionError extends NutritionState {
  final String message;

  const NutritionError(this.message);

  @override
  List<Object?> get props => [message];
}

class NutritionMealsLoaded extends NutritionState {
  final List<NutritionEntry> meals;
  final DateTime date;
  final NutritionInfo? dailyNutrition;

  const NutritionMealsLoaded({
    required this.meals,
    required this.date,
    this.dailyNutrition,
  });

  @override
  List<Object?> get props => [meals, date, dailyNutrition];
}

class NutritionMealAdded extends NutritionState {
  final NutritionEntry entry;

  const NutritionMealAdded(this.entry);

  @override
  List<Object?> get props => [entry];
}

class NutritionMealDeleted extends NutritionState {
  const NutritionMealDeleted();
}
