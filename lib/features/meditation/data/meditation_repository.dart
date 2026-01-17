import 'package:ai_health/features/meditation/data/meditation_item.dart';

class MeditationRepository {
  Future<List<MeditationItem>> getItems() async {
    // Return dummy data
    return const [
      // Tutorials
      MeditationItem(
        title: 'Meditation for Beginners',
        url: 'https://www.youtube.com/watch?v=inpok4MKVLM',
        thumbnailUrl: 'https://img.youtube.com/vi/inpok4MKVLM/0.jpg',
        duration: '10 min',
        isTutorial: true,
      ),
      MeditationItem(
        title: '10-Minute Meditation for Anxiety',
        url: 'https://www.youtube.com/watch?v=O-6f5wQXSu8',
        thumbnailUrl: 'https://img.youtube.com/vi/O-6f5wQXSu8/0.jpg',
        duration: '10 min',
        isTutorial: true,
      ),
       MeditationItem(
        title: 'Daily Calm 10 Minute Meditation',
        url: 'https://www.youtube.com/watch?v=ZToicYcHIOU',
        thumbnailUrl: 'https://img.youtube.com/vi/ZToicYcHIOU/0.jpg',
        duration: '10 min',
        isTutorial: true,
      ),

      // Beats / Music
      MeditationItem(
        title: 'Tibetan Healing Sounds',
        url: 'https://www.youtube.com/watch?v=Q5dU6serXkg',
        thumbnailUrl: 'https://img.youtube.com/vi/Q5dU6serXkg/0.jpg',
        duration: '1 Hour',
        isTutorial: false,
      ),
       MeditationItem(
        title: 'Positive Energy Music',
        url: 'https://www.youtube.com/watch?v=lWA2pjMjpBs',
        thumbnailUrl: 'https://img.youtube.com/vi/lWA2pjMjpBs/0.jpg',
        duration: '1 Hour',
        isTutorial: false,
      ),
    ];
  }
}
