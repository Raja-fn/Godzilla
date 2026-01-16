class MeditationItem {
  final String title;
  final String url;
  final String thumbnailUrl;
  final String? duration;
  final bool isTutorial;

  const MeditationItem({
    required this.title,
    required this.url,
    required this.thumbnailUrl,
    this.duration,
    required this.isTutorial,
  });
}
