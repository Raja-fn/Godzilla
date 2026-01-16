import 'package:hive_flutter/hive_flutter.dart';
import '../models/sleep_data.dart';

class SleepRepository {
  static const String boxName = 'sleep_data_box';

  Future<Box> _getBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    return await Hive.openBox(boxName);
  }

  Future<void> saveSleepData(SleepData data) async {
    final box = await _getBox();
    // Key by date string (YYYY-MM-DD) to ensure one entry per day
    final key = data.date.toIso8601String().split('T')[0];
    await box.put(key, data.toMap());
  }

  Future<List<SleepData>> getSleepHistory() async {
    final box = await _getBox();
    final List<SleepData> list = [];
    for (var key in box.keys) {
      final map = box.get(key);
       if (map != null) {
        list.add(SleepData.fromMap(map as Map<dynamic, dynamic>));
      }
    }
    // Sort by date descending
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> deleteSleepData(DateTime date) async {
    final box = await _getBox();
    final key = date.toIso8601String().split('T')[0];
    await box.delete(key);
  }
}
