import 'package:equatable/equatable.dart';

enum StreakStatus {
  none, // Day with no activity (initial)
  active, // Yellow - first day of activity
  consistent, // Green - consistent activity
  broken, // Red - streak was broken
}

class StreakDay extends Equatable {
  final DateTime date;
  final List<String> photoPaths; // Local file paths or URLs
  final StreakStatus status;
  final int dayStreak; // Number of consecutive days (0 if broken or none)

  const StreakDay({
    required this.date,
    this.photoPaths = const [],
    this.status = StreakStatus.none,
    this.dayStreak = 0,
  });

  /// Create a copy with modifications
  StreakDay copyWith({
    DateTime? date,
    List<String>? photoPaths,
    StreakStatus? status,
    int? dayStreak,
  }) {
    return StreakDay(
      date: date ?? this.date,
      photoPaths: photoPaths ?? this.photoPaths,
      status: status ?? this.status,
      dayStreak: dayStreak ?? this.dayStreak,
    );
  }

  /// Check if this day has any photos
  bool get hasPhotos => photoPaths.isNotEmpty;

  /// Add a photo to this day
  StreakDay addPhoto(String photoPath) {
    final newPhotos = [...photoPaths, photoPath];
    return copyWith(photoPaths: newPhotos);
  }

  /// Remove a photo from this day
  StreakDay removePhoto(String photoPath) {
    final newPhotos = photoPaths.where((p) => p != photoPath).toList();
    return copyWith(photoPaths: newPhotos);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'photoPaths': photoPaths,
      'status': status.toString().split('.').last,
      'dayStreak': dayStreak,
    };
  }

  /// Create from JSON
  factory StreakDay.fromJson(Map<String, dynamic> json) {
    return StreakDay(
      date: DateTime.parse(json['date'] as String),
      photoPaths: List<String>.from(json['photoPaths'] as List? ?? []),
      status: _statusFromString(json['status'] as String? ?? 'none'),
      dayStreak: json['dayStreak'] as int? ?? 0,
    );
  }

  static StreakStatus _statusFromString(String status) {
    return StreakStatus.values.firstWhere(
      (e) => e.toString().split('.').last == status,
      orElse: () => StreakStatus.none,
    );
  }

  @override
  List<Object?> get props => [date, photoPaths, status, dayStreak];
}
