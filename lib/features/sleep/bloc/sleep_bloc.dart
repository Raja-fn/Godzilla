import 'package:ai_health/features/sleep/models/sleep_data.dart';
import 'package:ai_health/features/sleep/repo/sleep_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class SleepEvent extends Equatable {
  const SleepEvent();

  @override
  List<Object> get props => [];
}

class LoadSleepHistory extends SleepEvent {}

class AddSleepEntry extends SleepEvent {
  final SleepData data;
  const AddSleepEntry(this.data);

  @override
  List<Object> get props => [data];
}

class DeleteSleepEntry extends SleepEvent {
  final DateTime date;
  const DeleteSleepEntry(this.date);

  @override
  List<Object> get props => [date];
}

// States
enum SleepStatus { initial, loading, success, failure }

class SleepState extends Equatable {
  final SleepStatus status;
  final List<SleepData> history;
  final String? errorMessage;

  const SleepState({
    this.status = SleepStatus.initial,
    this.history = const [],
    this.errorMessage,
  });

  SleepState copyWith({
    SleepStatus? status,
    List<SleepData>? history,
    String? errorMessage,
  }) {
    return SleepState(
      status: status ?? this.status,
      history: history ?? this.history,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, history, errorMessage];
}

// Bloc
class SleepBloc extends Bloc<SleepEvent, SleepState> {
  final SleepRepository _repository;

  SleepBloc({required SleepRepository repository})
      : _repository = repository,
        super(const SleepState()) {
    on<LoadSleepHistory>(_onLoadHistory);
    on<AddSleepEntry>(_onAddEntry);
    on<DeleteSleepEntry>(_onDeleteEntry);
  }

  Future<void> _onLoadHistory(
    LoadSleepHistory event,
    Emitter<SleepState> emit,
  ) async {
    emit(state.copyWith(status: SleepStatus.loading));
    try {
      final history = await _repository.getSleepHistory();
      emit(state.copyWith(
        status: SleepStatus.success,
        history: history,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SleepStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAddEntry(
    AddSleepEntry event,
    Emitter<SleepState> emit,
  ) async {
    try {
      await _repository.saveSleepData(event.data);
      add(LoadSleepHistory()); // Reload history
    } catch (e) {
      emit(state.copyWith(
        status: SleepStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteEntry(
    DeleteSleepEntry event,
    Emitter<SleepState> emit,
  ) async {
    try {
      await _repository.deleteSleepData(event.date);
      add(LoadSleepHistory());
    } catch (e) {
      emit(state.copyWith(
        status: SleepStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
