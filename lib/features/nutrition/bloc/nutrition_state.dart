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

  const NutritionFormUpdated({
    required this.image,
    required this.dishes,
    required this.notes,
  });

  @override
  List<Object?> get props => [image, dishes, notes];
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
