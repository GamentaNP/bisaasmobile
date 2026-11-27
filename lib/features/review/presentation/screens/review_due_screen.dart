import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../domain/entities/review.dart';
import '../controllers/review_controller.dart';

/// Prompt-only due cards from `GET /quiz/review/due`.
///
/// Grading goes to `PUT /quiz/reviews/{id}/grade` with a stable
/// Idempotency-Key. The server owns SM-2 scheduling — this screen only sends
/// the quality and refreshes the queue after a successful write.
class ReviewDueScreen extends ConsumerStatefulWidget {
  const ReviewDueScreen({super.key});

  @override
  ConsumerState<ReviewDueScreen> createState() => _ReviewDueScreenState();
}

class _ReviewDueScreenState extends ConsumerState<ReviewDueScreen> {
  final Set<String> _gradingIds = <String>{};

  Future<void> _grade(ReviewCard card, int quality) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _gradingIds.add(card.id));
    final result = await ref.read(reviewGradeControllerProvider.notifier).grade(
          card.id,
          quality: quality,
          type: card.type,
        );
    if (!mounted) return;
    setState(() => _gradingIds.remove(card.id));

    final error = ref.read(reviewGradeControllerProvider).gradeError;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.wrongRed),
      );
      return;
    }
    if (result != null) {
      final date = result.dueAt == null
          ? l10n.quizSrsUnknownDate
          : result.dueAt!.toLocal().toIso8601String().split('T').first;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.quizSrsGradedNextDue(result.quality, date)),
          backgroundColor: AppColors.correctGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dueAsync = ref.watch(reviewDueProvider);
    final ctrl = ref.watch(reviewGradeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.quizSrsReviewsDueTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.quizSrsRefresh,
            onPressed: () => ref.invalidate(reviewDueProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(reviewDueProvider);
          await ref.read(reviewDueProvider.future).catchError((_) => <ReviewCard>[]);
        },
        child: dueAsync.when(
          data: (cards) {
            if (cards.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  EmptyState(
                    title: l10n.quizSrsNoReviewsDue,
                    subtitle: l10n.quizSrsAllCaughtUp,
                    icon: Icons.check_circle_rounded,
                  ),
                  if (ctrl.gradeError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      ctrl.gradeError!,
                      style: const TextStyle(color: AppColors.wrongRed, fontSize: 12),
                    ),
                  ],
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cards.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _ReviewCardTile(
                card: cards[i],
                grading: _gradingIds.contains(cards[i].id) || ctrl.isGrading,
                onGrade: (quality) => _grade(cards[i], quality),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ErrorView(
                message: ErrorHandler.handle(e).message,
                onRetry: () => ref.invalidate(reviewDueProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCardTile extends StatelessWidget {
  const _ReviewCardTile({
    required this.card,
    required this.grading,
    required this.onGrade,
  });

  final ReviewCard card;
  final bool grading;
  final void Function(int quality) onGrade;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
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
                  decoration: BoxDecoration(
                    color: AppColors.xpGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    card.isWord ? Icons.translate_rounded : Icons.quiz_rounded,
                    size: 16,
                    color: AppColors.xpGold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.content.trim().isEmpty
                            ? l10n.quizSrsUntitledCard(card.id)
                            : card.content,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        card.isWord
                            ? l10n.quizSrsCardKindWord
                            : l10n.quizSrsCardKindQuestion,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (card.options.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final option in card.options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${option.label}. ${option.text}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ),
            ],
            if (card.isWord && card.definition != null && card.definition!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l10n.quizSrsDefinition(card.definition!),
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ],
            if (card.isWord && card.example != null && card.example!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                l10n.quizSrsExample(card.example!),
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.event_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    l10n.quizSrsDueMeta(
                      card.overdueDays,
                      card.repetitions,
                      card.intervalDays,
                    ),
                    style: TextStyle(
                      fontSize: 11,
                      color: card.isOverdue
                          ? AppColors.wrongRed
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight:
                          card.isOverdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Text(
                  l10n.quizSrsDueDate(
                    card.dueAt.toLocal().toIso8601String().split('T').first,
                  ),
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (grading)
              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Row(
                children: [
                  _GradeButton(
                    label: l10n.quizSrsGradeAgain,
                    color: AppColors.wrongRed,
                    onTap: () => onGrade(ReviewQuality.again),
                  ),
                  const SizedBox(width: 6),
                  _GradeButton(
                    label: l10n.quizSrsGradeHard,
                    color: AppColors.streakOrange,
                    onTap: () => onGrade(ReviewQuality.hard),
                  ),
                  const SizedBox(width: 6),
                  _GradeButton(
                    label: l10n.quizSrsGradeGood,
                    color: AppColors.correctGreen,
                    onTap: () => onGrade(ReviewQuality.good),
                  ),
                  const SizedBox(width: 6),
                  _GradeButton(
                    label: l10n.quizSrsGradeEasy,
                    color: AppColors.brand,
                    onTap: () => onGrade(ReviewQuality.easy),
                  ),
                ],
              ),
            const SizedBox(height: 6),
            Text(
              l10n.quizSrsGradingNote,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeButton extends StatelessWidget {
  const _GradeButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 10),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        child: Text(label),
      ),
    );
  }
}
