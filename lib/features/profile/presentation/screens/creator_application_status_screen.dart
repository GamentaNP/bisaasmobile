import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/error_view.dart';
import '../controllers/creator_application_controller.dart';

/// Eligibility + existing profile + top subjects from the server snapshot.
///
/// The submit action is deliberately absent: `POST /quiz/creator/applications`
/// is one-way and the eligibility flags here are advisory, not a local gate.
class CreatorApplicationStatusScreen extends ConsumerWidget {
  const CreatorApplicationStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(creatorApplicationStatusProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: ErrorHandler.handle(e).message,
          onRetry: () => ref.invalidate(creatorApplicationStatusProvider),
        ),
        data: (snapshot) {
          final eligibility = snapshot.eligibility;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: Text(l10n.socialStatus(eligibility.isEligible
                      ? l10n.commonSuccess
                      : l10n.commonFailed)),
                  subtitle: Text(l10n.socialStatus(
                    snapshot.existing?.status ?? l10n.battleResultPending,
                  )),
                ),
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.arrow_upward_rounded),
                title: Text(l10n.tutorCurrentLevel),
                trailing: Text(l10n.xpLevelLabel(eligibility.level)),
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.stars_outlined),
                title: Text(l10n.leaderboardScore(
                  '${eligibility.reputationScore}',
                )),
                trailing: Text(l10n.commonPoints(eligibility.reputationRequired)),
              ),
              if (snapshot.existing?.notes != null)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.notes_outlined),
                  title: Text(snapshot.existing!.notes!),
                ),
              const SizedBox(height: 8),
              Text(
                l10n.practiceWeakTopics,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (snapshot.topSubjects.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.practiceNoWeakTopics,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              else
                for (final subject in snapshot.topSubjects)
                  ListTile(
                    dense: true,
                    title: Text(subject.categoryName),
                    trailing: Text(l10n.commonPercent(subject.masteryScore.round())),
                  ),
            ],
          );
        },
      ),
    );
  }
}
