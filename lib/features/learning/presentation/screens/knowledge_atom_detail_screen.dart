import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/error_view.dart';
import '../controllers/knowledge_atom_controller.dart';

/// Bounded key-term popover from `GET /quiz/knowledge-atoms/{atom}`.
///
/// No lesson body and no answer key are fetched or reconstructed here. A drift
/// or a transport failure is an ErrorView with retry, never an empty detail.
class KnowledgeAtomDetailScreen extends ConsumerWidget {
  const KnowledgeAtomDetailScreen({super.key, required this.atomId});

  final String atomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(knowledgeAtomProvider(atomId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.knowledgeAtomNumbered(atomId))),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: ErrorHandler.handle(e).message,
          onRetry: () => ref.invalidate(knowledgeAtomProvider(atomId)),
        ),
        data: (atom) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              atom.title ?? l10n.knowledgeAtomNumbered(atom.id),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (atom.type != null)
              ListTile(
                dense: true,
                leading: const Icon(Icons.category_outlined),
                title: Text('${atom.type}'),
              ),
            if (atom.topicId != null)
              ListTile(
                dense: true,
                leading: const Icon(Icons.topic_outlined),
                title: Text('${atom.topicId}'),
              ),
            const SizedBox(height: 8),
            Text(l10n.libraryAbout, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(atom.summary ?? ''),
          ],
        ),
      ),
    );
  }
}
