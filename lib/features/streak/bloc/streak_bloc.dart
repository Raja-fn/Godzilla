import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_health/features/streak/bloc/streak_event.dart';
import 'package:ai_health/features/streak/bloc/streak_state.dart';
import 'package:ai_health/features/streak/repo/streak_repo.dart';
import 'package:ai_health/features/streak/models/streak_day.dart';

class StreakBloc extends Bloc<StreakEvent, StreakState> {
  final StreakRepository _repository;

  StreakBloc(this._repository) : super(const StreakInitial()) {
    on<FetchStreakDataEvent>(_onFetchStreakData);
    on<AddPhotoToDayEvent>(_onAddPhotoToDay);
    on<RemovePhotoFromDayEvent>(_onRemovePhotoFromDay);
    on<FetchMonthDataEvent>(_onFetchMonthData);
    on<DeleteStreakDataEvent>(_onDeleteStreakData);
  }

  /// Handle fetching streak data
  Future<void> _onFetchStreakData(
    FetchStreakDataEvent event,
    Emitter<StreakState> emit,
  ) async {
    try {
      emit(const StreakLoading());
      print("HERE-1");
      final streakData = await _repository.getStreakData(event.userId);
      print("HERE0");
      emit(StreakLoaded(streakData: streakData, monthData: {}));
    } catch (e) {
      print(e);
      emit(StreakError('Failed to fetch streak data: $e'));
    }
  }

  /// Handle adding photo to a day
  Future<void> _onAddPhotoToDay(
    AddPhotoToDayEvent event,
    Emitter<StreakState> emit,
  ) async {
    try {
      emit(const StreakLoading());
      // Save photo locally first
      final savedPhotoPath = await _repository.savePhotoLocally(
        event.userId,
        event.photoPath,
      );

      // Add photo to day
      await _repository.addPhotoToDay(event.userId, event.date, savedPhotoPath);
      print("HERE1");
      // Fetch updated streak data
      final updatedStreakData = await _repository.getStreakData(event.userId);
      final updatedDay = updatedStreakData.getDay(event.date);
      print("HERE2");
      if (updatedDay != null) {
        // Emit updated StreakLoaded state
        emit(StreakLoaded(streakData: updatedStreakData, monthData: {}));
        
        // Emitting PhotoAdded can be done if we want to show a snackbar, 
        // BUT it must not replace the view state if the view doesn't handle it.
        // For now, let's just stick to StreakLoaded to ensure UI shows the data.
        // If we want a one-off event, we should use a separate stream or 
        // a "Action" field in StreakLoaded, or rely on listener to diff changes (complex).
        // Simplest fix for "Stuck on loading": Ensure we are in StreakLoaded.
      } else {
         // Should not happen if logic is correct
         emit(const StreakInitial());
      }
    } catch (e) {
      print("HERE7");
      print(e);
      emit(StreakError('Failed to add photo: $e'));
    }
  }

  /// Handle removing photo from a day
  Future<void> _onRemovePhotoFromDay(
    RemovePhotoFromDayEvent event,
    Emitter<StreakState> emit,
  ) async {
    try {
      emit(const StreakLoading());
      await _repository.removePhotoFromDay(
        event.userId,
        event.date,
        event.photoPath,
      );

      final updatedStreakData = await _repository.getStreakData(event.userId);
      final updatedDay = updatedStreakData.getDay(event.date);

      // Ensure we emit the final loaded state with updated data
      emit(StreakLoaded(streakData: updatedStreakData, monthData: {}));
    } catch (e) {
      emit(StreakError('Failed to remove photo: $e'));
    }
  }

  /// Handle fetching month data
  Future<void> _onFetchMonthData(
    FetchMonthDataEvent event,
    Emitter<StreakState> emit,
  ) async {
    try {
      if (state is! StreakLoaded) {
        emit(const StreakLoading());
      }

      final monthData = await _repository.getMonthData(
        event.userId,
        event.month,
      );
      final streakData = await _repository.getStreakData(event.userId);

      emit(StreakLoaded(streakData: streakData, monthData: monthData));
    } catch (e) {
      emit(StreakError('Failed to fetch month data: $e'));
    }
  }

  /// Handle deleting streak data
  Future<void> _onDeleteStreakData(
    DeleteStreakDataEvent event,
    Emitter<StreakState> emit,
  ) async {
    try {
      await _repository.deleteUserStreakData(event.userId);
      await _repository.clearLocalPhotos(event.userId);
      emit(const StreakInitial());
    } catch (e) {
      emit(StreakError('Failed to delete streak data: $e'));
    }
  }
}
