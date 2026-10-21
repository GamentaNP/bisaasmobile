// ignore_for_file: unnecessary_lambdas, unnecessary_string_interpolations
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../tutor/presentation/controllers/tutor_controller.dart';
import '../controllers/practice_controller.dart';
import '../practice_session_args.dart';
import '../../domain/entities/practice.dart';
// Re-exported so the router keeps resolving the session args from this
// screen, which is where they used to live.
export '../practice_session_args.dart';

/// Practice hub — untimed drilling, bookmarked sets, self-challenge, weak-topic drill.
/// Endpoints:
/// - GET /quiz/bookmarks (cursor, bearer)
/// - GET /quiz/attempts/history (cursor, bearer)
/// - GET /quiz/questions (cursor, bearer)
/// - POST /quiz/attempts with mode=practice + question_ids (Idempotency-Key)
/// - POST /quiz/attempts/{attempt}/answers
/// - PUT /quiz/attempts/{attempt}/completion
///
/// Every drill is a live server attempt seeded with the exact question ids the
/// screen shows, so the server grades what the user actually saw.
class PracticeBrowserScreen extends ConsumerStatefulWidget {
  const PracticeBrowserScreen({super.key});

  @override
  ConsumerState<PracticeBrowserScreen> createState() => _PracticeBrowserScreenState();
}

class _PracticeBrowserScreenState extends ConsumerState<PracticeBrowserScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    Future.microtask(() {
      ref.read(practiceControllerProvider.notifier).fetchBookmarks();
      ref.read(practiceControllerProvider.notifier).fetchHistory();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.bookmark_rounded), text: 'Bookmarks'),
            Tab(icon: Icon(Icons.psychology_rounded), text: 'Weak Topics'),
            Tab(icon: Icon(Icons.flash_on_rounded), text: 'Self Challenge'),
            Tab(icon: Icon(Icons.history_rounded), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _BookmarksTab(onPractice: _startBookmarkedPractice),
          _WeakTopicTab(onStart: _startWeakTopic),
          _SelfChallengeTab(onStart: _startSelfChallenge),
          _HistoryTab(),
        ],
      ),
    );
  }

  Future<void> _startBookmarkedPractice(List<BookmarkedQuestion> items) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No bookmarks to practice'), backgroundColor: AppColors.wrongRed));
      return;
    }

    // The drill is seeded with the bookmarked question ids, so the server
    // grades the questions the user actually bookmarked — not a random set
    // from the same category.
    final notifier = ref.read(practiceControllerProvider.notifier);
    final drill = await notifier.startBookmarkDrill(
      title: 'Bookmarked Practice',
      bookmarks: items,
    );
    if (!mounted) return;
    if (drill == null) {
      final err = ref.read(practiceControllerProvider).startError ?? 'Could not start the drill';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.wrongRed));
      return;
    }
    if (drill.undrillableCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${drill.undrillableCount} of ${items.length} bookmarks could not be '
            'drilled — the server does not publish their answer options yet.',
          ),
          backgroundColor: AppColors.streakOrange,
        ),
      );
    }
    unawaited(context.push('/practice/session', extra: PracticeSessionArgs.fromDrill(drill)));
  }

  /// Weak-topic drill.
  ///
  /// The server's weak-area analysis publishes a topic *name* (not an id), and
  /// `GET /quiz/questions` has no `topic_id` filter — so the topic is matched
  /// with the server's own text search, which it does honour. The questions
  /// that come back are seeded into a practice attempt, so the drill is graded
  /// by the server like any other.
  Future<void> _startWeakTopic({String? topic, int? topicId}) async {
    final notifier = ref.read(practiceControllerProvider.notifier);
    final drill = await notifier.startDrill(
      title: topic == null ? 'Practice Drill' : 'Drill: $topic',
      search: topic,
      count: 10,
    );
    if (!mounted) return;
    if (drill == null) {
      final err = ref.read(practiceControllerProvider).startError ?? 'Could not start the drill';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.wrongRed));
      return;
    }
    unawaited(context.push('/practice/session', extra: PracticeSessionArgs.fromDrill(drill)));
  }

  Future<void> _startSelfChallenge({required int count, String? difficulty}) async {
    final notifier = ref.read(practiceControllerProvider.notifier);
    final drill = await notifier.startDrill(
      title: 'Self Challenge',
      difficulty: difficulty,
      count: count,
    );
    if (!mounted) return;
    if (drill == null) {
      final err = ref.read(practiceControllerProvider).startError ?? 'Failed to start self-challenge';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.wrongRed));
      return;
    }
    unawaited(context.push('/practice/session', extra: PracticeSessionArgs.fromDrill(drill)));
  }
}

