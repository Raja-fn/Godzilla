class SleepData {
  final DateTime date;
  final double durationHours;
  final String quality; // "Poor", "Fair", "Good", "Excellent"
  final DateTime bedTime;
  final DateTime wakeTime;

  SleepData({
    required this.date,
    required this.durationHours,
    required this.quality,
    required this.bedTime,
    required this.wakeTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'durationHours': durationHours,
      'quality': quality,
      'bedTime': bedTime.toIso8601String(),
      'wakeTime': wakeTime.toIso8601String(),
    };
  }

  factory SleepData.fromMap(Map<dynamic, dynamic> map) {
    return SleepData(
      date: DateTime.parse(map['date']),
      durationHours: (map['durationHours'] as num).toDouble(),
      quality: map['quality'],
      bedTime: DateTime.parse(map['bedTime']),
      wakeTime: DateTime.parse(map['wakeTime']),
    );
  }
}
