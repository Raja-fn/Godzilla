class VitalData {
  final DateTime date;
  final int? heartRate;
  final int stressLevel; // 1-10
  final String mood; // "Happy", "Sad", "Stressed", "Calm", "Energetic"
  final String? notes;

  VitalData({
    required this.date,
    this.heartRate,
    required this.stressLevel,
    required this.mood,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'heartRate': heartRate,
      'stressLevel': stressLevel,
      'mood': mood,
      'notes': notes,
    };
  }

  factory VitalData.fromMap(Map<dynamic, dynamic> map) {
    return VitalData(
      date: DateTime.parse(map['date']),
      heartRate: map['heartRate'],
      stressLevel: map['stressLevel'],
      mood: map['mood'],
      notes: map['notes'],
    );
  }
}
