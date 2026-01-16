import 'package:flutter/material.dart';
import 'package:ai_health/features/streak/models/streak_day.dart';

class StreakColorUtil {
  /// Get color based on streak status and day streak count
  static Color getStreakColor(StreakStatus status, int dayStreak) {
    switch (status) {
      case StreakStatus.none:
        // Gray for no activity
        return Colors.grey[300]!;
      case StreakStatus.active:
        // Yellow for first day (dayStreak == 1)
        return Colors.amber[400]!;
      case StreakStatus.consistent:
        // Green for multiple consecutive days
        return Colors.green[500]!;
      case StreakStatus.broken:
        // Red for broken streak
        return Colors.red[400]!;
    }
  }

  /// Get streak status text
  static String getStatusText(StreakStatus status) {
    switch (status) {
      case StreakStatus.none:
        return 'No Activity';
      case StreakStatus.active:
        return 'Active';
      case StreakStatus.consistent:
        return 'Consistent';
      case StreakStatus.broken:
        return 'Broken';
    }
  }

  /// Get border color based on streak status
  static Color getStreakBorderColor(StreakStatus status) {
    switch (status) {
      case StreakStatus.none:
        return Colors.grey[400]!;
      case StreakStatus.active:
        return Colors.amber[600]!;
      case StreakStatus.consistent:
        return Colors.green[700]!;
      case StreakStatus.broken:
        return Colors.red[600]!;
    }
  }

  /// Get text color based on streak status
  static Color getStreakTextColor(StreakStatus status) {
    switch (status) {
      case StreakStatus.none:
        return Colors.grey[700]!;
      case StreakStatus.active:
        return Colors.amber[900]!;
      case StreakStatus.consistent:
        return Colors.green[900]!;
      case StreakStatus.broken:
        return Colors.red[900]!;
    }
  }
}
