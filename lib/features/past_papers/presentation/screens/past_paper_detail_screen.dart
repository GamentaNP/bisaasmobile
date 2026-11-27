import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/error_view.dart';
import '../controllers/past_papers_controller.dart';

/// Bounded detail from `GET /quiz/past-papers/{paper}`.
///
/// Only question text and numbering are shown: there is no local grading and
/// no answer key on this surface. Scans appear only when the server published
/// them (`can_show_scans`) and never when a page is marked as an answer key.
class PastPaperDetailScreen extends ConsumerWidget {
  const PastPaperDetailScreen({super.key, required this.paperId});

  final int paperId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(pastPaperDetailProvider(paperId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pastPaperDetailTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: ErrorHandler.handle(e).message,
          onRetry: () => ref.invalidate(pastPaperDetailProvider(paperId)),
        ),
        data: (detail) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(detail.label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text([
              if (detail.authority != null) detail.authority!,
              if (detail.yearAd != null) '${detail.yearAd}',
              l10n.syllabusPapersCount(detail.totalQuestions),
              if (detail.verified) l10n.libraryVerified,
            ].join(' • ')),
            if (detail.canShowScans && detail.pages.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(l10n.pastPaperScans, style: Theme.of(context).textTheme.titleSmall),
              for (final page in detail.pages)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.image_outlined),
                  title: Text(page.url),
                ),
            ],
            const SizedBox(height: 16),
            Text(l10n.pastPaperQuestions, style: Theme.of(context).textTheme.titleSmall),
            for (final question in detail.questions)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (question.number != null)
                        Text(
                          l10n.practiceQuestionNumber(question.number!),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      Text(question.text),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
