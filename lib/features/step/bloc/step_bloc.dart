import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ai_health/main.dart';
import 'package:health_connector/health_connector.dart';
import 'package:health_connector/health_connector_internal.dart';
import '../models/step_model.dart';
import 'dart:developer' as developer;

part 'step_event.dart';
part 'step_state.dart';

class StepBloc extends Bloc<StepEvent, StepState> {
  StepBloc() : super(StepInitial()) {
    on<LoadStepDataEvent>(_onLoadStepData);
  }

  Future<void> _onLoadStepData(
    LoadStepDataEvent event,
    Emitter<StepState> emit,
  ) async {
    emit(StepLoading());
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: event.days));

      List<StepsRecord> records = [];
      try {
        final _records = await healthConnector.readRecords(
          ReadRecordsInTimeRangeRequest(
            dataType: HealthDataType.steps,
            startTime: startDate,
            endTime: now,
          ),
        );
        records = _records.records;

        print('StepBloc: Found ${records.length} step records');
        emit(StepLoaded(stepData: records));
      } catch (e) {
        print('StepBloc: Error reading step records: $e');
        emit(StepError(message: e.toString()));
        return;
      }

      final Map<DateTime, int> dailySteps = {};

      for (var record in records) {
        final date = DateTime(startDate.year, startDate.month, startDate.day);
        print(record.count);
        dailySteps[date] =
            ((dailySteps[date] ?? 0) + double.parse(record.count.toString()))
                .toInt();
      }

      records.sort((a, b) => a.startTime.compareTo(b.startTime));

      developer.log('StepBloc: Loaded ${records.length} days of step data');
      emit(StepLoaded(stepData: records));
    } catch (e) {
      developer.log('StepBloc: Error loading step data: $e', error: e);
      emit(StepError(message: e.toString()));
    }
  }
}
