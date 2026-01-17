part of 'step_bloc.dart';

abstract class StepState extends Equatable {
  const StepState();

  @override
  List<Object> get props => [];
}

class StepInitial extends StepState {}

class StepLoading extends StepState {}

class StepLoaded extends StepState {
  final List<StepsRecord> stepData;

  const StepLoaded({required this.stepData});

  @override
  List<Object> get props => [stepData];
}

class StepError extends StepState {
  final String message;

  const StepError({required this.message});

  @override
  List<Object> get props => [message];
}
