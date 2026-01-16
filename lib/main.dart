import 'package:ai_health/features/auth/bloc/auth_bloc.dart' as auth_bloc;
import 'package:ai_health/features/auth/pages/login_page.dart';
import 'package:ai_health/features/form/bloc/form_bloc.dart';
import 'package:ai_health/features/form/pages/form_page.dart';
import 'package:ai_health/features/form/pages/survey_page.dart';
import 'package:ai_health/features/form/repo/form_repository.dart';
import 'package:ai_health/features/home/pages/home_page.dart';
import 'package:ai_health/features/permissions/pages/permissions_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health_connector/health_connector.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

late HealthConnector healthConnector;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('user_data');
  await Supabase.initialize(
    url: 'https://pwpqkqxbzkinycrstkkt.supabase.co',
    anonKey: 'sb_publishable_drUfi5zzXLXTwI9MGUGwVg_2Ws20Y9d',
  );
  healthConnector = await HealthConnector.create();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) =>
              FormRepository(supabaseClient: Supabase.instance.client),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                auth_bloc.AuthBloc(supabase: Supabase.instance.client)
                  ..add(auth_bloc.AuthCheckStatus()),
          ),
          BlocProvider(
            create: (context) =>
                FormBloc(formRepository: context.read<FormRepository>()),
          ),
        ],
        child: MaterialApp(
          title: 'AI Health',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          home: const _HomeRouter(),
        ),
      ),
    );
  }
}

class _HomeRouter extends StatelessWidget {
  const _HomeRouter();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<auth_bloc.AuthBloc, auth_bloc.AuthState>(
      builder: (context, authState) {
        if (authState is auth_bloc.AuthAuthenticated) {
          context.read<FormBloc>().add(CheckProfileCompletion());
          return BlocBuilder<FormBloc, AppFormState>(
            builder: (context, formState) {
              if (formState is AllDataCompleted) {
                // Both profile and survey are completed
                return HomePage();
              } else if (formState is ProfileAlreadyCompleted) {
                // Profile is completed, but survey is pending
                return const SurveyPage();
              } else if (formState is ProfileFormState) {
                // Profile form not completed yet
                return const FormPage();
              } else if (formState is FormFailure) {
                // Error occurred
                return Scaffold(
                  body: Center(child: Text('Error: ${formState.error}')),
                );
              } else {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
            },
          );
        } else if (authState is auth_bloc.AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
