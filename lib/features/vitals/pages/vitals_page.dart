import 'package:ai_health/features/vitals/bloc/vitals_bloc.dart';
import 'package:ai_health/features/vitals/models/vital_data.dart';
import 'package:ai_health/features/vitals/repo/vitals_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class VitalsPage extends StatelessWidget {
  const VitalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => VitalsRepository(),
      child: BlocProvider(
        create: (context) =>
            VitalsBloc(repository: context.read<VitalsRepository>())
              ..add(LoadVitalsHistory()),
        child: const _VitalsView(),
      ),
    );
  }
}

class _VitalsView extends StatefulWidget {
  const _VitalsView();

  @override
  State<_VitalsView> createState() => _VitalsViewState();
}

class _VitalsViewState extends State<_VitalsView> {
  int _stressLevel = 5;
  String _mood = 'Calm';
  final TextEditingController _heartRateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final List<String> _moods = [
    'Happy',
    'Sad',
    'Stressed',
    'Calm',
    'Energetic',
    'Anxious'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vitals & Mood')),
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
                    const Text('Log Vitals',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _heartRateController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Heart Rate (bpm)',
                        suffixText: 'bpm',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Stress Level: $_stressLevel/10'),
                        Slider(
                          value: _stressLevel.toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          onChanged: (val) {
                            setState(() {
                              _stressLevel = val.toInt();
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _mood,
                      decoration: const InputDecoration(
                        labelText: 'Current Mood',
                        border: OutlineInputBorder(),
                      ),
                      items: _moods
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (val) => setState(() => _mood = val!),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        final data = VitalData(
                          date: DateTime.now(),
                          heartRate: int.tryParse(_heartRateController.text),
                          stressLevel: _stressLevel,
                          mood: _mood,
                          notes: _notesController.text,
                        );
                        context.read<VitalsBloc>().add(AddVitalEntry(data));

                        // Clear form
                        _heartRateController.clear();
                        _notesController.clear();
                        setState(() {
                          _stressLevel = 5;
                          _mood = 'Calm';
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vitals logged')));
                      },
                      child: const Text('Save Entry'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Recent Logs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            BlocBuilder<VitalsBloc, VitalsState>(
              builder: (context, state) {
                if (state.status == VitalsStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.history.isEmpty) {
                  return const Text('No vital logs yet.');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.history.length,
                  itemBuilder: (context, index) {
                    final item = state.history[index];
                    return Card(
                      child: ListTile(
                        leading: _getMoodIcon(item.mood),
                        title: Text(DateFormat.yMMMd().add_jm().format(item.date)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.heartRate != null)
                              Text('Heart Rate: ${item.heartRate} bpm'),
                            Text('Stress: ${item.stressLevel}/10'),
                            if (item.notes != null && item.notes!.isNotEmpty)
                              Text('Note: ${item.notes}'),
                          ],
                        ),
                        trailing: Text(item.mood, style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _getMoodIcon(String mood) {
    IconData icon;
    Color color;
    switch (mood) {
      case 'Happy':
      case 'Energetic':
        icon = Icons.sentiment_very_satisfied;
        color = Colors.green;
        break;
      case 'Sad':
        icon = Icons.sentiment_very_dissatisfied;
        color = Colors.blueGrey;
        break;
      case 'Stressed':
      case 'Anxious':
        icon = Icons.sentiment_dissatisfied;
        color = Colors.red;
        break;
      case 'Calm':
      default:
        icon = Icons.sentiment_satisfied;
        color = Colors.blue;
        break;
    }
    return Icon(icon, color: color, size: 32);
  }
}
