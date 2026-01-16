import 'package:equatable/equatable.dart';
import 'package:ai_health/features/streak/models/streak_data.dart';
import 'package:ai_health/features/streak/models/streak_day.dart';

abstract class StreakState extends Equatable {
  const StreakState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class StreakInitial extends StreakState {
  const StreakInitial();
}

/// Loading state
class StreakLoading extends StreakState {
  const StreakLoading();
}

/// Loaded state with streak data
class StreakLoaded extends StreakState {
  final StreakData streakData;
  final Map<String, StreakDay> monthData;

  const StreakLoaded({required this.streakData, this.monthData = const {}});

  StreakLoaded copyWith({
    StreakData? streakData,
    Map<String, StreakDay>? monthData,
  }) {
    return StreakLoaded(
      streakData: streakData ?? this.streakData,
      monthData: monthData ?? this.monthData,
    );
  }

  @override
  List<Object?> get props => [streakData, monthData];
}

/// Photo added state
class PhotoAdded extends StreakState {
  final String photoPath;
  final StreakDay day;

  const PhotoAdded({required this.photoPath, required this.day});

  @override
  List<Object?> get props => [photoPath, day];
}

/// Photo removed state
class PhotoRemoved extends StreakState {
  final String photoPath;
  final StreakDay day;

  const PhotoRemoved({required this.photoPath, required this.day});

  @override
  List<Object?> get props => [photoPath, day];
}

/// Error state
class StreakError extends StreakState {
  final String message;

  const StreakError(this.message);

  @override
  List<Object?> get props => [message];
}
