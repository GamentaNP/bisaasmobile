import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/error_view.dart';
import '../controllers/public_profile_controller.dart';

/// Comparison from `GET /quiz/profiles/compare?username=…`.
///
/// The target is a required query parameter: no other key is accepted by the
/// server. Rows (labels, values and suffixes) come verbatim from the server —
/// this screen performs no comparison math of its own.
class ProfileCompareScreen extends ConsumerWidget {
  const ProfileCompareScreen({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(profileCompareProvider(username));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileComparisonTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: ErrorHandler.handle(e).message,
          onRetry: () => ref.invalidate(profileCompareProvider(username)),
        ),
        data: (comparison) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(child: Text(comparison.viewer.name)),
                Expanded(child: Text(comparison.target.name)),
              ],
            ),
            const SizedBox(height: 12),
            for (final row in comparison.rows)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row.label, style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(child: Text('${row.viewer ?? ''}${row.suffix ?? ''}')),
                          Expanded(child: Text('${row.target ?? ''}${row.suffix ?? ''}')),
                        ],
                      ),
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
