import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../domain/entities/sandbox_attempt.dart';
import '../controllers/sandbox_attempt_controller.dart';

/// Verdict sheet for a finished guest sandbox attempt.
///
/// The endpoint requires the authenticated guest-sentinel credential AND the
/// client's `guest_session_id`; both are enforced in the data source. Only the
/// published verdicts are rendered — no answer key, share token or session
/// hash reaches this widget.
class SandboxAttemptResultsScreen extends ConsumerWidget {
  const SandboxAttemptResultsScreen({
    super.key,
    required this.attemptId,
    required this.guestSessionId,
  });

  final String attemptId;
  final String guestSessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final key = (attemptId: attemptId, guestSessionId: guestSessionId);
    final async = ref.watch(sandboxAttemptProvider(key));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.socialChallengeComplete)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: ErrorHandler.handle(e).message,
          onRetry: () => ref.invalidate(sandboxAttemptProvider(key)),
        ),
        data: (results) {
          final summary = results.summary;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.socialYouScored(summary.score),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(l10n.socialChallengeSummary(
                        summary.correct,
                        summary.wrong,
                        summary.skipped,
                        summary.total,
                      )),
                      const SizedBox(height: 6),
                      Text(
                        l10n.practiceGradedByServer,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (results.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.socialChallengeEmpty,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              else
                for (var i = 0; i < results.items.length; i++)
                  _VerdictTile(
                    number: i + 1,
                    item: results.items[i],
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _VerdictTile extends StatelessWidget {
  const _VerdictTile({required this.number, required this.item});

  final int number;
  final SandboxAttemptItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final verdict = item.isSkipped
        ? l10n.arcadeSkipped
        : item.isCorrect == true
            ? l10n.arcadeCorrect
            : l10n.arcadeWrong;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.practiceQuestionNumber(number),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 4),
            Text(item.questionText),
            if (item.givenAnswer != null)
              ListTile(
                dense: true,
                leading: const Icon(Icons.reply_outlined),
                title: Text(l10n.quizQuestionYourAnswer),
                trailing: Text('${item.givenAnswer}'),
              ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.fact_check_outlined),
              title: Text(l10n.socialStatus(verdict)),
            ),
            if (item.explanation != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.quizExplanation,
                      style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 4),
                  Text(item.explanation!),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
