import 'dart:io';
import 'package:ai_health/features/nutrition/models/nutrition_entry.dart';
import 'package:equatable/equatable.dart';

abstract class NutritionEvent extends Equatable {
  const NutritionEvent();

  @override
  List<Object> get props => [];
}

class NutritionImageSelected extends NutritionEvent {
  final File imageFile;

  const NutritionImageSelected(this.imageFile);

  @override
  List<Object> get props => [imageFile];
}

class NutritionAddDish extends NutritionEvent {
  final DishMetadata dish;

  const NutritionAddDish(this.dish);

  @override
  List<Object> get props => [dish];
}

class NutritionRemoveDish extends NutritionEvent {
  final int index;

  const NutritionRemoveDish(this.index);

  @override
  List<Object> get props => [index];
}

class NutritionAddVegetable extends NutritionEvent {
  final int dishIndex;
  final VegetableMetadata vegetable;

  const NutritionAddVegetable(this.dishIndex, this.vegetable);

  @override
  List<Object> get props => [dishIndex, vegetable];
}

class NutritionRemoveVegetable extends NutritionEvent {
  final int dishIndex;
  final int vegetableIndex;

  const NutritionRemoveVegetable(this.dishIndex, this.vegetableIndex);

  @override
  List<Object> get props => [dishIndex, vegetableIndex];
}

class NutritionUpdateNotes extends NutritionEvent {
  final String notes;

  const NutritionUpdateNotes(this.notes);

  @override
  List<Object> get props => [notes];
}

class NutritionSubmit extends NutritionEvent {
  final String userId;

  const NutritionSubmit(this.userId);

  @override
  List<Object> get props => [userId];
}

class NutritionFetchEntries extends NutritionEvent {
  final String userId;

  const NutritionFetchEntries(this.userId);

  @override
  List<Object> get props => [userId];
}

class NutritionDeleteEntry extends NutritionEvent {
  final String entryId;

  const NutritionDeleteEntry(this.entryId);

  @override
  List<Object> get props => [entryId];
}

class NutritionReset extends NutritionEvent {}

class NutritionUpdateMealTime extends NutritionEvent {
  final DateTime mealTime;

  const NutritionUpdateMealTime(this.mealTime);

  @override
  List<Object> get props => [mealTime];
}

class NutritionFetchMealsForDate extends NutritionEvent {
  final String userId;
  final DateTime date;

  const NutritionFetchMealsForDate(this.userId, this.date);

  @override
  List<Object> get props => [userId, date];
}

class NutritionDeleteMeal extends NutritionEvent {
  final String userId;
  final String mealId;

  const NutritionDeleteMeal(this.userId, this.mealId);

  @override
  List<Object> get props => [userId, mealId];
}
