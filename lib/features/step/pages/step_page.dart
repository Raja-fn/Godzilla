import 'package:ai_health/features/step/bloc/step_bloc.dart' as step_bloc;
import 'package:ai_health/features/step/models/step_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health_connector/health_connector.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class StepPage extends StatefulWidget {
  const StepPage({super.key});
  @override
  State<StepPage> createState() => _StepPageState();
}

class _StepPageState extends State<StepPage> {
  late step_bloc.StepBloc _stepBloc;
  int _selectedDays = 7;

  @override
  void initState() {
    super.initState();
    _stepBloc = context.read<step_bloc.StepBloc>();
    _stepBloc.add(step_bloc.LoadStepDataEvent(days: _selectedDays));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Steps'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.blue.shade800,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.blue.shade50],
          ),
        ),
        child: BlocBuilder<step_bloc.StepBloc, step_bloc.StepState>(
          builder: (context, state) {
            print(state);
            if (state is step_bloc.StepLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is step_bloc.StepLoaded) {
              return _buildDashboard(state.stepData);
            }
            return const Center(child: Text('Failed to load step data'));
          },
        ),
      ),
    );
  }

  Widget _buildDashboard(List<StepsRecord> stepData) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDaysSelector(),
            const SizedBox(height: 24),
            _buildChart(stepData),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildDaysButton(7),
          const SizedBox(width: 16),
          _buildDaysButton(30),
          const SizedBox(width: 16),
          _buildDaysButton(90),
        ],
      ),
    );
  }

  Widget _buildDaysButton(int days) {
    final isSelected = _selectedDays == days;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedDays = days;
        });
        _stepBloc.add(step_bloc.LoadStepDataEvent(days: _selectedDays));
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue.shade600 : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.blue.shade600,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text('$days Days'),
    );
  }

  Widget _buildChart(List<StepsRecord> stepData) {
    print(double.parse(stepData[0].count.toString()).toInt());
    return SizedBox(
      height: 300,
      child: SfCartesianChart(
        primaryXAxis: DateTimeAxis(
          dateFormat: DateFormat.MMMd(),
          intervalType: DateTimeIntervalType.days,
          majorGridLines: const MajorGridLines(width: 0),
        ),
        primaryYAxis: NumericAxis(
          majorGridLines: const MajorGridLines(width: 0.5),
          numberFormat: NumberFormat.compact(),
        ),
        series: [
          ColumnSeries<StepsRecord, DateTime>(
            dataSource: stepData,
            xValueMapper: (StepsRecord data, _) => data.startTime,
            yValueMapper: (StepsRecord data, _) =>
                double.parse(data.count.toString()).toInt(),
            color: Colors.blue.shade400,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
        ],
      ),
    );
  }
}
