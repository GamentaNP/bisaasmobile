import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/l10n.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../../../shared/widgets/safe_area_scaffold.dart';
import '../../data/providers/quiz_catalog_providers.dart';
import '../../domain/entities/quiz_catalog.dart';

// The intro screen builds its fallback course row from these names; keeping
// them re-exported here avoids a presentation-to-presentation import and keeps
// the public surface unchanged after moving the models into the domain layer.
export '../../domain/entities/quiz_catalog.dart'
    show QuestionCount, QuizCategoryEntry, QuizCourseEntry;

/// Lower-bound counts are rendered with localised copy, so the label stays in
/// the presentation layer while the data itself is a pure domain value.
extension QuestionCountLabel on QuestionCount {
  String get questionsLabel => isLowerBound
      ? appL10n().quizQuestionsPlus(rows)
      : appL10n().quizQuestionsCount(rows);
}

/// Browses the server-side quiz catalog via the real endpoints:
///  - `GET /api/v1/quiz/courses` — active courses (public catalog)
///  - `GET /api/v1/quiz/courses/{course}/categories` — course topics
///  - `GET /api/v1/quiz/courses/{course}/questions?category_id&per_page`
///
/// Level 1 lists courses; tapping drills into the course's categories with
/// live question counts from the paginated questions endpoint. Every read is
/// now owned by the quiz data layer and watched through a provider — a failed
/// or drifted response is an error with retry, never an empty catalog.
class QuizBrowserScreen extends ConsumerStatefulWidget {
  const QuizBrowserScreen({super.key});

  @override
  ConsumerState<QuizBrowserScreen> createState() => _QuizBrowserScreenState();
}