// ── Bookmarks tab ─────────────────────────────────────────────────────────────

class _BookmarksTab extends ConsumerWidget {
  const _BookmarksTab({required this.onPractice});
  final void Function(List<BookmarkedQuestion> items) onPractice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(practiceControllerProvider);

    if (state.isBookmarksLoading && state.bookmarks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.bookmarksError != null && state.bookmarks.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(16), child: ErrorView(message: state.bookmarksError!, onRetry: () => ref.read(practiceControllerProvider.notifier).fetchBookmarks())));
    }
    if (state.bookmarks.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(practiceControllerProvider.notifier).fetchBookmarks(),
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const EmptyState(title: 'No bookmarks', subtitle: 'Bookmark questions while you take a quiz and they will show up here for drilling later.', icon: Icons.bookmark_border_rounded),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(onPressed: () => context.go('/quiz'), icon: const Icon(Icons.quiz_rounded), label: const Text('Browse quizzes')),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(practiceControllerProvider.notifier).fetchBookmarks(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text('${state.bookmarks.length} bookmarked', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.brand)),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => onPractice(state.bookmarks),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Practice all'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: state.bookmarks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final b = state.bookmarks[i];
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.xpGold.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.bookmark_rounded, size: 16, color: AppColors.xpGold),
                    ),
                    title: Text(b.question.questionText.isEmpty ? 'Question #${b.question.id}' : b.question.questionText, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text('${b.question.type ?? 'mcq'} • difficulty ${b.question.difficulty ?? '-'} • ${b.question.points ?? 0} pts', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    trailing: IconButton(
                      icon: state.isTogglingBookmark ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.bookmark_remove_rounded),
                      // Removes the bookmark. The server's `POST` alias converges
                      // to `bookmarked: true` and cannot remove, so this calls
                      // `DELETE /quiz/bookmarks/{question}`.
                      onPressed: () => ref.read(practiceControllerProvider.notifier).removeBookmark(b.question.id),
                    ),
                    onTap: () {
                      // Review a single bookmark. The bookmarks endpoint does
                      // not publish answer options, so this is a read-through
                      // pass, not a drill — there is no attempt behind it.
                      context.push('/practice/session', extra: PracticeSessionArgs(title: 'Bookmarked', questions: [b.question], isTimed: false));
                    },
                  ),
                );
              },
            ),
          ),
          if (state.bookmarksPagination?.hasMore == true)
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: state.isBookmarksLoading
                    ? null
                    : () {
                        final next = state.bookmarksPagination?.nextCursor;
                        ref.read(practiceControllerProvider.notifier).fetchBookmarks(cursor: next, append: true);
                      },
                icon: const Icon(Icons.expand_more_rounded),
                label: const Text('Load more (cursor)'),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Weak topic tab ────────────────────────────────────────────────────────────

/// Weak topics, from the server's own analytics.
///
/// This tab previously rendered three hardcoded subjects with invented mastery
/// percentages ("Soil Mechanics 42%", "RCC Design 38%", "Fluid Mechanics 55%")
/// directly beneath a banner claiming the figures were "server-computed, never
/// client-inferred". Now it reads the tutor weak-areas endpoint and shows
/// nothing at all when the server has no analysis yet.
class _WeakTopicTab extends ConsumerWidget {
  const _WeakTopicTab({required this.onStart});

  /// The topic *name* is passed through so the drill is seeded with the
  /// server's own questions for that topic.
  final void Function({String? topic, int? topicId}) onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final weakAsync = ref.watch(tutorWeakAreasProvider);

    return weakAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 40, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'Could not load your weak topics',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'These are worked out from your own answer history. Nothing is '
                'shown unless it is real.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(tutorWeakAreasProvider),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (weak) {
        if (weak.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.insights_rounded, size: 40, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No weak topics yet',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'The server needs graded attempts before it can spot weak '
                    'areas. Take a quiz from the Quiz tab and check back.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.wrongRed.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.wrongRed.withValues(alpha: 0.2))),
              child: const Row(children: [Icon(Icons.insights_rounded, color: AppColors.wrongRed, size: 18), SizedBox(width: 8), Expanded(child: Text('Weak topics are worked out on our servers from your answer history, so nothing here is guessed.', style: TextStyle(fontSize: 11, color: AppColors.wrongRed)))]),
            ),
            const SizedBox(height: 16),
            Text('Your weak topics', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...weak.map((w) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.psychology_rounded, size: 16, color: AppColors.brand)),
                    title: Text(w.topic, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    // Only render the accuracy the server actually sent.
                    subtitle: Text(
                      [
                        if (w.accuracy != null) '${w.accuracy!.toStringAsFixed(0)}% accuracy',
                        if (w.attempts > 0) '${w.attempts} attempt${w.attempts == 1 ? '' : 's'}',
                      ].join(' • '),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    trailing: FilledButton.tonal(
                      onPressed: () => onStart(topic: w.topic, topicId: int.tryParse(w.topicId ?? '')),
                      child: const Text('Drill', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                )),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => onStart(),
              icon: const Icon(Icons.psychology_rounded),
              label: const Text('Drill 10 questions (practice mode, untimed)'),
            ),
            const SizedBox(height: 8),
            const Text('Practice is untimed and does not affect your rank or coin balance.', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        );
      },
    );
  }
}

