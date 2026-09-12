// ignore_for_file: cast_nullable_to_non_nullable

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../quiz/presentation/screens/quiz_browser_screen.dart';

/// Courses — `GET /api/v1/quiz/courses` (public catalog, no auth required).
///
/// Previously showed 10 hardcoded fake courses with invented progress %.
/// Now fetches the real server catalog. Progress is not part of the public
/// catalog endpoint (it requires auth + per-user data via attempt history);
/// the card navigates to the Quiz Browser which shows real categories + counts.
final _coursesProvider = FutureProvider<List<QuizCourseEntry>>((ref) async {
  final dio = DioClient.instance.dio;
  final res = await dio.get<Map<String, dynamic>>('/quiz/courses');
  final data = res.data?['data'];
  if (data is List) {
    return data.cast<Map<String, dynamic>>().map(QuizCourseEntry.fromJson).toList();
  }
  return const [];
});

class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  static const _courseColors = [
    Color(0xFFF59E0B), Color(0xFF8B5CF6), Color(0xFF06B6D4),
    Color(0xFF0EA5E9), Color(0xFFEF4444), Color(0xFF10B981),
    Color(0xFF64748B), Color(0xFF22D3EE), Color(0xFFEAB308),
    Color(0xFFEC4899),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final coursesAsync = ref.watch(_coursesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Courses')),
      body: coursesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: 'Could not load courses. Check connection.',
          onRetry: () => ref.invalidate(_coursesProvider),
        ),
        data: (courses) {
          if (courses.isEmpty) {
            return const EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'No courses available',
              subtitle: 'Civil engineering syllabi will appear here once published.',
            );
          }
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    '${courses.length} syllabus tracks',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final course = courses[i];
                      final color = _courseColors[i % _courseColors.length];
                      return _CourseCard(
                        course: course,
                        color: color,
                        onTap: () => context.go('/quiz/browse?course=${course.id}'),
                      );
                    },
                    childCount: courses.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.92,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course, required this.color, required this.onTap});
  final QuizCourseEntry course;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.menu_book_rounded, size: 18, color: color),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, size: 18, color: color),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              course.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (course.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                course.description,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('View syllabus', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