class _QuizBrowserScreenState extends ConsumerState<QuizBrowserScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';
  QuizCourseEntry? _course;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _query = v.trim());
    });
  }

  void _openCourse(QuizCourseEntry course) {
    setState(() {
      _course = course;
      _query = '';
      _searchCtrl.clear();
    });
  }

  void _backToCourses() {
    setState(() {
      _course = null;
      _query = '';
      _searchCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final coursesAsync = ref.watch(quizCoursesProvider);
    final categoriesAsync = ref.watch(quizCategoriesProvider(_course?.id));
    return SafeAreaScaffold(
      appBar: CivilAppBar(
        title: _course == null ? l10n.quizBrowseQuizzes : l10n.quizPickTopic,
        leading: _course == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: l10n.commonGoBack,
                onPressed: _backToCourses,
              ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: _course == null
                    ? l10n.quizSearchCourses
                    : l10n.quizSearchTopics,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        tooltip: l10n.libraryClearSearch,
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                      ),
                border: OutlineInputBorder(borderRadius: AppRadii.mdAll),
                isDense: true,
              ),
            ),
          ),
          if (_course != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                _course!.description.isNotEmpty
                    ? _course!.description
                    : _course!.title,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondaryLight),
              ),
            ),
          Expanded(
            child: _course == null
                ? coursesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => ErrorView(
                      message: e.toString(),
                      onRetry: () => ref.invalidate(quizCoursesProvider),
                    ),
                    data: (courses) => _courseList(courses, l10n),
                  )
                : categoriesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => ErrorView(
                      message: e.toString(),
                      onRetry: () =>
                          ref.invalidate(quizCategoriesProvider(_course!.id)),
                    ),
                    data: (cats) => _categoryList(cats, l10n),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _courseList(List<QuizCourseEntry> courses, AppLocalizations l10n) {
    final query = _query.toLowerCase();
    final filtered = query.isEmpty
        ? courses
        : courses
            .where((c) =>
                c.title.toLowerCase().contains(query) ||
                c.description.toLowerCase().contains(query))
            .toList();
    if (filtered.isEmpty) {
      return EmptyState(
        title: query.isEmpty ? l10n.quizNoCoursesYet : l10n.quizNoMatches,
        subtitle: query.isEmpty
            ? l10n.quizSetsBeingPrepared
            : l10n.quizTryDifferentSearch,
        icon: Icons.search_off_rounded,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _CourseCard(
        entry: filtered[i],
        onTap: () => _openCourse(filtered[i]),
      ),
    );
  }

  Widget _categoryList(
    List<QuizCategoryEntry> cats,
    AppLocalizations l10n,
  ) {
    final query = _query.toLowerCase();
    final filtered = query.isEmpty
        ? cats
        : cats.where((c) => c.name.toLowerCase().contains(query)).toList();
    if (filtered.isEmpty) {
      return EmptyState(
        title: query.isEmpty ? l10n.quizNoTopicsYet : l10n.quizNoMatches,
        subtitle: query.isEmpty
            ? l10n.quizCourseNoActiveTopics
            : l10n.quizTryDifferentSearch,
        icon: Icons.category_rounded,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _CategoryCard(
        course: _course!,
        entry: filtered[i],
      ),
    );
  }
}

/// Display card for the intro screen: topic + live counts resolved from the
/// catalog endpoints. Not a wire model — duration is derived client-side.
class QuizListEntry {
  const QuizListEntry({
    required this.id,
    required this.title,
    required this.category,
    required this.questionCount,
    required this.durationMinutes,
    this.hasMoreQuestions = false,
    this.xpReward,
  });
  final String id;
  final String title;
  final String category;
  final int questionCount;
  final int durationMinutes;

  /// The questions endpoint is cursor-paginated with no total, so
  /// [questionCount] is one page's worth and this says whether more exist.
  final bool hasMoreQuestions;

  /// XP reward **only if the server published one**. Null means "we do not
  /// know" — the intro screen then says so instead of inventing
  /// `questionCount * 10`, which the previous version did.
  final int? xpReward;
}

/// Solid category fills + matching extrusion shadows (Duolongo style).
const _kCategoryColors = [
  Color(0xFF58CC02), // brand green
  Color(0xFF1CB0F6), // blue
  Color(0xFFCE82FF), // purple
  Color(0xFFFF9600), // orange
  Color(0xFFFF4B4B), // red
  Color(0xFFFFC800), // gold
];

const _kCategoryIcons = [
  Icons.quiz_rounded,
  Icons.calculate_rounded,
  Icons.architecture_rounded,
  Icons.construction_rounded,
  Icons.terrain_rounded,
  Icons.water_drop_rounded,
];

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.entry, required this.onTap});
  final QuizCourseEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tileColor = _kCategoryColors[0];
    return GlassmorphicCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: BorderRadius.circular(12),
              border: Border(
                bottom: BorderSide(
                  color: Colors.black.withValues(alpha: 0.18),
                  width: 3,
                ),
              ),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title,
                    style:
                        const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                if (entry.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textTertiaryLight),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  const _CategoryCard({
    required this.course,
    required this.entry,
  });
  final QuizCourseEntry course;
  final QuizCategoryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final countAsync = ref.watch(
      quizQuestionCountProvider(
        (courseId: course.id, categoryId: entry.id),
      ),
    );
    final idx = entry.id.hashCode.abs();
    final tileColor = _kCategoryColors[idx % _kCategoryColors.length];
    final icon = _kCategoryIcons[idx % _kCategoryIcons.length];
    return GlassmorphicCard(
      padding: const EdgeInsets.all(14),
      // go, not push — pushes into a shell-branch subroute silently no-op
      // on web builds of this app; go() is deep-linkable and equivalent here
      // because every screen carries its own back affordance.
      onTap: () => context.go(
        '/quiz/intro/${course.id}?category=${entry.id}',
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: BorderRadius.circular(12),
              border: Border(
                bottom: BorderSide(
                  color: Colors.black.withValues(alpha: 0.18),
                  width: 3,
                ),
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name,
                    style:
                        const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                countAsync.when(
                  // Loading and "server told us nothing" render as a dash or
                  // nothing — never "0 questions", which would claim the
                  // topic is empty.
                  loading: () => const Text('', style: TextStyle(fontSize: 12)),
                  error: (_, __) => Text(
                    l10n.quizCountUnavailable,
                    style: TextStyle(fontSize: 11, color: AppColors.textTertiaryLight),
                  ),
                  data: (count) => Text(
                    count.questionsLabel,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textTertiaryLight),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
