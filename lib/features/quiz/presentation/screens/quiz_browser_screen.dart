import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../../../shared/widgets/safe_area_scaffold.dart';

/// A question count read from a cursor-paginated endpoint.
///
/// The questions endpoint publishes no `total`, only `has_more`, so [rows] is
/// what one page returned. When [isLowerBound] is true more rows exist beyond
/// it and the UI renders "100+" instead of a false exact figure.
@immutable
class QuestionCount {
  const QuestionCount({required this.rows, required this.isLowerBound});

  final int rows;
  final bool isLowerBound;

  String get questionsLabel => isLowerBound ? '$rows+ questions' : '$rows questions';
}

/// Browses the server-side quiz catalog via the real endpoints:
///  - `GET /api/v1/quiz/courses` — active courses (public catalog)
///  - `GET /api/v1/quiz/courses/{course}/categories` — course topics
///  - `GET /api/v1/quiz/courses/{course}/questions?category_id&per_page`
///
/// Level 1 lists courses; tapping drills into the course's categories with
/// live question counts from the paginated questions endpoint.
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
  late Future<Object> _future; // List<QuizCourseEntry> | List<QuizCategoryEntry>

  @override
  void initState() {
    super.initState();
    _future = _loadCourses();
  }

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

  Future<List<QuizCourseEntry>> _loadCourses() async {
    final dio = DioClient.instance.dio;
    final res = await dio.get<Map<String, dynamic>>('/quiz/courses');
    final data = res.data?['data'] as List? ?? const [];
    return data
        .cast<Map<String, dynamic>>()
        .map(QuizCourseEntry.fromJson)
        .toList();
  }

  Future<List<QuizCategoryEntry>> _loadCategories(QuizCourseEntry course) async {
    final dio = DioClient.instance.dio;
    final res = await dio.get<Map<String, dynamic>>(
      '/quiz/courses/${course.id}/categories',
    );
    final data = res.data?['data'] as List? ?? const [];
    return data
        .cast<Map<String, dynamic>>()
        .map(QuizCategoryEntry.fromJson)
        .toList();
  }

  /// Live question count for a category.
  ///
  /// The questions endpoint is **cursor** paginated and publishes **no total**
  /// (verified 2026-09-27: `pagination: {type:"cursor", per_page, count,
  /// has_more, next_cursor}` at the top level of the envelope). The previous
  /// implementation read `pagination.total`, which does not exist — so every
  /// category on every course rendered "0 questions" regardless of the real
  /// bank size. That is a lie in the worst direction: it told candidates their
  /// topic was empty when it was not.
  ///
  /// A cursor gives no total, so the only honest figure is the number of rows
  /// on one page, flagged as a lower bound when `has_more` is true. Returns
  /// null when we genuinely cannot tell, so the UI omits the count rather than
  /// printing 0.
  Future<QuestionCount?> _categoryQuestionCount(QuizCourseEntry course, QuizCategoryEntry cat) async {
    final dio = DioClient.instance.dio;
    final res = await dio.get<Map<String, dynamic>>(
      '/quiz/courses/${course.id}/questions',
      queryParameters: {'category_id': cat.id, 'per_page': 100},
    );
    final body = res.data;
    if (body == null) return null;

    // Rows may sit under data.items or data directly depending on envelope.
    final data = body['data'];
    final items = data is Map<String, dynamic>
        ? (data['items'] as List? ?? const [])
        : (data is List ? data : const <dynamic>[]);

    final pagination = body['pagination'] is Map<String, dynamic>
        ? body['pagination'] as Map<String, dynamic>
        : (data is Map<String, dynamic> && data['pagination'] is Map<String, dynamic>
            ? data['pagination'] as Map<String, dynamic>
            : null);
    if (pagination == null) return null;

    return QuestionCount(
      rows: items.length,
      isLowerBound: pagination['has_more'] as bool? ?? false,
    );
  }

  void _openCourse(QuizCourseEntry course) {
    setState(() {
      _course = course;
      _query = '';
      _searchCtrl.clear();
      _future = _loadCategories(course);
    });
  }

  void _backToCourses() {
    setState(() {
      _course = null;
      _query = '';
      _searchCtrl.clear();
      _future = _loadCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeAreaScaffold(
      appBar: CivilAppBar(
        title: _course == null ? 'Browse Quizzes' : 'Pick a Topic',
        leading: _course == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
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
                    ? 'Search courses…'
                    : 'Search topics…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
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
            child: FutureBuilder<Object>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return ErrorView(
                    message: snap.error.toString(),
                    onRetry: () => setState(() {
                      _future = _course == null ? _loadCourses() : _loadCategories(_course!);
                    }),
                  );
                }
                final query = _query.toLowerCase();
                if (_course == null) {
                  final courses =
                      snap.data as List<QuizCourseEntry>? ?? const [];
                  final filtered = query.isEmpty
                      ? courses
                      : courses
                          .where((c) =>
                              c.title.toLowerCase().contains(query) ||
                              c.description.toLowerCase().contains(query))
                          .toList();
                  if (filtered.isEmpty) {
                    return EmptyState(
                      title: query.isEmpty ? 'No courses yet' : 'No matches',
                      subtitle: query.isEmpty
                          ? 'Question sets for your exam are being prepared.'
                          : 'Try a different search',
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
                final cats =
                    snap.data as List<QuizCategoryEntry>? ?? const [];
                final filtered = query.isEmpty
                    ? cats
                    : cats.where((c) => c.name.toLowerCase().contains(query)).toList();
                if (filtered.isEmpty) {
                  return EmptyState(
                    title: query.isEmpty ? 'No topics yet' : 'No matches',
                    subtitle: query.isEmpty
                        ? 'This course has no active topics yet.'
                        : 'Try a different search',
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
                    countLoader: _categoryQuestionCount,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class QuizCourseEntry {
  const QuizCourseEntry({
    required this.id,
    required this.title,
    required this.description,
  });
  final String id;
  final String title;
  final String description;

  factory QuizCourseEntry.fromJson(Map<String, dynamic> j) => QuizCourseEntry(
        id: (j['id'] ?? '').toString(),
        title: (j['name'] ?? j['title'] ?? 'Course').toString(),
        description: (j['description'] ?? '').toString(),
      );
}

class QuizCategoryEntry {
  const QuizCategoryEntry({
    required this.id,
    required this.name,
  });
  final String id;
  final String name;

  factory QuizCategoryEntry.fromJson(Map<String, dynamic> j) =>
      QuizCategoryEntry(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? j['slug'] ?? 'Topic').toString(),
      );
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

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({
    required this.course,
    required this.entry,
    required this.countLoader,
  });
  final QuizCourseEntry course;
  final QuizCategoryEntry entry;
  final Future<QuestionCount?> Function(QuizCourseEntry, QuizCategoryEntry) countLoader;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  late Future<QuestionCount?> _count;

  @override
  void initState() {
    super.initState();
    _count = widget.countLoader(widget.course, widget.entry);
  }

  @override
  Widget build(BuildContext context) {
    final idx = widget.entry.id.hashCode.abs();
    final tileColor = _kCategoryColors[idx % _kCategoryColors.length];
    final icon = _kCategoryIcons[idx % _kCategoryIcons.length];
    return GlassmorphicCard(
      padding: const EdgeInsets.all(14),
      // go, not push — pushes into a shell-branch subroute silently no-op
      // on web builds of this app; go() is deep-linkable and equivalent here
      // because every screen carries its own back affordance.
      onTap: () => context.go(
        '/quiz/intro/${widget.course.id}?category=${widget.entry.id}',
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
                Text(widget.entry.name,
                    style:
                        const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                FutureBuilder<QuestionCount?>(
                  future: _count,
                  builder: (context, snap) {
                    // Loading, error and "the server told us nothing" all render
                    // as a dash or nothing — never "0 questions", which would
                    // claim the topic is empty.
                    if (snap.connectionState != ConnectionState.done) {
                      return const Text('', style: TextStyle(fontSize: 12));
                    }
                    if (snap.hasError || !snap.hasData || snap.data == null) {
                      return const Text(
                        'Count unavailable',
                        style: TextStyle(fontSize: 11, color: AppColors.textTertiaryLight),
                      );
                    }
                    final count = snap.data!;
                    return Text(
                      count.questionsLabel,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textTertiaryLight),
                    );
                  },
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
