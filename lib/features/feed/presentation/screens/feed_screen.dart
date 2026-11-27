import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../domain/entities/feed.dart';
import '../controllers/feed_controller.dart';

/// Read-only activity feed backed by `GET /quiz/feed`.
///
/// The server authors the message, applies visibility/mute rules and supplies
/// the action URLs. This screen does not invent local activities or rewrite
/// an `/api/v1/*` action URL into a web link.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  String _scope = FeedScope.personalized;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filters = (scope: _scope, activityType: 'all');
    final async = ref.watch(feedProvider(filters));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.feedActivityFeed),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_rounded),
            tooltip: l10n.profileAchievements,
            onPressed: () => context.go('/quiz/hall-of-fame'),
          ),
          IconButton(
            icon: const Icon(Icons.insights_rounded),
            tooltip: l10n.aiUsageOverview,
            onPressed: () => context.go('/quiz/analytics'),
          ),
          IconButton(
            icon: const Icon(Icons.autorenew_rounded),
            tooltip: l10n.quizSrsReviewsDueTitle,
            onPressed: () => context.go('/quiz/review/due'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                _ScopeChip(
                  label: l10n.feedPersonalized,
                  selected: _scope == FeedScope.personalized,
                  onTap: () => setState(() => _scope = FeedScope.personalized),
                ),
                const SizedBox(width: 8),
                _ScopeChip(
                  label: l10n.leaderboardFriends,
                  selected: _scope == FeedScope.friends,
                  onTap: () => setState(() => _scope = FeedScope.friends),
                ),
                const SizedBox(width: 8),
                _ScopeChip(
                  label: l10n.leaderboardGlobal,
                  selected: _scope == FeedScope.global,
                  onTap: () => setState(() => _scope = FeedScope.global),
                ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              data: (cards) {
                if (cards.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      EmptyState(
                        title: l10n.feedNoActivityYet,
                        icon: Icons.dynamic_feed_rounded,
                      ),
                    ],
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(feedProvider(filters));
                    await ref.read(feedProvider(filters).future).catchError(
                          (_) => <FeedCard>[],
                        );
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cards.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _FeedCardTile(card: cards[i]),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ErrorView(
                    message: ErrorHandler.handle(e).message,
                    onRetry: () => ref.invalidate(feedProvider(filters)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.brand.withValues(alpha: 0.18),
      labelStyle: TextStyle(
        color: selected ? AppColors.brand : theme.colorScheme.onSurfaceVariant,
        fontSize: 12,
      ),
    );
  }
}

class _FeedCardTile extends StatelessWidget {
  const _FeedCardTile({required this.card});

  final FeedCard card;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final attempt = card.attempt;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  child: Text(
                    card.actor.name.isEmpty
                        ? 'C'
                        : card.actor.name.substring(0, 1).toUpperCase(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.actor.name,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (card.relativeTime != null)
                        Text(
                          card.relativeTime!,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(card.message, style: theme.textTheme.bodyMedium),
            if (attempt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.score_rounded,
                      size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(l10n.commonPercent(attempt.score)),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.favorite_outline_rounded,
                    size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('${card.reactions.total}'),
                const SizedBox(width: 16),
                Icon(Icons.comment_outlined,
                    size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('${card.comments.count}'),
                const Spacer(),
                if (attempt != null)
                  TextButton(
                    onPressed: () => context.go('/quiz/attempt/${attempt.id}/review'),
                    child: Text(l10n.quizResultAnswerReview),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
