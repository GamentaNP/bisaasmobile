import '../../../l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/errors/error_handler.dart';
import '../../../shared/utils/display_name.dart';
import '../../../shared/widgets/page_controls.dart';

/// Course rows per page under the banners. The same catalog the Courses tab
/// paginates at 24; here the rows sit under two banners, so 10 per page keeps
/// one mode banner plus a course row pair above the fold.
const _coursesPerPage = 10;

/// Quiz home — server-driven course cards (no invented slugs: attempts can
/// only be started against ids the server knows, see QuizRemoteDataSource).
class QuizHomePage extends ConsumerStatefulWidget {
  const QuizHomePage({super.key});

  @override
  ConsumerState<QuizHomePage> createState() => _QuizHomePageState();
}

class _QuizHomePageState extends ConsumerState<QuizHomePage> {
  late Future<List<_QuizTopic>> _courses;
  int _page = 0;

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
    // go_router go, not a raw Navigator push — raw pushes inside the shell
    // branch render nothing on web; the route is deep-linkable either way.
    context.go('/quiz/${topic.id}');
  }

  /// The "how do I actually play this?" sheet. The five play modes are
  /// scattered across tabs (Daily and Battle live on the home tab; Worlds,
  /// Practice and Arcade here); one place names them all and says what each
  /// is for. Every row now has a destination — the Arcade row used to be the
  /// one that did not.
  void _showModesSheet() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final rows = <({IconData icon, String title, String body, String? route})>[
      (
        icon: Icons.public_rounded,
        title: l10n.quizPlayWorlds,
        body: l10n.modesWorldsBody,
        route: '/game/worlds',
      ),
      (
        icon: Icons.edit_note_rounded,
        title: l10n.quizPracticeDrill,
        body: l10n.modesPracticeBody,
        route: '/practice',
      ),
      (
        icon: Icons.local_fire_department_rounded,
        title: l10n.homeDaily,
        body: l10n.modesDailyBody,
        route: null,
      ),
      (
        icon: Icons.sports_kabaddi_rounded,
        title: l10n.homeBattle,
        body: l10n.modesBattleBody,
        route: '/battle',
      ),
      (
        icon: Icons.videogame_asset_rounded,
        title: l10n.modesArcadeTitle,
        body: l10n.modesArcadeBody,
        route: '/arcade',
      ),
    ];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.quizModesHelp,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: row.route == null
                        ? null
                        : () {
                            Navigator.of(sheetContext).pop();
                            context.go(row.route!);
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(row.icon, size: 22, color: AppColors.brand),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(row.title,
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(
                                  row.body,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (row.route != null)
                            Icon(Icons.chevron_right_rounded,
                                size: 20,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.4)),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(l10n.modesGotIt),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.quizHomeTitle,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.quizModesHelp,
                    onPressed: _showModesSheet,
                    icon: const Icon(Icons.help_outline_rounded),
                  ),
                ],
              ),
            ),
            // The world map is the primary, gamified path (chapters, stars,
            // bosses). The free-draft course list below is the alternative.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _WorldsBanner(onTap: () => context.go('/game/worlds')),
            ),
            // The practice drill (bookmarks, weak topics, self-challenge) is
            // the untimed, server-graded path. It has to be reachable from
            // the quiz tab — a shipped feature with no entry point is a
            // feature nobody has.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: _PracticeBanner(onTap: () => context.go('/practice')),
            ),
            // The arcade is the timed, scored counterpart to the untimed
            // practice drill. It gets a visible row rather than a mention in
            // the help sheet: the sheet used to advertise it with no
            // destination behind the row.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: _ArcadeBanner(onTap: () => context.go('/arcade')),
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
                      title: l10n.quizHomeLoadError,
                      message: ErrorHandler.handle(snapshot.error!).message,
                      actionLabel: l10n.retry,
                      onAction: _reload,
                    );
                  }
                  final topics = snapshot.data ?? const [];
                  if (topics.isEmpty) {
                    return _QuizEmpty(
                      icon: Icons.quiz_outlined,
                      title: l10n.quizHomeEmptyTitle,
                      message: l10n.quizHomeEmptyBody,
                    );
                  }
                  final totalPages =
                      (topics.length + _coursesPerPage - 1) ~/ _coursesPerPage;
                  final page = _page.clamp(0, totalPages - 1);
                  final start = page * _coursesPerPage;
                  final visible = topics.sublist(
                    start,
                    (start + _coursesPerPage).clamp(0, topics.length),
                  );
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final topic = visible[index];
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
                                      color: theme.colorScheme.outlineVariant
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.brand
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(12),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              humanizeName(topic.title),
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold),
                                            ),
                                            if (topic.desc.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                topic.desc,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: theme.colorScheme
                                                      .onSurface
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
                        ),
                      ),
                      PageControls(
                        current: page + 1,
                        total: totalPages,
                        onPrev: page > 0 ? () => setState(() => _page--) : null,
                        onNext: page < totalPages - 1
                            ? () => setState(() => _page++)
                            : null,
                      ),
                      const SizedBox(height: 8),
                    ],
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

/// Hero entry point to the world map — `GET /api/v1/quiz/game/worlds`.
class _WorldsBanner extends StatelessWidget {
  const _WorldsBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: AppColors.brand,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: const Border(bottom: BorderSide(color: AppColors.brandShadow, width: 4)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.public_rounded, color: Colors.white, size: 28),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.quizPlayWorlds,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
                      ),
                      SizedBox(height: 2),
                      Text(
                        l10n.quizPlayWorldsSubtitle,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.white, size: 26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary entry point to the untimed practice drill.
///
/// `POST /quiz/attempts` in `mode: practice` — graded by the server, but
/// with no leaderboard, no XP and no streak effect.
class _PracticeBanner extends StatelessWidget {
  const _PracticeBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: AppColors.brand.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.edit_note_rounded, color: AppColors.brand, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.quizPracticeDrill,
                      style: TextStyle(
                        color: AppColors.brand,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      l10n.quizPracticeDrillSubtitle,
                      style: TextStyle(color: AppColors.textTertiaryDark, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.brand, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Entry point to the arcade: three timed, server-scored run modes.
///
/// Purple rather than brand green so it reads as a different kind of activity
/// from the world map and the practice drill above it.
class _ArcadeBanner extends StatelessWidget {
  const _ArcadeBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: AppColors.violet.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.videogame_asset_rounded,
                  color: AppColors.violet, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.arcadeTitle,
                      style: TextStyle(
                        color: AppColors.violet,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      l10n.arcadeSubtitle,
                      style: TextStyle(
                          color: AppColors.textTertiaryDark, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.violet, size: 24),
            ],
          ),
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
