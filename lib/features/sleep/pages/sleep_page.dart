import 'package:ai_health/features/sleep/bloc/sleep_bloc.dart';
import 'package:ai_health/features/sleep/models/sleep_data.dart';
import 'package:ai_health/features/sleep/repo/sleep_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class SleepPage extends StatelessWidget {
  const SleepPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => SleepRepository(),
      child: BlocProvider(
        create: (context) =>
            SleepBloc(repository: context.read<SleepRepository>())
              ..add(LoadSleepHistory()),
        child: const _SleepView(),
      ),
    );
  }
}

class _SleepView extends StatefulWidget {
  const _SleepView();

  @override
  State<_SleepView> createState() => _SleepViewState();
}

class _SleepViewState extends State<_SleepView> {
  DateTime _bedTime = DateTime.now().subtract(const Duration(hours: 8));
  DateTime _wakeTime = DateTime.now();
  String _quality = 'Good';

  Future<void> _pickTime(BuildContext context, bool isBedTime) async {
    final initialTime = TimeOfDay.fromDateTime(isBedTime ? _bedTime : _wakeTime);
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final now = DateTime.now();
      setState(() {
        if (isBedTime) {
          _bedTime = DateTime(
              now.year, now.month, now.day, picked.hour, picked.minute);
           // Adjust if bedTime is after wakeTime (likely previous day)
           if (_bedTime.isAfter(_wakeTime)) {
             _bedTime = _bedTime.subtract(const Duration(days: 1));
           }
        } else {
          _wakeTime = DateTime(
              now.year, now.month, now.day, picked.hour, picked.minute);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = _wakeTime.difference(_bedTime);
    final hours = duration.inMinutes / 60.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Sleep Tracker')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Log Last Night\'s Sleep',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTimePicker(
                            context, 'Bed Time', _bedTime, true),
                        _buildTimePicker(
                            context, 'Wake Time', _wakeTime, false),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                        'Duration: ${hours.toStringAsFixed(1)} hours',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                     const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _quality,
                      decoration: const InputDecoration(labelText: 'Sleep Quality'),
                      items: ['Poor', 'Fair', 'Good', 'Excellent']
                          .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                          .toList(),
                      onChanged: (val) => setState(() => _quality = val!),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        final data = SleepData(
                          date: DateTime.now(), // Log for today
                          durationHours: hours,
                          quality: _quality,
                          bedTime: _bedTime,
                          wakeTime: _wakeTime,
                        );
                        context.read<SleepBloc>().add(AddSleepEntry(data));
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sleep log added')));
                      },
                      child: const Text('Log Sleep'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Sleep History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            BlocBuilder<SleepBloc, SleepState>(
              builder: (context, state) {
                if (state.status == SleepStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.history.isEmpty) {
                  return const Text('No sleep records yet.');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.history.length,
                  itemBuilder: (context, index) {
                    final item = state.history[index];
                    return Dismissible(
                      key: Key(item.date.toIso8601String()),
                      background: Container(color: Colors.red),
                      onDismissed: (direction) {
                        context.read<SleepBloc>().add(DeleteSleepEntry(item.date));
                      },
                      child: Card(
                        child: ListTile(
                          leading: const Icon(Icons.bed),
                          title: Text(DateFormat.yMMMd().format(item.date)),
                          subtitle: Text(
                              '${item.durationHours.toStringAsFixed(1)} hrs - ${item.quality}'),
                          trailing: Text(
                            '${DateFormat.Hm().format(item.bedTime)} - ${DateFormat.Hm().format(item.wakeTime)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(
      BuildContext context, String label, DateTime time, bool isBedTime) {
    return InkWell(
      onTap: () => _pickTime(context, isBedTime),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(DateFormat.Hm().format(time),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
