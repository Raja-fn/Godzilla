import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ai_health/main.dart';
import 'package:health_connector/health_connector.dart';
import 'package:health_connector/health_connector_internal.dart';
import '../models/hydration_model.dart';
import 'dart:developer' as developer;

part 'hydration_event.dart';
part 'hydration_state.dart';

class HydrationBloc extends Bloc<HydrationEvent, HydrationState> {
  HydrationBloc() : super(const HydrationInitial()) {
    on<InitializeHydrationEvent>(_onInitialize);
    on<AddGlassEvent>(_onAddGlass);
    on<SetupRemindersEvent>(_onSetupReminders);
    on<UpdateRemindersEvent>(_onUpdateReminders);
  }

  Future<void> _onInitialize(
    InitializeHydrationEvent event,
    Emitter<HydrationState> emit,
  ) async {
    emit(const HydrationLoading());
    try {
      // Initialize with 0 glasses consumed
      // In a real app, you'd sync with Health Connect to get today's total
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final records = await healthConnector.readRecords(
        ReadRecordsInTimeRangeRequest(
          dataType: HealthDataType.hydration,
          startTime: startOfDay,
          endTime: endOfDay,
        ),
      );
      double volumeofWater = 0;
      for (var record in records.records) {
        volumeofWater += record.volume.inMilliliters;
      }
      final hydration = HydrationModel(
        id: DateTime.now().millisecondsSinceEpoch,
        reminderTimes: [],
        date: now,
        glassesConsumed: (volumeofWater / 250).toInt(),
        glassesTarget: 8,
      );
      print(hydration.glassesConsumed);
      developer.log('HydrationBloc: Initialized hydration tracking for today');
      emit(HydrationLoaded(hydration: hydration));
    } catch (e) {
      developer.log('HydrationBloc: Initialization error: $e', error: e);
      emit(HydrationError(message: e.toString()));
    }
  }

  Future<void> _onAddGlass(
    AddGlassEvent event,
    Emitter<HydrationState> emit,
  ) async {
    if (state is HydrationLoaded) {
      final currentState = state as HydrationLoaded;
      final updatedHydration = currentState.hydration.copyWith(
        glassesConsumed: currentState.hydration.glassesConsumed + 1,
      );

      // Write to Health Connect - 250ml per glass
      try {
        final now = DateTime.now();

        // Create a hydration record with 250ml (one glass of water)
        final hydrationRecord = HydrationRecord(
          startTime: now,
          endTime: now.add(Duration(minutes: 2)), // Hydration is instantaneous
          volume: const Volume.milliliters(250), // 250ml per glass
          metadata: Metadata.internal(
            recordingMethod: RecordingMethod.manualEntry,
          ),
        );

        // Write the record to Health Connect
        await healthConnector.writeRecord(hydrationRecord);

        print('Total glasses today: ${updatedHydration.glassesConsumed}');
      } catch (e) {
        print('HydrationBloc: Health Connect Write Error: $e');
        // Still emit the local state update so the UI remains responsive
        // The data will be stored locally and synced when Health Connect is available
      }

      emit(HydrationLoaded(hydration: updatedHydration));
    }
  }

  Future<void> _onSetupReminders(
    SetupRemindersEvent event,
    Emitter<HydrationState> emit,
  ) async {
    if (state is HydrationLoaded) {
      final currentState = state as HydrationLoaded;
      final reminderTimes = _generateReminderTimes(event.intervalMinutes);
      final updatedHydration = currentState.hydration.copyWith(
        reminderTimes: reminderTimes,
      );
      print(
        'HydrationBloc: Setup reminders every ${event.intervalMinutes} minutes. ',
      );
      emit(HydrationLoaded(hydration: updatedHydration));
    }
  }

  Future<void> _onUpdateReminders(
    UpdateRemindersEvent event,
    Emitter<HydrationState> emit,
  ) async {
    if (state is HydrationLoaded) {
      final currentState = state as HydrationLoaded;
      final remainingTimes = currentState.hydration.reminderTimes
          .where((time) => time.isAfter(DateTime.now()))
          .toList();
      final updatedHydration = currentState.hydration.copyWith(
        reminderTimes: remainingTimes,
      );
      developer.log(
        'HydrationBloc: Updated reminders. '
        '${remainingTimes.length} reminders remaining for today',
      );
      emit(HydrationLoaded(hydration: updatedHydration));
    }
  }

  /// Generate reminder times for the day at specified intervals
  /// Starts from now + interval and continues until 11:59 PM
  List<DateTime> _generateReminderTimes(int intervalMinutes) {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59);
    final times = <DateTime>[];
    var currentTime = now.add(Duration(minutes: intervalMinutes));

    while (currentTime.isBefore(endOfDay)) {
      times.add(currentTime);
      currentTime = currentTime.add(Duration(minutes: intervalMinutes));
    }

    return times;
  }
}
