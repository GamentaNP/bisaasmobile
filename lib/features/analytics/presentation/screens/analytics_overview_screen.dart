import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../domain/entities/analytics.dart';
import '../controllers/analytics_controller.dart';

/// Learner analytics from `GET /quiz/analytics/overview`.
///
/// Every figure shown here was computed by the server and scoped to the
/// credential tenant. No accuracy, ranking or grade is recalculated locally.
class AnalyticsOverviewScreen extends ConsumerWidget {
  const AnalyticsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final async = ref.watch(analyticsOverviewProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.analyticsYourProgress)),
      body: async.when(
        data: (overview) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(analyticsOverviewProvider);
            await ref.read(analyticsOverviewProvider.future).catchError(
                  (_) => const AnalyticsOverview(
                    userStats: AnalyticsUserStats(),
                    categoryPerformance: [],
                    heatmap: WeakTopicHeatmap(
                      summary: AnalyticsHeatmapSummary(),
                      topics: [],
                    ),
                  ),
                );
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: l10n.quizResultAccuracy,
                      value: l10n.commonPercent(overview.userStats.accuracyPercent),
                      icon: Icons.flag_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      label: l10n.tutorAvgScore,
                      value: '${overview.userStats.averageScore}',
                      icon: Icons.score_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _StatCard(
                label: l10n.analyticsTotalAttempts,
                value: '${overview.userStats.totalAttempts}',
                icon: Icons.replay_rounded,
              ),
              const SizedBox(height: 8),
              _StatCard(
                label: l10n.analyticsQuestionsAnswered,
                value: '${overview.userStats.totalQuestionsAnswered}',
                icon: Icons.question_answer_rounded,
              ),
              const SizedBox(height: 8),
              _StatCard(
                label: l10n.analyticsCorrectAnswers,
                value: '${overview.userStats.correctAnswers}',
                icon: Icons.check_circle_outline_rounded,
              ),
              const SizedBox(height: 16),
              Text(l10n.profileLearning, style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              if (overview.categoryPerformance.isEmpty)
                EmptyState(
                  title: l10n.leaderboardNoEntries,
                  icon: Icons.category_outlined,
                  compact: true,
                )
              else
                for (final category in overview.categoryPerformance)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(category.categoryName),
                      trailing: Text(
                        l10n.commonPercent(category.accuracyPercent),
                        style: TextStyle(color: AppColors.brand),
                      ),
                    ),
                  ),
              const SizedBox(height: 16),
              Text(l10n.practiceWeakTopics, style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              Text(
                l10n.practiceWeakTopicsServerNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              if (overview.heatmap.topics.isEmpty)
                EmptyState(
                  title: l10n.practiceNoWeakTopics,
                  subtitle: l10n.practiceWeakTopicsNeedsAttempts,
                  icon: Icons.bolt_outlined,
                  compact: true,
                )
              else
                for (final topic in overview.heatmap.topics)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(topic.topicName)),
                              Text(
                                l10n.commonPercent(topic.accuracyPercent),
                                style: TextStyle(color: AppColors.brand),
                              ),
                            ],
                          ),
                          if (topic.categoryName != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              topic.categoryName!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ErrorView(
              message: ErrorHandler.handle(e).message,
              onRetry: () => ref.invalidate(analyticsOverviewProvider),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.xpGold, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: theme.textTheme.titleMedium),
                  Text(label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
