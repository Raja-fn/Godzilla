part of 'hydration_bloc.dart';

abstract class HydrationEvent extends Equatable {
  const HydrationEvent();

  @override
  List<Object?> get props => [];
}

class InitializeHydrationEvent extends HydrationEvent {
  const InitializeHydrationEvent();
}

class AddGlassEvent extends HydrationEvent {
  const AddGlassEvent();
}

class SetupRemindersEvent extends HydrationEvent {
  final int intervalMinutes;

  const SetupRemindersEvent({required this.intervalMinutes});

  @override
  List<Object?> get props => [intervalMinutes];
}

class UpdateRemindersEvent extends HydrationEvent {
  const UpdateRemindersEvent();
}
