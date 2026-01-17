part of 'hydration_bloc.dart';

abstract class HydrationState extends Equatable {
  const HydrationState();

  @override
  List<Object?> get props => [];
}

class HydrationInitial extends HydrationState {
  const HydrationInitial();
}

class HydrationLoading extends HydrationState {
  const HydrationLoading();
}

class HydrationLoaded extends HydrationState {
  final HydrationModel hydration;

  const HydrationLoaded({required this.hydration});

  @override
  List<Object?> get props => [hydration];
}

class HydrationError extends HydrationState {
  final String message;

  const HydrationError({required this.message});

  @override
  List<Object?> get props => [message];
}
