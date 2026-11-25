import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/error_view.dart';
import '../data/providers/psc_providers.dart';
import '../../../l10n/app_localizations.dart';

// Both names stay reachable from their old location: the blueprint provider
// is watched below, and the data-source provider remains the test seam.
export '../data/providers/psc_providers.dart'
    show pscBlueprintsProvider, pscRemoteProvider, pscRepositoryProvider;

class PscScreen extends ConsumerWidget {
  const PscScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final blueprints = ref.watch(pscBlueprintsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pscTitle)),
      body: blueprints.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        // A failure is an error, not an empty catalogue. The data source
        // throws rather than collapsing a transport error into "no
        // blueprints", so it has to be rendered as an error.
        error: (e, _) => ErrorView(
          message: l10n.pscBlueprintsFailed(e),
          onRetry: () => ref.invalidate(pscBlueprintsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Text(
                l10n.pscNoBlueprints,
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final blueprint = list[i];
              return Card(
                child: ListTile(
                  title: Text(
                    blueprint.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  subtitle: Text(
                    l10n.pscBlueprintMeta(
                      blueprint.id,
                      blueprint.questionCount,
                    ),
                    style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  trailing: const Icon(Icons.arrow_forward_rounded),
                  onTap: () async {
                    final exam = await ref
                        .read(pscRepositoryProvider)
                        .startExam(blueprint.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          exam == null
                              ? l10n.pscStartFailed
                              : l10n.pscStarted(exam.id),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
