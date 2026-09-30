import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/corpus_availability.dart';
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
    return data
        .cast<Map<String, dynamic>>()
        .map(QuizCourseEntry.fromJson)
        .toList();
  }
  return const [];
});

class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  static const _courseColors = [
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFF0EA5E9),
    Color(0xFFEF4444),
    Color(0xFF10B981),
    Color(0xFF64748B),
    Color(0xFF22D3EE),
    Color(0xFFEAB308),
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
              subtitle:
                  'Civil engineering syllabi will appear here once published.',
            );
          }
          return CustomScrollView(
            slivers: [
              // Three separate corpora with their own readers, so none of them can
              // be presented as a course card.
              //
              // The names are Bisaas's and they are not interchangeable:
              //   Library  - PDFs/notes as soft form (/library/files)
              //   Books    - the Book Engine: real books with a reader
              //   Syllabus - the exam tree
              //
              // The bottom-nav branch was itself labelled "Library" while
              // routing here, so a user looking for the PDF library found this
              // tab with no way to reach it. The tab is now "Courses" and Library
              // is offered here under its own name.
              //
              // Each tile is gated on the corpus actually having content, so we
              // never ship a tab that can only render an empty reader. See
              // corpus_availability.dart for why both the operator's flag and a
              // real content probe are required.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
                  child: _CorpusTiles(),
                ),
              ),
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
                        onTap: () =>
                            context.go('/quiz/browse?course=${course.id}'),
                      );
                    },
                    childCount: courses.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    // A fixed main-axis extent rather than an aspect ratio: the
                    // cards hold a two-line title, a two-line description and a
                    // full-width button, and an aspect ratio computed from the
                    // tile width overflows by 13-31px on a 720px-wide phone.
                    // An extent is independent of width, so the same card height
                    // holds on a narrow phone and a tablet.
                    mainAxisExtent: 214,
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
  const _CourseCard({
    required this.course,
    required this.color,
    required this.onTap,
  });
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
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
          ),
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
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // Labelled for what it does. It opens the course's questions,
                // not the Syllabus Engine corpus, which is a separate resource
                // keyed on the syllabus version's public_id. A button promising a
                // syllabus and landing on a question list is the same kind of
                // dishonesty this pass has been removing elsewhere.
                child: const Text(
                  'Browse questions',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A corpus that has its own reader, so it cannot be presented as a course card.
class _CorpusTile extends StatelessWidget {
  const _CorpusTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.brand),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The three reader corpora, laid out in rows of two and gated on real content.
///
/// Renders nothing at all when every corpus is empty, so the screen does not
/// open on a wall of dead tiles. A corpus that is still probing renders
/// optimistically rather than flickering, because hiding a working feature for
/// the duration of a network call is worse than briefly showing an empty one.
class _CorpusTiles extends ConsumerWidget {
  const _CorpusTiles();

  static const _tiles =
      <({String code, IconData icon, String label, String route})>[
        (
          code: 'library',
          icon: Icons.folder_open_rounded,
          label: 'Library',
          route: '/library',
        ),
        (
          code: 'books',
          icon: Icons.menu_book_rounded,
          label: 'Books',
          route: '/books',
        ),
        (
          code: 'syllabus',
          icon: Icons.account_tree_rounded,
          label: 'Syllabus',
          route: '/syllabus',
        ),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offered = <({IconData icon, String label, String route})>[];
    for (final tile in _tiles) {
      // `value` is null while loading; treat that as "still assume offered" so
      // the tile does not appear and vanish on a slow connection.
      final status = ref.watch(corpusStatusProvider(tile.code)).value;
      if (status?.availability == CorpusAvailability.empty) continue;
      offered.add((icon: tile.icon, label: tile.label, route: tile.route));
    }

    if (offered.isEmpty) {
      return const SizedBox.shrink();
    }

    final rows = <Widget>[];
    for (var i = 0; i < offered.length; i += 2) {
      final pair = offered.skip(i).take(2).toList();
      rows.add(
        Row(
          children: [
            for (var j = 0; j < pair.length; j++) ...[
              if (j > 0) const SizedBox(width: 12),
              Expanded(
                child: _CorpusTile(
                  icon: pair[j].icon,
                  label: pair[j].label,
                  onTap: () => context.push(pair[j].route),
                ),
              ),
            ],
            // Keep a lone trailing tile at half width instead of stretching it.
            if (pair.length == 1) const Spacer(),
          ],
        ),
      );
      if (i + 2 < offered.length) rows.add(const SizedBox(height: 12));
    }

    return Column(children: rows);
  }
}
