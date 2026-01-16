class WorkoutData {
  final DateTime date;
  final String type; // e.g., Running, Cycling, Gym, Yoga
  final int durationMinutes;
  final int caloriesBurned;
  final String? notes;

  WorkoutData({
    required this.date,
    required this.type,
    required this.durationMinutes,
    required this.caloriesBurned,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'type': type,
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
      'notes': notes,
    };
  }

  factory WorkoutData.fromMap(Map<dynamic, dynamic> map) {
    return WorkoutData(
      date: DateTime.parse(map['date']),
      type: map['type'],
      durationMinutes: map['durationMinutes'],
      caloriesBurned: map['caloriesBurned'],
      notes: map['notes'],
    );
  }
}
