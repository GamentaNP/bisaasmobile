import '../../domain/entities/learning.dart';

class LearningTrackDto {
  const LearningTrackDto({required this.id, required this.slug, required this.name, this.description});
  factory LearningTrackDto.fromJson(Map<String, dynamic> j) => LearningTrackDto(
        id: (j['id'] ?? j['slug'] ?? '') as String,
        slug: (j['slug'] ?? '') as String,
        name: (j['name'] ?? j['title'] ?? '') as String,
        description: j['description'] as String?,
      );
  final String id;
  final String slug;
  final String name;
  final String? description;
  LearningTrack toDomain() => LearningTrack(id: id, slug: slug, name: name, description: description);
}

class TodayPlanDto {
  const TodayPlanDto({required this.id, required this.title, this.tasks = const []});
  factory TodayPlanDto.fromJson(Map<String, dynamic> j) {
    final rawTasks = j['tasks'] ?? j['items'] ?? j['plan'] ?? [];
    final tasks = rawTasks is List ? rawTasks.map((e) => e is String ? e : (e is Map ? (e['title'] ?? e.toString()).toString() : e.toString())).toList() : <String>[];
    return TodayPlanDto(
      id: (j['id'] ?? j['plan_id'] ?? 'today') as String,
      title: (j['title'] ?? j['name'] ?? 'Today') as String,
      tasks: tasks.cast<String>(),
    );
  }
  final String id;
  final String title;
  final List<String> tasks;
  TodayPlan toDomain() => TodayPlan(id: id, title: title, tasks: tasks);
}

class ReviewItemDto {
  const ReviewItemDto({required this.id, required this.questionId, required this.dueAt});
  factory ReviewItemDto.fromJson(Map<String, dynamic> j) => ReviewItemDto(
        id: (j['id'] ?? '') as String,
        questionId: (j['question_id'] ?? j['questionId'] ?? '') as String,
        dueAt: DateTime.tryParse((j['due_at'] ?? j['dueAt'] ?? '').toString()) ?? DateTime.now(),
      );
  final String id;
  final String questionId;
  final DateTime dueAt;
  ReviewItem toDomain() => ReviewItem(id: id, questionId: questionId, dueAt: dueAt);
}
