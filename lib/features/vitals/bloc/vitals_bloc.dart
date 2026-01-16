import 'package:ai_health/features/vitals/models/vital_data.dart';
import 'package:ai_health/features/vitals/repo/vitals_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class VitalsEvent extends Equatable {
  const VitalsEvent();
  @override
  List<Object> get props => [];
}

class LoadVitalsHistory extends VitalsEvent {}

class AddVitalEntry extends VitalsEvent {
  final VitalData data;
  const AddVitalEntry(this.data);
  @override
  List<Object> get props => [data];
}

// States
enum VitalsStatus { initial, loading, success, failure }

class VitalsState extends Equatable {
  final VitalsStatus status;
  final List<VitalData> history;
  final String? errorMessage;

  const VitalsState({
    this.status = VitalsStatus.initial,
    this.history = const [],
    this.errorMessage,
  });

  VitalsState copyWith({
    VitalsStatus? status,
    List<VitalData>? history,
    String? errorMessage,
  }) {
    return VitalsState(
      status: status ?? this.status,
      history: history ?? this.history,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, history, errorMessage];
}

// Bloc
class VitalsBloc extends Bloc<VitalsEvent, VitalsState> {
  final VitalsRepository _repository;

  VitalsBloc({required VitalsRepository repository})
      : _repository = repository,
        super(const VitalsState()) {
    on<LoadVitalsHistory>(_onLoadHistory);
    on<AddVitalEntry>(_onAddEntry);
  }

  Future<void> _onLoadHistory(
    LoadVitalsHistory event,
    Emitter<VitalsState> emit,
  ) async {
    emit(state.copyWith(status: VitalsStatus.loading));
    try {
      final history = await _repository.getVitalsHistory();
      emit(state.copyWith(
        status: VitalsStatus.success,
        history: history,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: VitalsStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAddEntry(
    AddVitalEntry event,
    Emitter<VitalsState> emit,
  ) async {
    try {
      await _repository.saveVitalData(event.data);
      add(LoadVitalsHistory());
    } catch (e) {
      emit(state.copyWith(
        status: VitalsStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
