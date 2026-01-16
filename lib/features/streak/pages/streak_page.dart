import 'dart:io';

import 'package:ai_health/features/streak/bloc/streak_bloc.dart';
import 'package:ai_health/features/streak/bloc/streak_event.dart';
import 'package:ai_health/features/streak/bloc/streak_state.dart';
import 'package:ai_health/features/streak/models/streak_day.dart';
import 'package:ai_health/features/streak/utils/streak_color_util.dart';
import 'package:ai_health/features/streak/widgets/photo_gallery_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class StreakPage extends StatefulWidget {
  final String userId;

  const StreakPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<StreakPage> createState() => _StreakPageState();
}

class _StreakPageState extends State<StreakPage> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StreakBloc>().add(FetchStreakDataEvent(widget.userId));
    });
  }

  Future<void> _handleDateTap(DateTime date, List<String> photoPaths) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: ListView(
              controller: scrollController,
              children: [
                Text(
                  'Entries for ${date.day}/${date.month}/${date.year}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                PhotoGalleryWidget(
                  photoPaths: photoPaths,
                  onAddPhoto: () => _pickImage(date),
                  isReadOnly:
                      date.month != DateTime.now().month &&
                      date.day != DateTime.now().day &&
                      date.year != DateTime.now().year,
                  onRemovePhoto: (path) {
                    context.read<StreakBloc>().add(
                      RemovePhotoFromDayEvent(
                        userId: widget.userId,
                        date: date,
                        photoPath: path,
                      ),
                    );
                    Navigator.pop(
                      context,
                    ); // Close to refresh/avoid stale state
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickImage(DateTime date) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null) {
        if (!mounted) return;
        context.read<StreakBloc>().add(
          AddPhotoToDayEvent(
            userId: widget.userId,
            date: date,
            photoPath: image.path,
          ),
        );
        Navigator.pop(context); // Close sheet to refresh
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error capturing image: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Streak Tracker'), centerTitle: true),
      body: BlocConsumer<StreakBloc, StreakState>(
        listener: (context, state) {
          if (state is StreakError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is StreakLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is StreakLoaded) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Streak Summary Card
                  _buildStreakSummary(state),
                  const SizedBox(height: 16),
                  // Calendar
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SfCalendar(
                          view: CalendarView.month,
                          showNavigationArrow: true,
                          headerHeight: 50,
                          viewHeaderHeight: 40,
                          backgroundColor: Colors.white,
                          selectionDecoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          monthViewSettings: const MonthViewSettings(
                            appointmentDisplayMode:
                                MonthAppointmentDisplayMode.none,
                            showTrailingAndLeadingDates: false,
                          ),
                          monthCellBuilder:
                              (BuildContext context, MonthCellDetails details) {
                                final dayData = state.streakData.getDay(
                                  details.date,
                                );
                                return _buildCalendarCell(details, dayData);
                              },
                          onTap: (CalendarTapDetails details) {
                            if (details.targetElement ==
                                CalendarElement.calendarCell) {
                              final date = details.date!;
                              final dayData = state.streakData.getDay(date);
                              final now = DateTime.now();

                              _handleDateTap(date, dayData?.photoPaths ?? []);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          // Handle initial or other states
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildStreakSummary(StreakLoaded state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Streak',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${state.streakData.currentStreak} Days',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCell(MonthCellDetails details, StreakDay? dayData) {
    final bool isToday =
        details.date.year == DateTime.now().year &&
        details.date.month == DateTime.now().month &&
        details.date.day == DateTime.now().day;

    Color? cellColor;
    if (dayData != null && dayData.hasPhotos) {
      if (dayData.status == StreakStatus.consistent) {
        cellColor = Colors.green.shade100;
      } else if (dayData.status == StreakStatus.active) {
        cellColor = Colors.orange.shade100;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: cellColor,
        border: isToday
            ? Border.all(color: Colors.blue, width: 2)
            : Border.all(color: Colors.grey.shade100, width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            details.date.day.toString(),
            style: TextStyle(
              color: details.date.month == details.visibleDates[0].month
                  ? Colors.black87
                  : Colors.grey,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (dayData != null && dayData.hasPhotos)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: dayData.status == StreakStatus.consistent
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
        ],
      ),
    );
  }
}