// ── Self challenge tab ────────────────────────────────────────────────────────

class _SelfChallengeTab extends StatefulWidget {
  const _SelfChallengeTab({required this.onStart});
  final void Function({required int count, String? difficulty}) onStart;

  @override
  State<_SelfChallengeTab> createState() => _SelfChallengeTabState();
}

class _SelfChallengeTabState extends State<_SelfChallengeTab> {
  int _count = 10;
  String _difficulty = 'any';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Self Challenge', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Pick question count & difficulty — mirrors Elite Quiz self-challenge but sourced from adaptive engine.', style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 16),
        Text('Question count: $_count', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Slider(value: _count.toDouble(), min: 5, max: 30, divisions: 5, label: '$_count', onChanged: (v) => setState(() => _count = v.round())),
        const SizedBox(height: 8),
        Text('Difficulty', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['any', 'easy', 'medium', 'hard'].map((d) => ChoiceChip(label: Text(d), selected: _difficulty == d, onSelected: (_) => setState(() => _difficulty = d))).toList(),
        ),
        const SizedBox(height: 16),
        Consumer(builder: (context, ref, _) {
          final s = ref.watch(practiceControllerProvider);
          return FilledButton.icon(
            onPressed: s.isStartingSession ? null : () => widget.onStart(count: _count, difficulty: _difficulty == 'any' ? null : _difficulty),
            icon: s.isStartingSession ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.play_arrow_rounded),
            label: Text(s.isStartingSession ? 'Starting…' : 'Start challenge ($_count Qs)'),
          );
        }),
        const SizedBox(height: 8),
        Consumer(builder: (context, ref, _) {
          final err = ref.watch(practiceControllerProvider).startError;
          if (err == null) return const SizedBox.shrink();
          return Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.wrongRed.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)), child: Text(err, style: const TextStyle(color: AppColors.wrongRed, fontSize: 12)));
        }),
        const SizedBox(height: 16),
        const Text('Results are labelled as practice, so they never count towards your rank.', style: TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

// ── History tab ───────────────────────────────────────────────────────────────

class _HistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(practiceControllerProvider);

    if (state.isHistoryLoading && state.history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.historyError != null && state.history.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(16), child: ErrorView(message: state.historyError!, onRetry: () => ref.read(practiceControllerProvider.notifier).fetchHistory())));
    }
    if (state.history.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(practiceControllerProvider.notifier).fetchHistory(),
        child: ListView(padding: const EdgeInsets.all(24), children: const [EmptyState(title: 'No history', subtitle: 'Your completed practice sessions will appear here.', icon: Icons.history_rounded)]),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(practiceControllerProvider.notifier).fetchHistory(),
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final h = state.history[i];
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: (h.isCompleted ? AppColors.correctGreen : AppColors.streakOrange).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                      child: Icon(h.isCompleted ? Icons.check_circle_rounded : Icons.hourglass_empty_rounded, size: 16, color: h.isCompleted ? AppColors.correctGreen : AppColors.streakOrange),
                    ),
                    title: Text('Attempt #${h.id} • ${h.mode}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text('${h.status} • score ${h.score ?? '-'} • ${h.correctCount ?? 0}✓ ${h.wrongCount ?? 0}✗ ${h.skippedCount ?? 0}– • ${h.questionCount ?? '-'} Qs', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    trailing: Text(h.completedAt != null ? '${h.completedAt!.toLocal().toIso8601String().split('T').first}' : '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ),
                );
              },
            ),
          ),
          // Attempt history is cursor-paginated (`MOBILE_API_INTEGRATION_GUIDE.md`
          // §4.1), so there is no page number to jump to — only "next".
          if (state.historyPagination?.hasMore == true)
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: state.isHistoryLoading
                    ? null
                    : () {
                        final next = state.historyPagination?.nextCursor;
                        ref.read(practiceControllerProvider.notifier).fetchHistory(cursor: next, append: true);
                      },
                icon: const Icon(Icons.expand_more_rounded),
                label: const Text('Load more (cursor)'),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Session args ──────────────────────────────────────────────────────────────
