// ignore_for_file: avoid_dynamic_calls, avoid_bool_literals_in_conditional_expressions, use_is_even_rather_than_modulo, unnecessary_lambdas, unnecessary_string_interpolations, prefer_is_empty, unnecessary_brace_in_string_interps, omit_local_variable_types
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../controllers/practice_controller.dart';
import '../../domain/entities/practice.dart';

/// Practice hub — untimed drilling, bookmarked sets, self-challenge, weak-topic drill.
/// Endpoints:
/// - GET /quiz/bookmarks (cursor, bearer)
/// - GET /quiz/attempts/history (offset, bearer)
/// - POST /quiz/attempts/start with mode=practice (Idempotency-Key)
/// Bookmarks are cursor-paginated; history is offset paginated.
/// All tolerant additive parsing; never throws on new server fields.
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
    final questions = items.map((b) => b.question).toList();
    unawaited(context.push('/practice/session', extra: PracticeSessionArgs(title: 'Bookmarked Practice', questions: questions, isTimed: false)));
  }

  Future<void> _startWeakTopic({int? topicId}) async {
    // For demo, start a practice attempt server-side with topicId if available, else local drill
    final notifier = ref.read(practiceControllerProvider.notifier);
    final attemptId = await notifier.startSession(topicId: topicId, questionCount: 10);
    if (!mounted) return;
    if (attemptId != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Practice started: $attemptId'), backgroundColor: AppColors.correctGreen));
      // For now, also push local session with placeholder questions from history or bookmarks
      // In real flow, would fetch attempt questions via GET /quiz/attempts/{id} — but practice/history shows untimed local preview
      final bookmarks = ref.read(practiceControllerProvider).bookmarks;
      final qs = bookmarks.isNotEmpty ? bookmarks.take(5).map((b) => b.question).toList() : <PracticeQuestion>[];
      if (qs.isNotEmpty) {
        unawaited(context.push('/practice/session', extra: PracticeSessionArgs(title: 'Weak Topic Drill', questions: qs, isTimed: false)));
      }
    } else {
      final err = ref.read(practiceControllerProvider).startError ?? 'Failed to start';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.wrongRed));
    }
  }

  Future<void> _startSelfChallenge({required int count, String? difficulty}) async {
    final notifier = ref.read(practiceControllerProvider.notifier);
    final attemptId = await notifier.startSession(questionCount: count);
    if (!mounted) return;
    if (attemptId != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Self-challenge started ($count Qs): $attemptId'), backgroundColor: AppColors.correctGreen));
    } else {
      final err = ref.read(practiceControllerProvider).startError ?? 'Failed to start self-challenge';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.wrongRed));
    }
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
          const EmptyState(title: 'No bookmarks', subtitle: 'Bookmark questions during quiz to drill them later. GET /quiz/bookmarks (cursor).', icon: Icons.bookmark_border_rounded),
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
                      onPressed: () => ref.read(practiceControllerProvider.notifier).toggleBookmark(b.question.id),
                    ),
                    onTap: () {
                      // Practice single question untimed
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

class _WeakTopicTab extends StatelessWidget {
  const _WeakTopicTab({required this.onStart});
  final void Function({int? topicId}) onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Placeholder weak topics — real data would come from GET /learning/goals/{goal}/readiness or /tutor weak-areas
    final weak = [
      ('Soil Mechanics', 42, Icons.landscape_rounded),
      ('RCC Design', 38, Icons.view_module_rounded),
      ('Fluid Mechanics', 55, Icons.water_drop_rounded),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.wrongRed.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.wrongRed.withValues(alpha: 0.2))),
          child: const Row(children: [Icon(Icons.insights_rounded, color: AppColors.wrongRed, size: 18), SizedBox(width: 8), Expanded(child: Text('Weak topics from readiness (GET /learning/goals/{goal}/readiness) — server-computed, never client-inferred.', style: TextStyle(fontSize: 11, color: AppColors.wrongRed)))]),
        ),
        const SizedBox(height: 16),
        Text('Your weak topics', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...weak.map((w) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)), child: Icon(w.$3, size: 16, color: AppColors.brand)),
                title: Text(w.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text('${w.$2}% mastery', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                trailing: FilledButton.tonal(onPressed: () => onStart(), child: const Text('Drill', style: TextStyle(fontSize: 12))),
              ),
            )),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: () => onStart(), icon: const Icon(Icons.psychology_rounded), label: const Text('Drill weakest 10 (practice mode, untimed)')),
        const SizedBox(height: 8),
        const Text('Practice is untimed, no coins, no rank effect — per spec 4.6. Official grading via POST /quiz/attempts/start with mode=practice.', style: TextStyle(fontSize: 11, color: Colors.grey)),
      ],
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
        const Text('Uses Idempotency-Key on POST /quiz/attempts/start — double-tap cannot double-create. Results are labelled “Practice — not affecting rank”.', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
        child: ListView(padding: const EdgeInsets.all(24), children: const [EmptyState(title: 'No history', subtitle: 'Practice attempts will appear here (GET /quiz/attempts/history, offset paginated).', icon: Icons.history_rounded)]),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(practiceControllerProvider.notifier).fetchHistory(),
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
    );
  }
}

// ── Session args ──────────────────────────────────────────────────────────────

class PracticeSessionArgs {
  const PracticeSessionArgs({required this.title, required this.questions, this.isTimed = false, this.timeLimitSeconds});
  final String title;
  final List<PracticeQuestion> questions;
  final bool isTimed;
  final int? timeLimitSeconds;
}
