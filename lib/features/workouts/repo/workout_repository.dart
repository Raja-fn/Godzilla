import 'package:hive_flutter/hive_flutter.dart';
import '../models/workout_data.dart';

class WorkoutRepository {
  static const String boxName = 'workout_data_box';

  Future<Box> _getBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    return await Hive.openBox(boxName);
  }

  Future<void> saveWorkout(WorkoutData data) async {
    final box = await _getBox();
    final key = data.date.millisecondsSinceEpoch.toString();
    await box.put(key, data.toMap());
  }

  Future<List<WorkoutData>> getWorkoutHistory() async {
    final box = await _getBox();
    final List<WorkoutData> list = [];
    for (var i = 0; i < box.length; i++) {
      final map = box.getAt(i) as Map<dynamic, dynamic>;
      list.add(WorkoutData.fromMap(map));
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }
}
