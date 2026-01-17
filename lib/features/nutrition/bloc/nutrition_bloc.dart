import 'package:ai_health/features/nutrition/bloc/nutrition_event.dart';
import 'package:ai_health/features/nutrition/bloc/nutrition_state.dart';
import 'package:bloc/bloc.dart';
import 'dart:io';
import '../models/nutrition_entry.dart';
import '../repo/nutrition_repo.dart';
import 'dart:developer' as developer;

class NutritionBloc extends Bloc<NutritionEvent, NutritionState> {
  final NutritionRepository repository;

  File? _selectedImage;
  final List<DishMetadata> _dishes = [];
  String _notes = '';
  DateTime _mealTime = DateTime.now();

  NutritionBloc({required this.repository}) : super(NutritionInitial()) {
    on<NutritionImageSelected>(_onImageSelected);
    on<NutritionAddDish>(_onAddDish);
    on<NutritionRemoveDish>(_onRemoveDish);
    on<NutritionAddVegetable>(_onAddVegetable);
    on<NutritionRemoveVegetable>(_onRemoveVegetable);
    on<NutritionUpdateNotes>(_onUpdateNotes);
    on<NutritionUpdateMealTime>(_onUpdateMealTime);
    on<NutritionSubmit>(_onSubmit);
    on<NutritionFetchMealsForDate>(_onFetchMealsForDate);
    on<NutritionDeleteMeal>(_onDeleteMeal);
    on<NutritionReset>(_onReset);
  }

  Future<void> _onImageSelected(
    NutritionImageSelected event,
    Emitter<NutritionState> emit,
  ) async {
    _selectedImage = event.imageFile;
    emit(NutritionImageSelectedState(_selectedImage!));
  }

  Future<void> _onAddDish(
    NutritionAddDish event,
    Emitter<NutritionState> emit,
  ) async {
    _dishes.add(event.dish);
    emit(
      NutritionFormUpdated(
        image: _selectedImage,
        dishes: List.unmodifiable(_dishes),
        notes: _notes,
        mealTime: _mealTime,
      ),
    );
  }

  Future<void> _onRemoveDish(
    NutritionRemoveDish event,
    Emitter<NutritionState> emit,
  ) async {
    if (event.index >= 0 && event.index < _dishes.length) {
      _dishes.removeAt(event.index);
      emit(
        NutritionFormUpdated(
          image: _selectedImage,
          dishes: List.unmodifiable(_dishes),
          notes: _notes,
          mealTime: _mealTime,
        ),
      );
    }
  }

  Future<void> _onAddVegetable(
    NutritionAddVegetable event,
    Emitter<NutritionState> emit,
  ) async {
    if (event.dishIndex >= 0 && event.dishIndex < _dishes.length) {
      final dish = _dishes[event.dishIndex];
      final updatedVegetables = [...dish.vegetables, event.vegetable];
      final updatedDish = DishMetadata(
        dishName: dish.dishName,
        numberOfRots: dish.numberOfRots,
        chawalWeight: dish.chawalWeight,
        vegetables: updatedVegetables,
      );
      _dishes[event.dishIndex] = updatedDish;
      emit(
        NutritionFormUpdated(
          image: _selectedImage,
          dishes: List.unmodifiable(_dishes),
          notes: _notes,
          mealTime: _mealTime,
        ),
      );
    }
  }

  Future<void> _onRemoveVegetable(
    NutritionRemoveVegetable event,
    Emitter<NutritionState> emit,
  ) async {
    if (event.dishIndex >= 0 && event.dishIndex < _dishes.length) {
      final dish = _dishes[event.dishIndex];
      final updatedVegetables = [...dish.vegetables];
      if (event.vegetableIndex >= 0 &&
          event.vegetableIndex < updatedVegetables.length) {
        updatedVegetables.removeAt(event.vegetableIndex);
        final updatedDish = DishMetadata(
          dishName: dish.dishName,
          numberOfRots: dish.numberOfRots,
          chawalWeight: dish.chawalWeight,
          vegetables: updatedVegetables,
        );
        _dishes[event.dishIndex] = updatedDish;
        emit(
          NutritionFormUpdated(
            image: _selectedImage,
            dishes: List.unmodifiable(_dishes),
            notes: _notes,
            mealTime: _mealTime,
          ),
        );
      }
    }
  }

  Future<void> _onUpdateNotes(
    NutritionUpdateNotes event,
    Emitter<NutritionState> emit,
  ) async {
    _notes = event.notes;
    emit(
      NutritionFormUpdated(
        image: _selectedImage,
        dishes: List.unmodifiable(_dishes),
        notes: _notes,
        mealTime: _mealTime,
      ),
    );
  }

  Future<void> _onUpdateMealTime(
    NutritionUpdateMealTime event,
    Emitter<NutritionState> emit,
  ) async {
    _mealTime = event.mealTime;
    emit(
      NutritionFormUpdated(
        image: _selectedImage,
        dishes: List.unmodifiable(_dishes),
        notes: _notes,
        mealTime: _mealTime,
      ),
    );
  }

  Future<void> _onSubmit(
    NutritionSubmit event,
    Emitter<NutritionState> emit,
  ) async {
    if (_selectedImage == null || _dishes.isEmpty) {
      emit(
        const NutritionError(
          'Please select an image and add at least one dish',
        ),
      );
      return;
    }

    emit(NutritionLoading());
    try {
      // Using mock submit for now
      final entry = await repository.mockSubmitNutritionEntry(
        imageFile: _selectedImage!,
        userId: event.userId,
        dishes: _dishes,
        notes: _notes,
        mealTime: _mealTime,
      );

      emit(NutritionMealAdded(entry));
      _resetForm();
    } catch (e) {
      developer.log('Error submitting nutrition: $e', error: e);
      emit(NutritionError(e.toString()));
    }
  }

  Future<void> _onFetchMealsForDate(
    NutritionFetchMealsForDate event,
    Emitter<NutritionState> emit,
  ) async {
    emit(NutritionLoading());
    try {
      final meals = await repository.getMealsForDate(event.userId, event.date);

      // Also fetch daily nutrition totals
      final dailyNutrition = await repository.getDailyNutrition(
        event.userId,
        event.date,
      );

      developer.log('Fetched ${meals.length} meals for ${event.date}');
      emit(
        NutritionMealsLoaded(
          meals: meals,
          date: event.date,
          dailyNutrition: dailyNutrition,
        ),
      );
    } catch (e) {
      developer.log('Error fetching meals: $e', error: e);
      emit(NutritionError(e.toString()));
    }
  }

  Future<void> _onDeleteMeal(
    NutritionDeleteMeal event,
    Emitter<NutritionState> emit,
  ) async {
    emit(NutritionLoading());
    try {
      await repository.deleteMeal(event.userId, event.mealId);
      emit(const NutritionMealDeleted());
    } catch (e) {
      developer.log('Error deleting meal: $e', error: e);
      emit(NutritionError(e.toString()));
    }
  }

  Future<void> _onReset(
    NutritionReset event,
    Emitter<NutritionState> emit,
  ) async {
    _resetForm();
    emit(NutritionInitial());
  }

  void _resetForm() {
    _selectedImage = null;
    _dishes.clear();
    _notes = '';
    _mealTime = DateTime.now();
  }
}
