import 'dart:async';
import 'package:ai_health/main.dart';
import 'package:ai_health/services/system_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:health_connector/health_connector.dart';
import 'package:hive_flutter/hive_flutter.dart';

class MeditationTimerView extends StatefulWidget {
  const MeditationTimerView({super.key});

  @override
  State<MeditationTimerView> createState() => _MeditationTimerViewState();
}

class _MeditationTimerViewState extends State<MeditationTimerView>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  Timer? _timer;
  int _selectedDurationMinutes = 10;
  int _remainingSeconds = 600; // 10 minutes * 60
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isInitializing = true;
  MindfulnessSessionType _selectedSessionType =
      MindfulnessSessionType.meditation;
  
  final List<int> _durations = [5, 10, 15, 20, 30, 60];
  Box? _box;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: _remainingSeconds),
    );
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize Notification Service
    await SystemNotificationService().initialize();
    await SystemNotificationService().requestPermissions();

    // Initialize Hive
    _box = await Hive.openBox('meditation_timer');
    
    _restoreState();
    
    setState(() {
      _isInitializing = false;
    });
  }

  void _restoreState() {
    final int? savedEndTimeMillis = _box?.get('endTime');
    final int? savedDuration = _box?.get('duration');
    final int? savedRemaining = _box?.get('remaining'); // For paused state
    
    if (savedDuration != null) {
      _selectedDurationMinutes = savedDuration;
    }

    if (savedEndTimeMillis != null) {
      // Timer was running
      final endTime = DateTime.fromMillisecondsSinceEpoch(savedEndTimeMillis);
      final now = DateTime.now();
      
      if (now.isBefore(endTime)) {
        // Still running
        final difference = endTime.difference(now);
        _remainingSeconds = difference.inSeconds;
        _isRunning = true;
        _isPaused = false;
        
        // Re-sync controller
        _controller.duration = Duration(minutes: _selectedDurationMinutes);
        final elapsed = (_selectedDurationMinutes * 60) - _remainingSeconds;
        _controller.value = elapsed / (_selectedDurationMinutes * 60);
        _controller.forward(from: _controller.value);

        _startTicker();
      } else {
        // Finished while closed
        _remainingSeconds = 0;
        _isRunning = false;
        _isPaused = false;
        _controller.value = 1.0;
        _clearPersistence();
        // Notification should have fired already
      }
    } else if (savedRemaining != null) {
      // Timer was paused
      _remainingSeconds = savedRemaining;
      _isRunning = true;
      _isPaused = true;
      
       _controller.duration = Duration(minutes: _selectedDurationMinutes);
       final elapsed = (_selectedDurationMinutes * 60) - _remainingSeconds;
       _controller.value = elapsed / (_selectedDurationMinutes * 60);
    } else {
      // Fresh start
      _resetTimerState(_selectedDurationMinutes);
    }
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _isRunning = false;
          _isPaused = false;
          _clearPersistence(); // Clear saved state
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meditation session completed. Namaste.'),
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // Handle app lifecycle to update UI if needed
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check timer state when app comes to foreground
      if (_isRunning && !_isPaused) {
        _restoreState(); 
      }
    }
  }

  void _resetTimer([int? newDurationMinutes]) {
    _timer?.cancel();
    _clearPersistence();
    SystemNotificationService().cancelNotification(1); // Cancel any scheduled
    
    setState(() {
      _resetTimerState(newDurationMinutes);
    });
  }
  
  void _resetTimerState(int? newDurationMinutes) {
    if (newDurationMinutes != null) {
      _selectedDurationMinutes = newDurationMinutes;
    }
    _remainingSeconds = _selectedDurationMinutes * 60;
    _isRunning = false;
    _isPaused = false;
    _controller.duration = Duration(seconds: _remainingSeconds);
    _controller.value = 0.0;
  }

  Future<void> _startTimer() async {
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });
    
    // Resume animation
    _controller.duration = Duration(seconds: _selectedDurationMinutes * 60); // Ensure duration is correct base
    _controller.forward(from: _controller.value);
    
    final now = DateTime.now();
    final endTime = now.add(Duration(seconds: _remainingSeconds));

    // Persist State
    _box?.put('endTime', endTime.millisecondsSinceEpoch);
    _box?.put('duration', _selectedDurationMinutes);
    _box?.put('remaining', null); // Clear paused state

    // Write Health Connect Record
    try {
       healthConnector.writeRecord(
        MindfulnessSessionRecord(
          startTime: now,
          endTime: endTime,
          sessionType: _selectedSessionType,
          metadata: Metadata.internal(
            recordingMethod: RecordingMethod.manualEntry,
          ),
        ),
      );
    } catch (e) {
      print("Health Connect Error: $e");
    }

    // Schedule Notification
    await SystemNotificationService().scheduleNotification(
      id: 1,
      title: 'Meditation Complete',
      body: 'Great job! Your session is finished.',
      scheduledTime: endTime,
    );

    _startTicker();
  }

  Future<void> _pauseTimer() async {
    _timer?.cancel();
    _controller.stop();
    SystemNotificationService().cancelNotification(1); // Cancel scheduled notification
    
    setState(() {
      _isPaused = true;
    });

    // Save Pause State
    _box?.put('endTime', null);
    _box?.put('remaining', _remainingSeconds);
    _box?.put('duration', _selectedDurationMinutes);
  }
  
  void _clearPersistence() {
    _box?.delete('endTime');
    _box?.delete('remaining');
    _box?.delete('duration');
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  String _formatSessionType(MindfulnessSessionType type) {
    final text = type.toString().split('.').last;
    return text[0].toUpperCase() + text.substring(1).replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // Timer Display
          SizedBox(
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background Circle
                SizedBox(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                    value: 1.0, 
                    strokeWidth: 12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.grey.shade100,
                    ),
                  ),
                ),
                // Progress Circle
                SizedBox(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                    value: 1.0 - _controller.value, // Invert so it depletes
                    strokeWidth: 12,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(_remainingSeconds),
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w300,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRunning
                          ? (_isPaused ? 'Paused' : 'Meditating')
                          : 'Ready',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Duration Selector & Session Type (only when not running or paused)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: (!_isRunning && !_isPaused) ? Column(
              key: const ValueKey('settings'),
              children: [
                const SizedBox(height: 32),
                _buildSectionTitle('Duration (Minutes)'),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _durations.map((duration) {
                      final isSelected = _selectedDurationMinutes == duration;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text('$duration'),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              _resetTimer(duration);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                const SizedBox(height: 24),
                _buildSectionTitle('Session Type'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<MindfulnessSessionType>(
                      value: _selectedSessionType,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down_rounded),
                      items: MindfulnessSessionType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(_formatSessionType(type)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedSessionType = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ) : const SizedBox(height: 48, key: ValueKey('empty')),
          ),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isRunning || _isPaused)
                Padding(
                  padding: const EdgeInsets.only(right: 24.0),
                  child: IconButton.filledTonal(
                    onPressed: () {
                      _resetTimer();
                    },
                    icon: const Icon(Icons.stop_rounded),
                    iconSize: 32,
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              
              IconButton.filled(
                onPressed: _isRunning && !_isPaused ? _pauseTimer : _startTimer,
                icon: Icon(
                  _isRunning && !_isPaused ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                iconSize: 48,
                style: IconButton.styleFrom(padding: const EdgeInsets.all(24)),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
