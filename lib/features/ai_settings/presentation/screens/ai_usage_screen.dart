import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/error_view.dart';

import '../../domain/entities/ai_settings.dart';
import '../controllers/ai_settings_controller.dart';

/// The user's own AI usage.
///
/// `GET /me/ai-usage?period=7d|30d|90d` plus the user's own tutor
/// conversations and the week-over-week report-card trend.
///
/// **Units and feature names only.** The server never publishes an internal
/// USD cost and the client does not invent one — cost data stays admin-only
/// so the pricing model is not exposed to users.
class AiUsageScreen extends ConsumerStatefulWidget {
  const AiUsageScreen({super.key});

  @override
  ConsumerState<AiUsageScreen> createState() => _AiUsageScreenState();
}

class _AiUsageScreenState extends ConsumerState<AiUsageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(aiSettingsControllerProvider.notifier);
      notifier.fetchUsage();
      notifier.fetchTutorSessions();
      notifier.fetchReportCardHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiSettingsControllerProvider);
    final notifier = ref.read(aiSettingsControllerProvider.notifier);
    final theme = Theme.of(context);
    final usage = state.usage;

    return Scaffold(
      appBar: AppBar(title: const Text('Your AI usage')),
      body: RefreshIndicator(
        onRefresh: () async {
          await notifier.fetchUsage();
          await notifier.fetchTutorSessions();
          await notifier.fetchReportCardHistory();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Period selector ────────────────────────────────────────────
            Wrap(
              spacing: 8,
              children: [
                for (final p in AiUsagePeriod.values)
                  ChoiceChip(
                    label: Text(p.label, style: const TextStyle(fontSize: 12)),
                    selected: state.usagePeriod == p,
                    onSelected: (_) => notifier.fetchUsage(period: p),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            if (state.isUsageLoading && usage == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.usageError != null && usage == null)
              ErrorView(
                message: state.usageError!,
                onRetry: notifier.fetchUsage,
              )
            else if (usage != null) ...[
              Row(
                children: [
                  Text(
                    'Overview',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (usage.periodFrom != null && usage.periodTo != null)
                    Text(
                      '${usage.periodFrom} → ${usage.periodTo}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _Stat(
                    value: '${usage.requests}',
                    label: 'requests',
                  ),
                  const SizedBox(width: 18),
                  _Stat(
                    value: _compact(usage.totalTokens),
                    label: 'tokens',
                  ),
                  const SizedBox(width: 18),
                  _Stat(
                    value: '${usage.tutorConversations}',
                    // The server counts tutor conversations with **no** date
                    // filter, so this is a lifetime total. Labelling it
                    // "all time" keeps it from reading as a period figure
                    // next to the 7/30/90-day chip.
                    label: 'tutor chats (all time)',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (usage.features.isEmpty)
                const Text(
                  'No AI features were used in this period.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                )
              else ...[
                Text(
                  'By feature',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...usage.features.map((f) => _FeatureRow(feature: f)),
              ],
            ],

            // ── Tutor conversations ────────────────────────────────────────
            const SizedBox(height: 24),
            Text(
              'Tutor conversations',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (state.isSessionsLoading && state.tutorSessions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.sessionsError != null && state.tutorSessions.isEmpty)
              ErrorView(
                message: state.sessionsError!,
                onRetry: notifier.fetchTutorSessions,
              )
            else if (state.tutorSessions.isEmpty)
              const Text(
                'No tutor conversations yet.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              )
            else
              ...state.tutorSessions.map((s) => _SessionRow(session: s)),
            // The tutor conversations are cursor-paginated, so the first page
            // is not all of them.
            if (state.sessionsHasMore)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: OutlinedButton.icon(
                  onPressed: state.isSessionsLoading
                      ? null
                      : () => notifier.fetchTutorSessions(
                            cursor: state.sessionsCursor,
                            append: true,
                          ),
                  icon: const Icon(Icons.expand_more_rounded, size: 18),
                  label: const Text('Load more conversations'),
                ),
              ),

            // ── Report card trend ─────────────────────────────────────────
            const SizedBox(height: 24),
            Text(
              'Weekly report card',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (state.isReportCardLoading && state.reportCard.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.reportCardError != null && state.reportCard.isEmpty)
              ErrorView(
                message: state.reportCardError!,
                onRetry: notifier.fetchReportCardHistory,
              )
            else if (state.reportCard.isEmpty)
              const Text(
                'No weekly summaries stored yet.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              )
            else
              ...state.reportCard.map((w) => _WeekRow(week: w)),
            // The weekly history is cursor-paginated too.
            if (state.reportCardHasMore)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: OutlinedButton.icon(
                  onPressed: state.isReportCardLoading
                      ? null
                      : () => notifier.fetchReportCardHistory(
                            cursor: state.reportCardCursor,
                            append: true,
                          ),
                  icon: const Icon(Icons.expand_more_rounded, size: 18),
                  label: const Text('Load more weeks'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _compact(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return '$value';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: theme.textTheme.titleLarge),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature});
  final AiUsageFeature feature;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              feature.label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${feature.requests}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'requests',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session});
  final TutorSession session;

  @override
  Widget build(BuildContext context) {
    final created = session.createdAt;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.forum_outlined, size: 16, color: AppColors.brand),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              session.questionId == null
                  ? 'Conversation #${session.id}'
                  : 'Question ${session.questionId}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Text(
            '${session.turnCount} turns',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          if (created != null) ...[
            const SizedBox(width: 8),
            Text(
              DateFormat.yMMMd().format(created.toLocal()),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({required this.week});
  final ReportCardWeek week;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        title: Text(
          'Week of ${week.weekStartDate}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${week.accuracyPct.toStringAsFixed(0)}% accuracy • ${week.xpEarned} XP • ${week.coinsEarned} coins • ${week.bestStreak} day streak',
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        trailing: Text(
          '${(week.timeSpentSeconds / 3600).toStringAsFixed(1)}h',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
