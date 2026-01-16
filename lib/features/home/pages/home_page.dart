import 'package:ai_health/features/auth/pages/login_page.dart';
import 'package:ai_health/features/form/pages/form_page.dart';
import 'package:ai_health/features/home/widgets/feature_card.dart';
import 'package:ai_health/features/meditation/pages/meditation_page.dart';
import 'package:ai_health/features/nutrition/pages/nutrition_page.dart';
import 'package:ai_health/features/permissions/pages/permissions_page.dart';
import 'package:ai_health/features/streak/pages/streak_page.dart';
import 'package:ai_health/features/step/pages/step_page.dart';
import 'package:ai_health/features/hydration/pages/hydration_page.dart';
import 'package:ai_health/features/sleep/pages/sleep_page.dart';
import 'package:ai_health/features/vitals/pages/vitals_page.dart';
import 'package:ai_health/features/workouts/pages/workouts_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_health/features/hydration/bloc/hydration_bloc.dart';
import 'package:ai_health/main.dart' show healthConnector;
import 'package:ai_health/services/permissions_service.dart';
import 'package:ai_health/services/profile_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ProfileService _profileService;
  late PermissionsService _permissionsService;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(supabaseClient: Supabase.instance.client);
    _permissionsService = PermissionsService(healthConnector: healthConnector);
    _checkProfileCompletion();
  }

  /// Check if profile is completed, redirect to form if not
  Future<void> _checkProfileCompletion() async {
    try {
      final isProfileCompleted = await _profileService.isProfileCompleted();

      if (!mounted) return;

      if (!isProfileCompleted) {
        // Redirect to form page if profile is not completed
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const FormPage()),
        );
      } else {
        // Profile completed, check permissions
        _checkPermissionsCompletion();
      }
    } catch (e) {
      developer.log('Error checking profile: $e', error: e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error checking profile: $e')));
    }
  }

  /// Check if all available permissions are granted
  /// If not all are granted, redirect to permissions page
  Future<void> _checkPermissionsCompletion() async {
    try {
      developer.log(
        'HomePage._checkPermissionsCompletion - Starting permissions check',
      );

      final allPermissionsGranted = await _permissionsService
          .areAllPermissionsGranted();

      if (!mounted) return;

      developer.log(
        'HomePage._checkPermissionsCompletion - All permissions granted: $allPermissionsGranted',
      );

      if (!allPermissionsGranted) {
        // Redirect to permissions page if not all permissions are granted
        developer.log(
          'HomePage._checkPermissionsCompletion - Redirecting to PermissionsPage',
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PermissionsPage()),
        );
      } else {
        developer.log(
          'HomePage._checkPermissionsCompletion - All permissions granted, showing home',
        );
      }
    } catch (e) {
      developer.log('Error checking permissions: $e', error: e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error checking permissions: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Hi " +
              "${Supabase.instance.client.auth.currentUser!.userMetadata!["name"]}!!!"
                  .toUpperCase()
                  .split(" ")[0] +
              "!!!",
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          height: 12,
          child: const CircleAvatar(child: Icon(Icons.person), radius: 12),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Dashboard',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  FeatureCard(
                    title: 'Nutrition',
                    icon: Icons.restaurant_menu,
                    color: Colors.green,
                    onTap: () {
                      final userId =
                          Supabase.instance.client.auth.currentUser?.id;
                      if (userId != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => NutritionPage(userId: userId),
                          ),
                        );
                      }
                    },
                  ),
                  FeatureCard(
                    title: 'Meditation',
                    icon: Icons.self_improvement,
                    color: Colors.purple,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const MeditationPage(),
                        ),
                      );
                    },
                  ),
                  FeatureCard(
                    title: 'Hydration',
                    icon: Icons.water_drop,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BlocProvider(
                            create: (context) => HydrationBloc(),
                            child: const HydrationPage(),
                          ),
                        ),
                      );
                    },
                  ),
                  FeatureCard(
                    title: 'Streak',
                    icon: Icons.local_fire_department,
                    color: Colors.orange,
                    onTap: () {
                      final userId =
                          Supabase.instance.client.auth.currentUser?.id;
                      if (userId != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => StreakPage(userId: userId),
                          ),
                        );
                      }
                    },
                  ),
                  FeatureCard(
                    title: 'Steps',
                    icon: Icons.directions_run,
                    color: Colors.red,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const StepPage(),
                        ),
                      );
                    },
                  ),
                  FeatureCard(
                    title: 'Sleep',
                    icon: Icons.bed,
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SleepPage(),
                        ),
                      );
                    },
                  ),
                  FeatureCard(
                    title: 'Vitals & Mood',
                    icon: Icons.monitor_heart,
                    color: Colors.pink,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const VitalsPage(),
                        ),
                      );
                    },
                  ),
                  FeatureCard(
                    title: 'Workouts',
                    icon: Icons.fitness_center,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const WorkoutsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
