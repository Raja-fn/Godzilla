import 'package:equatable/equatable.dart';

class HydrationModel extends Equatable {
  final int id;
  final DateTime date;
  final int glassesConsumed;
  final int glassesTarget;
  final List<DateTime> reminderTimes;

  const HydrationModel({
    required this.id,
    required this.date,
    required this.glassesConsumed,
    required this.glassesTarget,
    required this.reminderTimes,
  });

  HydrationModel copyWith({
    int? id,
    DateTime? date,
    int? glassesConsumed,
    int? glassesTarget,
    List<DateTime>? reminderTimes,
  }) {
    return HydrationModel(
      id: id ?? this.id,
      date: date ?? this.date,
      glassesConsumed: glassesConsumed ?? this.glassesConsumed,
      glassesTarget: glassesTarget ?? this.glassesTarget,
      reminderTimes: reminderTimes ?? this.reminderTimes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    date,
    glassesConsumed,
    glassesTarget,
    reminderTimes,
  ];
}
