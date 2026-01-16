import 'package:ai_health/features/streak/models/streak_day.dart';
import 'package:equatable/equatable.dart';

class StreakData extends Equatable {
  final String id;
  final String userId;
  final Map<String, StreakDay> days; // Key: date in 'yyyy-MM-dd' format
  final int longestStreak;
  final int currentStreak;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StreakData({
    required this.id,
    required this.userId,
    this.days = const {},
    this.longestStreak = 0,
    this.currentStreak = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get a specific day by DateTime
  StreakDay? getDay(DateTime date) {
    final dateKey = _formatDateKey(date);
    return days[dateKey];
  }

  /// Add or update a day
  StreakData updateDay(StreakDay day) {
    final dateKey = _formatDateKey(day.date);
    final newDays = {...days, dateKey: day};
    return copyWith(days: newDays);
  }

  /// Format date to string key (yyyy-MM-dd)
  static String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Check if there's a streak on a specific date
  bool hasStreakOnDate(DateTime date) {
    final day = getDay(date);
    return day != null && day.hasPhotos;
  }

  /// Get all days in a date range
  List<StreakDay> getDaysInRange(DateTime start, DateTime end) {
    final result = <StreakDay>[];
    for (
      var date = start;
      date.isBefore(end) || date.isAtSameMomentAs(end);
      date = date.add(const Duration(days: 1))
    ) {
      final day = getDay(date);
      if (day != null) {
        result.add(day);
      }
    }
    return result;
  }

  /// Calculate streak from a given date backwards
  int calculateStreakFromDate(DateTime date) {
    int streak = 0;
    var currentDate = date;

    while (true) {
      final day = getDay(currentDate);
      if (day != null && day.hasPhotos) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  /// Copy with modifications
  StreakData copyWith({
    String? id,
    String? userId,
    Map<String, StreakDay>? days,
    int? longestStreak,
    int? currentStreak,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StreakData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      days: days ?? this.days,
      longestStreak: longestStreak ?? this.longestStreak,
      currentStreak: currentStreak ?? this.currentStreak,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'days': days.map((key, value) => MapEntry(key, value.toJson())),
      'longestStreak': longestStreak,
      'currentStreak': currentStreak,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory StreakData.fromJson(Map<String, dynamic> json) {
    final Map<String, StreakDay> daysMap = {};

    final rawDays = json['days'];

    if (rawDays is Map) {
      rawDays.forEach((key, value) {
        daysMap[key.toString()] = StreakDay.fromJson(
          Map<String, dynamic>.from(value as Map),
        );
      });
    }

    return StreakData(
      id: json['id'] as String,
      userId: json['userId'] as String,
      days: daysMap,
      longestStreak: json['longestStreak'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'].toString()),
      updatedAt: DateTime.parse(json['updatedAt'].toString()),
    );
  }

  /// Create from JSON
  @override
  List<Object?> get props => [
    id,
    userId,
    days,
    longestStreak,
    currentStreak,
    createdAt,
    updatedAt,
  ];
}
