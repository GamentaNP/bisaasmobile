import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/error_view.dart';
import '../controllers/profile_onboarding_status_controller.dart';

/// Status + picker snapshot from `GET /quiz/profile-onboarding/status`.
///
/// The flags come from the server; this screen never decides for the reader
/// that onboarding is finished. Tapping continue only navigates to the existing
/// wizard — the write still lives at `POST /quiz/profile-onboarding`.
class ProfileOnboardingStatusScreen extends ConsumerWidget {
  const ProfileOnboardingStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(profileOnboardingStatusProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.coachingOnboarding)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: ErrorHandler.handle(e).message,
          onRetry: () => ref.invalidate(profileOnboardingStatusProvider),
        ),
        data: (snapshot) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.assignment_turned_in_outlined),
                title: Text(l10n.socialStatus(
                  snapshot.shouldShowWizard
                      ? l10n.tutorStartOnboarding
                      : l10n.tutorOnboardingComplete,
                )),
                trailing: snapshot.shouldShowWizard
                    ? TextButton(
                        onPressed: () => context.go('/onboarding'),
                        child: Text(l10n.onboardingContinue),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.onboardingCurrentLevelTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            for (final level in snapshot.educationLevels)
              ListTile(
                dense: true,
                title: Text(level.name),
                subtitle: Text(level.description ?? ''),
              ),
            const SizedBox(height: 8),
            Text(
              l10n.onboardingTargetExamTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            for (final domain in snapshot.domains)
              ListTile(
                dense: true,
                title: Text(domain.name),
                subtitle: Text(domain.description ?? ''),
              ),
            const SizedBox(height: 8),
            Text(
              l10n.economyCatalog,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            for (final course in snapshot.courses)
              ListTile(
                dense: true,
                title: Text(course.name),
                subtitle: Text('${course.id}'),
              ),
          ],
        ),
      ),
    );
  }
}
