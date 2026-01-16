import 'package:hive_flutter/hive_flutter.dart';
import '../models/vital_data.dart';

class VitalsRepository {
  static const String boxName = 'vitals_data_box';

  Future<Box> _getBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    return await Hive.openBox(boxName);
  }

  Future<void> saveVitalData(VitalData data) async {
    final box = await _getBox();
    // Key by timestamp to allow multiple entries per day
    final key = data.date.millisecondsSinceEpoch.toString();
    await box.put(key, data.toMap());
  }

  Future<List<VitalData>> getVitalsHistory() async {
    final box = await _getBox();
    final List<VitalData> list = [];
    for (var i = 0; i < box.length; i++) {
      final map = box.getAt(i) as Map<dynamic, dynamic>;
      list.add(VitalData.fromMap(map));
    }
    // Sort by date descending
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }
}
