import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/errors/error_handler.dart';
import 'screens/quiz_attempt_screen.dart';

/// Quiz home — server-driven course cards (no invented slugs: attempts can
/// only be started against ids the server knows, see QuizRemoteDataSource).
class QuizHomePage extends ConsumerStatefulWidget {
  const QuizHomePage({super.key});

  @override
  ConsumerState<QuizHomePage> createState() => _QuizHomePageState();
}

class _QuizHomePageState extends ConsumerState<QuizHomePage> {
  late Future<List<_QuizTopic>> _courses;

  @override
  void initState() {
    super.initState();
    _courses = _loadCourses();
  }

  Future<List<_QuizTopic>> _loadCourses() async {
    final res = await ref.read(dioProvider).get<Map<String, dynamic>>('/quiz/courses');
    final data = res.data?['data'];
    final items = data is List
        ? data
        : data is Map<String, dynamic>
            ? (data['items'] as List? ?? [])
            : <dynamic>[];
    return items.cast<Map<String, dynamic>>().map(_QuizTopic.fromCourse).toList();
  }

  void _reload() {
    setState(() => _courses = _loadCourses());
  }

  void _openQuiz(_QuizTopic topic) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizAttemptScreen(quizId: topic.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'Practice & Quiz',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<_QuizTopic>>(
                future: _courses,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _QuizEmpty(
                      icon: Icons.error_outline_rounded,
                      title: 'Could not load quiz',
                      message: ErrorHandler.handle(snapshot.error!).message,
                      actionLabel: 'Retry',
                      onAction: _reload,
                    );
                  }
                  final topics = snapshot.data ?? const [];
                  if (topics.isEmpty) {
                    return const _QuizEmpty(
                      icon: Icons.quiz_outlined,
                      title: 'No quizzes yet',
                      message: 'Question sets for your exam are being prepared. Check back soon.',
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    itemCount: topics.length,
                    itemBuilder: (context, index) {
                      final topic = topics[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _openQuiz(topic),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.brand.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.assignment_rounded,
                                    color: AppColors.brand,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        topic.title,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      if (topic.desc.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          topic.desc,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.play_circle_filled_rounded,
                                  color: AppColors.brand,
                                  size: 32,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizTopic {
  const _QuizTopic({required this.id, required this.title, required this.desc});

  factory _QuizTopic.fromCourse(Map<String, dynamic> c) => _QuizTopic(
        id: (c['id'] ?? '').toString(),
        title: (c['name'] ?? c['title'] ?? 'Quiz') as String,
        desc: (c['description'] ?? '') as String,
      );

  final String id;
  final String title;
  final String desc;
}

class _QuizEmpty extends StatelessWidget {
  const _QuizEmpty({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
