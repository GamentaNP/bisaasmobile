import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../domain/entities/question_report.dart';
import '../../domain/entities/review.dart';
import '../controllers/review_controller.dart';

/// Per-question verdict sheet for one completed attempt.
///
/// `GET /quiz/attempts/{attempt}/review` applies the same release gate as the
/// results endpoint. A locked high-stakes attempt carries null verdicts,
/// scores and explanations — this screen never invents one locally.
///
/// Every unlocked question offers a report action. The report is a keyed write
/// to `/quiz/questions/{id}/reports`; this screen shows "sent" only for a
/// server-accepted result and keeps a retry on failure.
class AttemptReviewScreen extends ConsumerStatefulWidget {
  const AttemptReviewScreen({required this.attemptId, super.key});

  final int attemptId;

  @override
  ConsumerState<AttemptReviewScreen> createState() =>
      _AttemptReviewScreenState();
}

class _AttemptReviewScreenState extends ConsumerState<AttemptReviewScreen> {
  /// A failure visible inside the dialog does not also need a snackbar.
  bool _dialogOpen = false;

  void _onReportState(
    QuestionReportState? previous,
    QuestionReportState state,
  ) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final result = state.lastResult;
    if (result != null && result != previous?.lastResult) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.duplicate
                ? l10n.quizReportUpdated
                : l10n.quizReportSubmitted,
          ),
        ),
      );
    }
    if (!_dialogOpen && state.error != null && state.error != previous?.error) {
      _showFailure(l10n, state.error!);
    }
  }

  void _showFailure(AppLocalizations l10n, String reason) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.quizReportFailed(reason)),
        action: SnackBarAction(
          label: l10n.retry,
          onPressed: () =>
              ref.read(questionReportControllerProvider.notifier).retry(),
        ),
      ),
    );
  }

  Future<void> _openReportDialog(int questionId) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _dialogOpen = true);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ReportDialog(
        l10n: l10n,
        questionId: questionId,
        submit: (submission) => ref
            .read(questionReportControllerProvider.notifier)
            .submit(submission),
        currentError: () => ref.read(questionReportControllerProvider).error,
      ),
    );
    if (!mounted) return;
    setState(() => _dialogOpen = false);
    // A user can dismiss the dialog after a failed submit. The failure is then
    // still actionable from the snackbar instead of disappearing with it.
    final reportState = ref.read(questionReportControllerProvider);
    if (reportState.failedSubmission?.questionId == questionId &&
        reportState.error != null) {
      _showFailure(AppLocalizations.of(context)!, reportState.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(attemptReviewProvider(widget.attemptId));
    final reportState = ref.watch(questionReportControllerProvider);
    ref.listen(questionReportControllerProvider, _onReportState);

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
              ref.invalidate(attemptReviewProvider(widget.attemptId));
              await ref
                  .read(attemptReviewProvider(widget.attemptId).future)
                  .catchError(
                    (_) => const AttemptReview(
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
                    ),
                  );
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: review.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _VerdictTile(
                item: review.items[i],
                index: i + 1,
                isReported: reportState.reportedQuestionIds.contains(
                  review.items[i].questionId,
                ),
                onReport: () => _openReportDialog(review.items[i].questionId),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ErrorView(
              message: ErrorHandler.handle(e).message,
              onRetry: () =>
                  ref.invalidate(attemptReviewProvider(widget.attemptId)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Owns its text controllers for the full dialog lifetime, including the exit
/// animation: disposing them as soon as `showDialog` returns would let the
/// still-mounted `TextField` read a disposed controller.
class _ReportDialog extends StatefulWidget {
  const _ReportDialog({
    required this.l10n,
    required this.questionId,
    required this.submit,
    required this.currentError,
  });

  final AppLocalizations l10n;
  final int questionId;
  final Future<QuestionReportResult?> Function(QuestionReportSubmission) submit;
  final String? Function() currentError;

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _reasonController = TextEditingController();
  final _correctionController = TextEditingController();
  String? _category;
  bool _submitting = false;
  String _error = '';

  @override
  void dispose() {
    _reasonController.dispose();
    _correctionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = widget.l10n;
    final description = _reasonController.text.trim();
    if (_category == null ||
        description.length < QuestionReportCategory.minDescriptionLength ||
        description.length > QuestionReportCategory.maxLength) {
      setState(() => _error = l10n.quizReportInvalid);
      return;
    }
    setState(() {
      _submitting = true;
      _error = '';
    });
    final result = await widget.submit(
      QuestionReportSubmission(
        questionId: widget.questionId,
        category: _category!,
        description: description,
        suggestedCorrection: _correctionController.text.trim().isEmpty
            ? null
            : _correctionController.text.trim(),
      ),
    );
    if (result != null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    if (mounted) {
      setState(() {
        _submitting = false;
        _error = l10n.quizReportFailed(widget.currentError() ?? l10n.error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.quizReportTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: InputDecoration(
                labelText: l10n.quizReportCategory,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final value in QuestionReportCategory.values)
                  DropdownMenuItem<String>(
                    value: value,
                    child: Text(_reportCategoryLabel(l10n, value)),
                  ),
              ],
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _category = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              enabled: !_submitting,
              maxLines: 4,
              maxLength: QuestionReportCategory.maxLength,
              decoration: InputDecoration(
                labelText: l10n.quizReportDescription,
                helperText: l10n.quizReportDescriptionHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _correctionController,
              enabled: !_submitting,
              maxLines: 3,
              maxLength: QuestionReportCategory.maxLength,
              decoration: InputDecoration(
                labelText: l10n.quizReportCorrection,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                _error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(_error.isEmpty ? l10n.quizReportSubmit : l10n.retry),
        ),
      ],
    );
  }
}

String _reportCategoryLabel(AppLocalizations l10n, String value) =>
    switch (value) {
      QuestionReportCategory.incorrectAnswer => l10n.quizReportIncorrectAnswer,
      QuestionReportCategory.unclearQuestion => l10n.quizReportUnclearQuestion,
      QuestionReportCategory.typoGrammar => l10n.quizReportTypoGrammar,
      QuestionReportCategory.inappropriate => l10n.quizReportInappropriate,
      QuestionReportCategory.duplicate => l10n.quizReportDuplicate,
      QuestionReportCategory.outdated => l10n.quizReportOutdated,
      QuestionReportCategory.other => l10n.quizReportOther,
      _ => l10n.quizReportOther,
    };

class _VerdictTile extends StatelessWidget {
  const _VerdictTile({
    required this.item,
    required this.index,
    required this.isReported,
    required this.onReport,
  });

  final AttemptReviewItem item;
  final int index;
  final bool isReported;
  final VoidCallback onReport;

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
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (verdictLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
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
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(item.explanation!, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 6),
            if (isReported)
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.quizReportSent,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onReport,
                  icon: const Icon(Icons.flag_outlined, size: 16),
                  label: Text(l10n.quizReportAction),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
