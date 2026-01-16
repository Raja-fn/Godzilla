import 'package:ai_health/features/meditation/data/meditation_item.dart';
import 'package:ai_health/features/meditation/data/meditation_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class MeditationEvent extends Equatable {
  const MeditationEvent();

  @override
  List<Object> get props => [];
}

class LoadMeditationContent extends MeditationEvent {}

// States
enum MeditationStatus { initial, loading, success, failure }

class MeditationState extends Equatable {
  final MeditationStatus status;
  final List<MeditationItem> beats;
  final List<MeditationItem> tutorials;
  final String? errorMessage;

  const MeditationState({
    this.status = MeditationStatus.initial,
    this.beats = const [],
    this.tutorials = const [],
    this.errorMessage,
  });

  MeditationState copyWith({
    MeditationStatus? status,
    List<MeditationItem>? beats,
    List<MeditationItem>? tutorials,
    String? errorMessage,
  }) {
    return MeditationState(
      status: status ?? this.status,
      beats: beats ?? this.beats,
      tutorials: tutorials ?? this.tutorials,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, beats, tutorials, errorMessage];
}

// Bloc
class MeditationBloc extends Bloc<MeditationEvent, MeditationState> {
  final MeditationRepository _repository;

  MeditationBloc({required MeditationRepository repository})
      : _repository = repository,
        super(const MeditationState()) {
    on<LoadMeditationContent>(_onLoadContent);
  }

  Future<void> _onLoadContent(
    LoadMeditationContent event,
    Emitter<MeditationState> emit,
  ) async {
    emit(state.copyWith(status: MeditationStatus.loading));
    try {
      final items = await _repository.getItems();
      final beats = items.where((i) => !i.isTutorial).toList();
      final tutorials = items.where((i) => i.isTutorial).toList();

      emit(state.copyWith(
        status: MeditationStatus.success,
        beats: beats,
        tutorials: tutorials,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MeditationStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
