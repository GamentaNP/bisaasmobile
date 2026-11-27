import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../domain/entities/review.dart';
import '../controllers/review_controller.dart';

/// Per-question verdict sheet for one completed attempt.
///
/// `GET /quiz/attempts/{attempt}/review` applies the same release gate as the
/// results endpoint. A locked high-stakes attempt carries null verdicts,
/// scores and explanations — this screen never invents one locally.
class AttemptReviewScreen extends ConsumerWidget {
  const AttemptReviewScreen({required this.attemptId, super.key});

  final int attemptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(attemptReviewProvider(attemptId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.quizReviewTitle)),
      body: async.when(
        data: (review) {
          if (!review.policy.answersVisible || review.policy.locked) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                EmptyState(
                  title: l10n.quizReviewTitle,
                  subtitle: l10n.reviewAnswersLocked,
                  icon: Icons.lock_outline_rounded,
                ),
              ],
            );
          }
          if (review.items.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                EmptyState(
                  title: l10n.quizReviewEmpty,
                  icon: Icons.question_answer_rounded,
                ),
              ],
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(attemptReviewProvider(attemptId));
              await ref
                  .read(attemptReviewProvider(attemptId).future)
                  .catchError((_) => const AttemptReview(
                        attemptId: -1,
                        status: '',
                        policy: ReviewPolicy(
                          answersVisible: false,
                          locked: true,
                          isHighStakes: false,
                          releaseMode: '',
                          released: false,
                        ),
                        items: [],
                      ));
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: review.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _VerdictTile(item: review.items[i], index: i + 1),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ErrorView(
              message: ErrorHandler.handle(e).message,
              onRetry: () => ref.invalidate(attemptReviewProvider(attemptId)),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerdictTile extends StatelessWidget {
  const _VerdictTile({required this.item, required this.index});

  final AttemptReviewItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final verdict = item.verdict;
    final verdictColor = switch (verdict) {
      'correct' => AppColors.correctGreen,
      'wrong' => AppColors.wrongRed,
      'skipped' => AppColors.streakOrange,
      _ => null,
    };
    final verdictLabel = switch (verdict) {
      'correct' => l10n.arcadeCorrect,
      'wrong' => l10n.arcadeWrong,
      'skipped' => l10n.arcadeSkipped,
      _ => null,
    };

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.quizReviewQuestionNumber(index),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (verdictLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: verdictColor?.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      verdictLabel,
                      style: TextStyle(
                        color: verdictColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (item.questionText != null && item.questionText!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(item.questionText!, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 8),
            Text(
              l10n.quizReviewYourAnswer,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.givenAnswer == null || item.givenAnswer!.isEmpty
                  ? l10n.quizReviewNotAnswered
                  : item.givenAnswer!,
              style: theme.textTheme.bodyMedium,
            ),
            if (item.scoreAwarded != null) ...[
              const SizedBox(height: 6),
              Text(
                l10n.practiceScore(item.scoreAwarded!),
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (item.explanation != null && item.explanation!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                l10n.quizExplanation,
                style: theme.textTheme.labelSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(item.explanation!, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
