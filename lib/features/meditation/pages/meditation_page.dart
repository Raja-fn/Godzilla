import 'package:ai_health/features/meditation/bloc/meditation_bloc.dart';
import 'package:ai_health/features/meditation/data/meditation_repository.dart';
import 'package:ai_health/features/meditation/widgets/meditation_timer_view.dart';
import 'package:ai_health/features/meditation/widgets/video_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MeditationPage extends StatelessWidget {
  const MeditationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => MeditationRepository(),
      child: BlocProvider(
        create: (context) =>
            MeditationBloc(repository: context.read<MeditationRepository>())
              ..add(LoadMeditationContent()),
        child: const _MeditationView(),
      ),
    );
  }
}

class _MeditationView extends StatelessWidget {
  const _MeditationView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meditation'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Timer'),
              Tab(text: 'Tutorials'),
              Tab(text: 'Beats'),
            ],
          ),
        ),
        body: BlocBuilder<MeditationBloc, MeditationState>(
          builder: (context, state) {
            if (state.status == MeditationStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state.status == MeditationStatus.failure) {
              return Center(child: Text('Error: ${state.errorMessage}'));
            } else if (state.status == MeditationStatus.success) {
              return TabBarView(
                children: [
                  const MeditationTimerView(),

                  _buildList(context, state.tutorials),
                  _buildList(context, state.beats),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List items) {
    if (items.isEmpty) {
      return const Center(child: Text('No content available'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return VideoListItem(item: item);
      },
    );
  }
}
