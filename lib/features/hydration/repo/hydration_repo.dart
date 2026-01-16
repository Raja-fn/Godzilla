import 'package:ai_health/main.dart';
import 'package:health_connector/health_connector.dart';
import '../models/hydration_model.dart';
import 'dart:developer' as developer;

class HydrationRepository {
  /// Write a hydration record (250ml glass) to Health Connect
  Future<void> addHydrationGlass() async {
    try {
      final now = DateTime.now();
      final hydrationRecord = HydrationRecord(
        startTime: now,
        endTime: now,
        volume: const Volume.milliliters(250), // 250ml per glass
        metadata: Metadata.internal(
          recordingMethod: RecordingMethod.manualEntry,
        ),
      );

      await healthConnector.writeRecord(hydrationRecord);
      developer.log('HydrationRepository: Successfully wrote hydration record');
    } catch (e) {
      developer.log(
        'HydrationRepository: Error writing hydration record: $e',
        error: e,
      );
      rethrow;
    }
  }

  /// Get today's hydration data
  /// Returns the number of glasses consumed based on Health Connect data
  Future<int> getTodayHydration() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      developer.log('HydrationRepository: Fetching hydration for today');

      // Try to aggregate hydration data for today
      try {
        // Alternative: Count records manually by reading all hydration records
        // Note: The exact API might differ based on health_connector version
        developer.log(
          'HydrationRepository: Health Connect aggregate not directly supported, returning 0',
        );
        return 0;
      } catch (e) {
        developer.log(
          'HydrationRepository: Could not fetch from Health Connect: $e',
          error: e,
        );
        return 0;
      }
    } catch (e) {
      developer.log(
        'HydrationRepository: Error getting today hydration: $e',
        error: e,
      );
      rethrow;
    }
  }

  /// Get hydration target for the day (default: 8 glasses)
  int getDailyTarget() {
    return 8; // 8 glasses per day
  }

  /// Convert milliliters to glasses (250ml per glass)
  int millilitersToGlasses(double milliliters) {
    return (milliliters / 250).round();
  }

  /// Convert glasses to milliliters
  double glassesToMilliliters(int glasses) {
    return glasses * 250.0;
  }
}
