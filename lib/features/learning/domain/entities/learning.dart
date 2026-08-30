import 'package:meta/meta.dart';

@immutable
class LearningTrack {
  const LearningTrack({required this.id, required this.slug, required this.name, this.description});
  final String id;
  final String slug;
  final String name;
  final String? description;
}

@immutable
class LearningGoal {
  const LearningGoal({required this.id, required this.trackId, this.progress = 0});
  final String id;
  final String trackId;
  final double progress;
}

@immutable
class TodayPlan {
  const TodayPlan({required this.id, required this.title, this.tasks = const []});
  final String id;
  final String title;
  final List<String> tasks;
}

@immutable
class ReviewItem {
  const ReviewItem({required this.id, required this.questionId, required this.dueAt});
  final String id;
  final String questionId;
  final DateTime dueAt;
}

@immutable
class TutorMessage {
  const TutorMessage({required this.role, required this.content});
  final String role; // user / assistant
  final String content;
}
