part of 'step_bloc.dart';

abstract class StepEvent extends Equatable {
  const StepEvent();

  @override
  List<Object> get props => [];
}

class LoadStepDataEvent extends StepEvent {
  final int days;

  const LoadStepDataEvent({required this.days});

  @override
  List<Object> get props => [days];
}
