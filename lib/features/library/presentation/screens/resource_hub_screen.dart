import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/error_view.dart';
import '../controllers/resource_hub_controller.dart';

/// Resource hub from `GET /quiz/resources`.
///
/// The four sections and every card field are server-authored. Section labels
/// have their own localized copy; no English string is introduced here.
class ResourceHubScreen extends ConsumerWidget {
  const ResourceHubScreen({super.key});

  /// Maps the server's section keys onto their localized labels.
  String _sectionLabel(AppLocalizations l10n, String key) => switch (key) {
        'recommended' => l10n.libraryRecommendedForYou,
        'trending' => l10n.libraryTrending,
        'top_rated' => l10n.resourceSectionTopRated,
        'recently_added' => l10n.resourceSectionRecentlyAdded,
        _ => l10n.commonLibrary,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(resourceHubProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.resourceHubTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: ErrorHandler.handle(e).message,
          onRetry: () => ref.invalidate(resourceHubProvider),
        ),
        data: (hub) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final section in hub.sections.entries) ...[
              Text(
                _sectionLabel(l10n, section.key),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              if (section.value.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l10n.libraryNoFiles,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              else
                for (final card in section.value)
                  Card(
                    child: ListTile(
                      title: Text(card.title),
                      subtitle: Text([
                        if (card.categoryName != null) card.categoryName!,
                        if (card.coinPrice == 0)
                          l10n.libraryFree
                        else
                          l10n.libraryCoinsLabel(card.coinPrice),
                        '${card.downloadCount} ${l10n.libraryDownloads}',
                        l10n.libraryReviewsCount(card.reviewCount),
                      ].join(' • ')),
                      trailing: card.isUnlocked
                          ? const Icon(Icons.check_circle_outline, size: 18)
                          : null,
                      onTap: () => context.go('/library/${Uri.encodeComponent(card.slug)}'),
                    ),
                  ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
