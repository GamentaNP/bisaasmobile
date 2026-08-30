import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../domain/entities/learning.dart';
import '../controllers/learning_controller.dart';

/// Reviews due — GET /learning/reviews/due + POST /learning/reviews/{review}/grade
/// Outcomes: again | hard | good | easy (FSRS). Uses Idempotency-Key per grade.
/// Client never computes interval — server's SpacedRepetitionService does.
class ReviewsDueScreen extends ConsumerStatefulWidget {
  const ReviewsDueScreen({super.key});

  @override
  ConsumerState<ReviewsDueScreen> createState() => _ReviewsDueScreenState();
}

class _ReviewsDueScreenState extends ConsumerState<ReviewsDueScreen> {
  final Set<int> _gradingIds = {};

  Future<void> _grade(int reviewId, String outcome) async {
    setState(() => _gradingIds.add(reviewId));
    final res = await ref.read(learningControllerProvider.notifier).gradeReview(reviewId, outcome);
    if (!mounted) return;
    setState(() => _gradingIds.remove(reviewId));
    final err = ref.read(learningControllerProvider).gradeError;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.wrongRed));
    } else if (res != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Graded as $outcome — next due ${res.dueAt.toLocal().toIso8601String().split('T').first}'), backgroundColor: AppColors.correctGreen));
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(reviewsDueProvider);
    final ctrl = ref.watch(learningControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews Due'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => ref.invalidate(reviewsDueProvider)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(reviewsDueProvider);
          await ref.read(reviewsDueProvider.future).catchError((_) => <ReviewItem>[]);
        },
        child: reviewsAsync.when(
          data: (reviews) {
            if (reviews.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const EmptyState(title: 'No reviews due', subtitle: 'You are all caught up! FSRS will schedule the next reviews after you master new atoms.', icon: Icons.check_circle_rounded),
                  if (ctrl.gradeError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.wrongRed.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                      child: Text(ctrl.gradeError!, style: const TextStyle(color: AppColors.wrongRed, fontSize: 12)),
                    ),
                  ],
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final r = reviews[i];
                final grading = _gradingIds.contains(r.id) || ctrl.isGrading;
                return Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppColors.xpGold.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                              child: Icon(r.isOverdue ? Icons.warning_rounded : Icons.schedule_rounded, size: 16, color: r.isOverdue ? AppColors.wrongRed : AppColors.xpGold),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(r.knowledgeAtom?.title ?? 'Knowledge Atom #${r.knowledgeAtomId}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                Text('Review #${r.id} • atom ${r.knowledgeAtomId} • ${r.state ?? 'learning'}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ]),
                            ),
                            if (r.intervalIndex != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                                child: Text('I${r.intervalIndex}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                        if (r.knowledgeAtom?.content != null && r.knowledgeAtom!.content!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(r.knowledgeAtom!.content!, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.7), height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                        ],
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.event_rounded, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('Due ${r.dueAt.toLocal().toIso8601String().split('T').first}', style: TextStyle(fontSize: 11, color: r.isOverdue ? AppColors.wrongRed : Colors.grey, fontWeight: r.isOverdue ? FontWeight.bold : FontWeight.normal)),
                          const Spacer(),
                          if (r.lapses != null && r.lapses! > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.wrongRed.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                              child: Text('${r.lapses} lapses', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.wrongRed)),
                            ),
                        ]),
                        const SizedBox(height: 12),
                        if (grading)
                          const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                        else
                          Row(
                            children: [
                              _GradeButton(label: 'Again', color: AppColors.wrongRed, onTap: () => _grade(r.id, 'again')),
                              const SizedBox(width: 6),
                              _GradeButton(label: 'Hard', color: AppColors.streakOrange, onTap: () => _grade(r.id, 'hard')),
                              const SizedBox(width: 6),
                              _GradeButton(label: 'Good', color: AppColors.correctGreen, onTap: () => _grade(r.id, 'good')),
                              const SizedBox(width: 6),
                              _GradeButton(label: 'Easy', color: AppColors.brand, onTap: () => _grade(r.id, 'easy')),
                            ],
                          ),
                        const SizedBox(height: 6),
                        const Text('Grading uses Idempotency-Key — retries are safe. Next interval computed server-side (1/3/7/15/21-day ladder).', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(padding: const EdgeInsets.all(16), children: [ErrorView(message: e.toString(), onRetry: () => ref.invalidate(reviewsDueProvider))]),
        ),
      ),
    );
  }
}

class _GradeButton extends StatelessWidget {
  const _GradeButton({required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 10), textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        child: Text(label),
      ),
    );
  }
}
