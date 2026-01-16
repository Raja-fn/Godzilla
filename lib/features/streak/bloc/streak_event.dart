import 'package:equatable/equatable.dart';
import 'package:ai_health/features/streak/models/streak_day.dart';

abstract class StreakEvent extends Equatable {
  const StreakEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch streak data for the user
class FetchStreakDataEvent extends StreakEvent {
  final String userId;

  const FetchStreakDataEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Add photo to a specific day
class AddPhotoToDayEvent extends StreakEvent {
  final String userId;
  final DateTime date;
  final String photoPath;

  const AddPhotoToDayEvent({
    required this.userId,
    required this.date,
    required this.photoPath,
  });

  @override
  List<Object?> get props => [userId, date, photoPath];
}

/// Remove photo from a day
class RemovePhotoFromDayEvent extends StreakEvent {
  final String userId;
  final DateTime date;
  final String photoPath;

  const RemovePhotoFromDayEvent({
    required this.userId,
    required this.date,
    required this.photoPath,
  });

  @override
  List<Object?> get props => [userId, date, photoPath];
}

/// Update specific day's photos
class UpdateDayPhotosEvent extends StreakEvent {
  final String userId;
  final StreakDay day;

  const UpdateDayPhotosEvent({required this.userId, required this.day});

  @override
  List<Object?> get props => [userId, day];
}

/// Fetch month data
class FetchMonthDataEvent extends StreakEvent {
  final String userId;
  final DateTime month;

  const FetchMonthDataEvent({required this.userId, required this.month});

  @override
  List<Object?> get props => [userId, month];
}

/// Delete user streak data
class DeleteStreakDataEvent extends StreakEvent {
  final String userId;

  const DeleteStreakDataEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}
