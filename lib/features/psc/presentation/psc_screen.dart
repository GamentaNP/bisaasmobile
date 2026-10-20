import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../shared/widgets/error_view.dart';
import '../data/psc_remote_data_source.dart';

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
    final blueprints = ref.watch(pscBlueprintsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('PSC / Loksewa')),
      body: blueprints.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        // A failure is an error, not an empty catalogue. The data source
        // throws rather than collapsing a transport error into "no
        // blueprints", so it has to be rendered as an error.
        error: (e, _) => ErrorView(
          message: 'Could not load the PSC blueprints.\n$e',
          onRetry: () => ref.invalidate(pscBlueprintsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text(
                'No blueprints are published yet. Pull down to retry.',
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
                    'id: ${m['id'] ?? ''} • ${m['question_count'] ?? m['questions_count'] ?? ''} Qs',
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
                              ? 'Start exam failed (offline or 404)'
                              : 'Exam started: ${exam['id'] ?? ''}',
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
