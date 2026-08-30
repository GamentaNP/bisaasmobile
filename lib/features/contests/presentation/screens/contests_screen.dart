import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../controllers/contests_controller.dart';
import '../../domain/entities/contest.dart';

class ContestsScreen extends ConsumerStatefulWidget {
  const ContestsScreen({super.key});

  @override
  ConsumerState<ContestsScreen> createState() => _ContestsScreenState();
}

class _ContestsScreenState extends ConsumerState<ContestsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(contestsControllerProvider.notifier).fetchContests(page: 1));
  }

  Future<void> _onRefresh() async {
    await ref.read(contestsControllerProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contestsControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contests'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: state.isLoading ? null : _onRefresh),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _buildBody(context, theme, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, ContestsState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          ErrorView(message: state.error!, onRetry: () => ref.read(contestsControllerProvider.notifier).fetchContests(page: 1)),
        ],
      );
    }
    if (state.items.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          EmptyState(title: 'No contests yet', subtitle: 'Active and upcoming contests will appear here.', icon: Icons.emoji_events_outlined),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: state.items.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i >= state.items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: state.isLoading
                  ? const CircularProgressIndicator()
                  : OutlinedButton.icon(
                      onPressed: () => ref.read(contestsControllerProvider.notifier).fetchContests(page: state.currentPage + 1, append: true),
                      icon: const Icon(Icons.expand_more_rounded),
                      label: const Text('Load more'),
                    ),
            ),
          );
        }
        final c = state.items[i];
        return _ContestCard(contest: c, onTap: () => context.push('/contests/${c.id}'));
      },
    );
  }
}

class _ContestCard extends StatelessWidget {
  const _ContestCard({required this.contest, required this.onTap});
  final Contest contest;
  final VoidCallback onTap;

  Color _statusColor(String status) {
    return switch (status.toLowerCase()) {
      'active' => AppColors.correctGreen,
      'upcoming' => AppColors.brand,
      'ended' => Colors.grey,
      _ => AppColors.streakOrange,
    };
  }

  IconData _statusIcon(String status) {
    return switch (status.toLowerCase()) {
      'active' => Icons.play_circle_rounded,
      'upcoming' => Icons.schedule_rounded,
      'ended' => Icons.flag_rounded,
      _ => Icons.emoji_events_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(contest.status);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(_statusIcon(contest.status), size: 18, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(contest.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(contest.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                ),
              ],
            ),
            if (contest.description != null && contest.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(contest.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.65))),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                if (contest.startsAt != null) ...[
                  Icon(Icons.calendar_today_rounded, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text(_fmt(contest.startsAt!), style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                  const SizedBox(width: 10),
                ],
                if (!contest.isFree) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.coinYellow.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.monetization_on_rounded, size: 12, color: AppColors.coinYellow), const SizedBox(width: 2), Text('${contest.entryFeeCoins}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.coinYellow))]),
                  ),
                  const SizedBox(width: 6),
                ] else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.correctGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                    child: const Text('FREE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.correctGreen)),
                  ),
                const Spacer(),
                if (contest.prizePoolCoins > 0) ...[
                  const Icon(Icons.card_giftcard_rounded, size: 12, color: AppColors.xpGold),
                  const SizedBox(width: 2),
                  Text('${contest.prizePoolCoins} prize', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.xpGold)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) {
    final local = d.toLocal();
    return '${local.day}/${local.month} ${local.hour}:${local.minute.toString().padLeft(2, '0')}';
  }
}
