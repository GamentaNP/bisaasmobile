import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../shared/widgets/error_view.dart';
import '../data/psc_remote_data_source.dart';
import '../../../l10n/app_localizations.dart';

final pscRemoteProvider = Provider<PscRemoteDataSource>(
  (ref) => PscRemoteDataSource(DioClient.instance.dio),
);

/// The blueprint list, as a provider so a failure is an error state rather
/// than an empty catalogue.
final pscBlueprintsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.read(pscRemoteProvider).getBlueprints(),
);

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
              final m = list[i];
              return Card(
                child: ListTile(
                  title: Text(
                    (m['title'] ?? m['name'] ?? 'Blueprint') as String,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  subtitle: Text(
                    l10n.pscBlueprintMeta(
          (m['id'] ?? '') as String,
          (m['question_count'] ?? m['questions_count'] ?? '') as String,
        ),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.arrow_forward_rounded),
                  onTap: () async {
                    final id = (m['id'] ?? '').toString();
                    final exam =
                        await ref.read(pscRemoteProvider).startExam(id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          exam == null
                              ? l10n.pscStartFailed
                              : l10n.pscStarted((exam['id'] ?? '') as String),
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
