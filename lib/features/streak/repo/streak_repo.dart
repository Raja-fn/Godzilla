import 'dart:io';
import 'package:ai_health/features/streak/models/streak_data.dart';
import 'package:ai_health/features/streak/models/streak_day.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

class StreakRepository {
  static const String _streakBoxName = 'streak_box';

  /// Initialize the repository
  Future<StreakData> getStreakData(String userId) async {
    final key = 'streak_$userId';
    final box = Hive.box(_streakBoxName);

    final raw = box.get(key);

    // 🔒 Always normalize Hive data
    final Map<String, dynamic>? data = raw != null
        ? Map<String, dynamic>.from(
            (raw as Map).map((k, v) => MapEntry(k.toString(), v)),
          )
        : null;

    print(data);
    print(data.runtimeType);

    if (data == null) {
      final newStreak = StreakData(
        id: 'streak_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await box.put(key, newStreak.toJson());
      return newStreak;
    }

    return StreakData.fromJson(data);
  }

  /// Get or create streak data for a user

  /// Save a streak day
  Future<void> saveStreakDay(String userId, StreakDay day) async {
    final streakData = await getStreakData(userId);
    final updated = streakData.updateDay(day);

    // Recalculate streaks
    final today = DateTime.now();
    final todayStreak = updated.calculateStreakFromDate(today);

    final finalData = updated.copyWith(
      currentStreak: todayStreak,
      updatedAt: DateTime.now(),
    );
    final _box = await Hive.box(_streakBoxName);
    await _box.put('streak_$userId', finalData.toJson());
  }

  /// Add a photo to a specific day
  Future<void> addPhotoToDay(
    String userId,
    DateTime date,
    String photoPath,
  ) async {
    final streakData = await getStreakData(userId);
    var day = streakData.getDay(date);

    if (day == null) {
      day = StreakDay(date: date, status: StreakStatus.active);
    }

    final updatedDay = day.addPhoto(photoPath);

    // Determine status based on streak
    final streak = streakData.calculateStreakFromDate(date);
    StreakStatus status;
    if (streak == 1) {
      status = StreakStatus.active; // First day is yellow
    } else if (streak > 1) {
      status = StreakStatus.consistent; // Multiple days is green
    } else {
      status = StreakStatus.broken; // No previous streak
    }

    final finalDay = updatedDay.copyWith(status: status, dayStreak: streak);
    await saveStreakDay(userId, finalDay);
  }

  /// Remove a photo from a day
  Future<void> removePhotoFromDay(
    String userId,
    DateTime date,
    String photoPath,
  ) async {
    final streakData = await getStreakData(userId);
    var day = streakData.getDay(date);

    if (day != null) {
      final updatedDay = day.removePhoto(photoPath);

      // If no more photos, mark as broken
      if (updatedDay.photoPaths.isEmpty) {
        final finalDay = updatedDay.copyWith(
          status: StreakStatus.broken,
          dayStreak: 0,
        );
        await saveStreakDay(userId, finalDay);
      } else {
        await saveStreakDay(userId, updatedDay);
      }
    }
  }

  /// Get a month's streak data
  Future<Map<String, StreakDay>> getMonthData(
    String userId,
    DateTime month,
  ) async {
    final streakData = await getStreakData(userId);
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    return Map.fromEntries(
      streakData.getDaysInRange(firstDay, lastDay).map((day) {
        final dateKey =
            '${day.date.year}-${day.date.month.toString().padLeft(2, '0')}-${day.date.day.toString().padLeft(2, '0')}';
        return MapEntry(dateKey, day);
      }),
    );
  }

  /// Get all photos for a specific day
  Future<List<String>> getPhotosForDay(String userId, DateTime date) async {
    final streakData = await getStreakData(userId);
    final day = streakData.getDay(date);
    return day?.photoPaths ?? [];
  }

  /// Delete all streak data for a user (for testing/reset)
  Future<void> deleteUserStreakData(String userId) async {
    final _box = await Hive.box(_streakBoxName);
    await _box.delete('streak_$userId');
  }

  /// Clear all local photo files for a user
  Future<void> clearLocalPhotos(String userId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final streakPhotosDir = Directory('${appDir.path}/streak_photos/$userId');

      if (await streakPhotosDir.exists()) {
        await streakPhotosDir.delete(recursive: true);
      }
    } catch (e) {
      print('Error clearing local photos: $e');
    }
  }

  /// Save a photo locally and return the path
  Future<String> savePhotoLocally(String userId, String sourcePhotoPath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final streakPhotosDir = Directory('${appDir.path}/streak_photos/$userId');

      if (!await streakPhotosDir.exists()) {
        await streakPhotosDir.create(recursive: true);
      }

      final fileName =
          'photo_${DateTime.now().millisecondsSinceEpoch}${_getFileExtension(sourcePhotoPath)}';
      final newPath = '${streakPhotosDir.path}/$fileName';

      final sourceFile = File(sourcePhotoPath);
      await sourceFile.copy(newPath);

      return newPath;
    } catch (e) {
      print('Error saving photo: $e');
      rethrow;
    }
  }

  /// Get file extension from path
  String _getFileExtension(String path) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot != -1) {
      return path.substring(lastDot);
    }
    return '.jpg';
  }
}
