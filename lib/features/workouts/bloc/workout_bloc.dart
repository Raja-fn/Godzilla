import 'package:ai_health/features/workouts/models/workout_data.dart';
import 'package:ai_health/features/workouts/repo/workout_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class WorkoutEvent extends Equatable {
  const WorkoutEvent();
  @override
  List<Object> get props => [];
}

class LoadWorkoutHistory extends WorkoutEvent {}

class AddWorkoutEntry extends WorkoutEvent {
  final WorkoutData data;
  const AddWorkoutEntry(this.data);
  @override
  List<Object> get props => [data];
}

// States
enum WorkoutStatus { initial, loading, success, failure }

class WorkoutState extends Equatable {
  final WorkoutStatus status;
  final List<WorkoutData> history;
  final String? errorMessage;

  const WorkoutState({
    this.status = WorkoutStatus.initial,
    this.history = const [],
    this.errorMessage,
  });

  WorkoutState copyWith({
    WorkoutStatus? status,
    List<WorkoutData>? history,
    String? errorMessage,
  }) {
    return WorkoutState(
      status: status ?? this.status,
      history: history ?? this.history,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, history, errorMessage];
}

// Bloc
class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  final WorkoutRepository _repository;

  WorkoutBloc({required WorkoutRepository repository})
      : _repository = repository,
        super(const WorkoutState()) {
    on<LoadWorkoutHistory>(_onLoadHistory);
    on<AddWorkoutEntry>(_onAddEntry);
  }

  Future<void> _onLoadHistory(
    LoadWorkoutHistory event,
    Emitter<WorkoutState> emit,
  ) async {
    emit(state.copyWith(status: WorkoutStatus.loading));
    try {
      final history = await _repository.getWorkoutHistory();
      emit(state.copyWith(
        status: WorkoutStatus.success,
        history: history,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: WorkoutStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAddEntry(
    AddWorkoutEntry event,
    Emitter<WorkoutState> emit,
  ) async {
    try {
      await _repository.saveWorkout(event.data);
      add(LoadWorkoutHistory());
    } catch (e) {
      emit(state.copyWith(
        status: WorkoutStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
