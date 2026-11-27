import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../domain/entities/hall_of_fame.dart';
import '../controllers/hall_of_fame_controller.dart';

/// Hall of Fame snapshot from `GET /quiz/hall-of-fame`.
///
/// Filter chips are built from the server's own option lists, so no label or
/// period value is invented on-device. This is a bounded snapshot — there is
/// deliberately no cursor walk and no `page` control.
class HallOfFameScreen extends ConsumerStatefulWidget {
  const HallOfFameScreen({super.key});

  @override
  ConsumerState<HallOfFameScreen> createState() => _HallOfFameScreenState();
}

class _HallOfFameScreenState extends ConsumerState<HallOfFameScreen> {
  String _recordType = 'all';
  String _period = 'all_time';
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filters = (
      recordType: _recordType,
      period: _period,
      search: _search.text.trim().isEmpty ? null : _search.text.trim(),
    );
    final async = ref.watch(hallOfFameProvider(filters));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.hallOfFameTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.dynamic_feed_rounded),
            tooltip: l10n.economyLiveFeed,
            onPressed: () => context.go('/quiz/feed'),
          ),
          IconButton(
            icon: const Icon(Icons.insights_rounded),
            tooltip: l10n.aiUsageOverview,
            onPressed: () => context.go('/quiz/analytics'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                labelText: l10n.hallOfFameSearchRecords,
                prefixIcon: const Icon(Icons.search_rounded),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: async.when(
              data: (snapshot) => _SnapshotView(
                snapshot: snapshot,
                recordType: _recordType,
                period: _period,
                onRecordType: (value) => setState(() => _recordType = value),
                onPeriod: (value) => setState(() => _period = value),
                onSearch: () => setState(() {}),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ErrorView(
                    message: ErrorHandler.handle(e).message,
                    onRetry: () => ref.invalidate(hallOfFameProvider(filters)),
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

class _SnapshotView extends StatelessWidget {
  const _SnapshotView({
    required this.snapshot,
    required this.recordType,
    required this.period,
    required this.onRecordType,
    required this.onPeriod,
    required this.onSearch,
  });

  final HallOfFameSnapshot snapshot;
  final String recordType;
  final String period;
  final void Function(String value) onRecordType;
  final void Function(String value) onPeriod;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        onSearch();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _Stat(
                  icon: Icons.emoji_events_rounded,
                  value: '${snapshot.summary.recordCount}',
                  label: l10n.quizFunnelShown(snapshot.summary.recordCount),
                ),
              ),
              Expanded(
                child: _Stat(
                  icon: Icons.star_rounded,
                  value: '${snapshot.summary.featuredCount}',
                  label: l10n.quizFunnelShown(snapshot.summary.featuredCount),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(l10n.hallOfFameAllRecords, style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: [
              for (final option in snapshot.recordTypeOptions)
                ChoiceChip(
                  label: Text(option.label),
                  selected: option.value == recordType,
                  onSelected: (_) => onRecordType(option.value),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              for (final option in snapshot.periodOptions)
                ChoiceChip(
                  label: Text(option.label),
                  selected: option.value == period,
                  onSelected: (_) => onPeriod(option.value),
                ),
            ],
          ),
          if (snapshot.featuredRecords.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(l10n.hallOfFameTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            for (final record in snapshot.featuredRecords)
              _RecordTile(record: record),
          ],
          const SizedBox(height: 16),
          Text(l10n.commonLeaderboard, style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          if (snapshot.records.isEmpty)
            EmptyState(
              title: l10n.hallOfFameNoRecords,
              icon: Icons.emoji_events_outlined,
              compact: true,
            )
          else
            for (final record in snapshot.records) _RecordTile(record: record),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.xpGold, size: 20),
            const SizedBox(width: 8),
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

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});

  final HallOfFameRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (record.isFeatured)
                  const Icon(Icons.star_rounded, size: 16, color: AppColors.xpGold),
                Expanded(
                  child: Text(
                    record.title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(record.valueLabel,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: AppColors.brand)),
              ],
            ),
            if (record.name != null && record.name!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(record.name!, style: theme.textTheme.bodySmall),
            ],
            if (record.achievedAt != null) ...[
              const SizedBox(height: 2),
              Text(
                l10n.quizSrsDueDate(
                  record.achievedAt!.toLocal().toIso8601String().split('T').first,
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
