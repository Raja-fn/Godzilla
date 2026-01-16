import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../bloc/hydration_bloc.dart';
import '../models/hydration_model.dart';
import '../services/hydration_service.dart';
import '../services/notification_service.dart';
import 'package:ai_health/services/system_notification_service.dart';

class HydrationPage extends StatefulWidget {
  const HydrationPage({super.key});

  @override
  State<HydrationPage> createState() => _HydrationPageState();
}

class _HydrationPageState extends State<HydrationPage>
    with SingleTickerProviderStateMixin {
  late HydrationBloc _hydrationBloc;
  int _reminderIntervalMinutes = 120;
  bool _remindersActive = false;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _hydrationBloc = context.read<HydrationBloc>();
    _initializeHydration();
    _initializeService();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _initializeHydration() {
    _hydrationBloc.add(const InitializeHydrationEvent());
  }

  Future<void> _initializeService() async {
    try {
      await HydrationService.initialize();
      // Initialize SystemNotificationService for foreground usage if needed
      await SystemNotificationService().initialize();
      await SystemNotificationService().requestPermissions();
    } catch (e) {
      debugPrint('Error initializing hydration service: $e');
    }
  }

  void _addGlass() {
    _hydrationBloc.add(const AddGlassEvent());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Glass added (+250ml) 💧')),
    );
  }

  Future<void> _setupReminders() async {
    _hydrationBloc.add(
      SetupRemindersEvent(intervalMinutes: _reminderIntervalMinutes),
    );
    await HydrationService.setupDailyReminders(
      intervalMinutes: _reminderIntervalMinutes,
      glassesPerDay: 8,
    );
    setState(() => _remindersActive = true);
  }
  
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Hydration'),
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
        child: BlocBuilder<HydrationBloc, HydrationState>(
          builder: (context, state) {
            if (state is HydrationLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is HydrationLoaded) {
              return _buildDashboard(state.hydration);
            }
            return const Center(child: Text('Failed to load hydration data'));
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addGlass,
        label: const Text('Add 250ml'),
        icon: const Icon(Icons.water_drop),
        backgroundColor: Colors.blue.shade600,
      ),
    );
  }

  Widget _buildDashboard(HydrationModel hydration) {
    final percentage = (hydration.glassesConsumed / hydration.glassesTarget).clamp(0.0, 1.0);
    final consumedMl = hydration.glassesConsumed * 250;
    final targetMl = hydration.glassesTarget * 250;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Big Circular Wave Progress
            Center(
              child: SizedBox(
                width: 250,
                height: 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glass/Container Border
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    // Wave Mask
                    ClipOval(
                      child: AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _WavePainter(
                              animationValue: _waveController.value,
                              percentage: percentage,
                              color: Colors.blue.shade400,
                            ),
                            size: const Size(250, 250),
                          );
                        },
                      ),
                    ),
                    // Text Overlay
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(percentage * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: percentage > 0.5 ? Colors.white : Colors.blue.shade900,
                          ),
                        ),
                        Text(
                          '$consumedMl / $targetMl ml',
                          style: TextStyle(
                            fontSize: 16,
                            color: percentage > 0.5 ? Colors.white.withValues(alpha: 0.9) : Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Grid of Glasses
            Text(
              'Daily Goal: ${hydration.glassesTarget} Glasses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: List.generate(hydration.glassesTarget, (index) {
                final isConsumed = index < hydration.glassesConsumed;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 30,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isConsumed ? Colors.blue.shade400 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isConsumed ? Colors.blue.shade400 : Colors.blue.shade200,
                      width: 2,
                    ),
                  ),
                  child: isConsumed 
                    ? const Icon(Icons.check, size: 20, color: Colors.white)
                    : null,
                );
              }),
            ),
             
             const SizedBox(height: 40),
             
             // Setup Reminders Card (Simplified for UI look)
             Card(
               elevation: 0,
               color: Colors.white,
               shape: RoundedRectangleBorder(
                 borderRadius: BorderRadius.circular(16),
                 side: BorderSide(color: Colors.blue.shade100),
               ),
               child: SwitchListTile(
                 title: const Text('Daily Reminders'),
                 subtitle: Text('Notify every $_reminderIntervalMinutes mins'),
                 value: _remindersActive,
                 thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
                   if (states.contains(WidgetState.selected)) {
                     return Colors.blue;
                   }
                   return Colors.grey;
                 }),
                 onChanged: (val) {
                    setState(() {
                      _remindersActive = val;
                      if(val) {
                        _setupReminders();
                      } else {
                        HydrationService.cancelReminders();
                      }
                    });
                 },
                 secondary: const Icon(Icons.notifications_active_outlined, color: Colors.blue),
               ),
             ),
          ],
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double animationValue;
  final double percentage;
  final Color color;

  _WavePainter({
    required this.animationValue,
    required this.percentage,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (percentage == 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 10.0;
    final waveLength = size.width;
    
    // Calculate water level height based on percentage
    final waterLevel = size.height * (1 - percentage);

    path.moveTo(0, waterLevel);
    
    for (double i = 0; i <= waveLength; i++) {
      // Calculate sine wave
      final offset = (animationValue * 2 * math.pi);
      final y = waterLevel + math.sin((i / waveLength * 2 * math.pi) + offset) * waveHeight;
      path.lineTo(i, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.percentage != percentage;
  }
}
