import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/error_view.dart';
import '../controllers/contests_controller.dart';
import '../../domain/entities/contest.dart';

class ContestDetailScreen extends ConsumerStatefulWidget {
  const ContestDetailScreen({super.key, required this.contestId});
  final String contestId;

  @override
  ConsumerState<ContestDetailScreen> createState() => _ContestDetailScreenState();
}

class _ContestDetailScreenState extends ConsumerState<ContestDetailScreen> {
  int get _id => int.tryParse(widget.contestId) ?? 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final c = ref.read(contestDetailControllerProvider.notifier);
      c.fetchDetail(_id);
      c.fetchLeaderboard(_id);
      c.fetchRecap(_id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contestDetailControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(state.detail?.contest.title ?? 'Contest #$_id')),
      body: _buildBody(context, theme, state),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, ContestDetailState state) {
    if (state.isLoading && state.detail == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.detail == null) {
      return Center(child: ErrorView(message: state.error!, onRetry: () => ref.read(contestDetailControllerProvider.notifier).fetchDetail(_id)));
    }
    final detail = state.detail;
    if (detail == null) {
      return Center(child: ErrorView(message: 'Contest not found', onRetry: () => ref.read(contestDetailControllerProvider.notifier).fetchDetail(_id)));
    }
    final contest = detail.contest;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(contestDetailControllerProvider.notifier).fetchDetail(_id),
          ref.read(contestDetailControllerProvider.notifier).fetchLeaderboard(_id),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Header(detail: detail, theme: theme),
          const SizedBox(height: 12),
          _ActionBar(state: state, contest: contest, onJoin: _join, onEnter: _enter, onLeave: _leave, onRefresh: () => ref.read(contestDetailControllerProvider.notifier).fetchLeaderboard(_id)),
          if (state.joinError != null) ...[
            const SizedBox(height: 8),
            Text(state.joinError!, style: const TextStyle(fontSize: 12, color: AppColors.wrongRed)),
          ],
          if (state.enterError != null) ...[
            const SizedBox(height: 8),
            Text(state.enterError!, style: const TextStyle(fontSize: 12, color: AppColors.wrongRed)),
          ],
          if (state.lastAttempt != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.correctGreen.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.correctGreen.withValues(alpha: 0.2))),
              child: Text('Attempt #${state.lastAttempt!.attemptId} started. Expires: ${state.lastAttempt!.expiresAt?.toLocal().toString().split('.').first ?? '—'}', style: const TextStyle(fontSize: 12, color: AppColors.correctGreen)),
            ),
          ],
          const SizedBox(height: 20),
          Text('Leaderboard', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (state.isLeaderboardLoading) const LinearProgressIndicator(),
          if (state.leaderboardError != null) ErrorView(message: state.leaderboardError!, onRetry: () => ref.read(contestDetailControllerProvider.notifier).fetchLeaderboard(_id)),
          if (!state.isLeaderboardLoading && state.leaderboard.isEmpty && state.leaderboardError == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
              child: const Text('No leaderboard entries yet — be the first!', style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
            ),
          ...state.leaderboard.map((e) => _LeaderTile(entry: e)),
          if (detail.leaderboardMeta != null) ...[
            const SizedBox(height: 6),
            Text('Generated: ${detail.leaderboardMeta!.generatedAt?.toLocal().toString().split('.').first ?? '—'} • Refresh budget: ${detail.leaderboardMeta!.refreshBudgetRemaining} • ${detail.leaderboardMeta!.cached ? 'cached' : 'live'}', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ],
          const SizedBox(height: 20),
          Text('Recap', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (state.isRecapLoading) const LinearProgressIndicator(),
          if (state.recapError != null) ErrorView(message: state.recapError!, onRetry: () => ref.read(contestDetailControllerProvider.notifier).fetchRecap(_id)),
          if (!state.isRecapLoading && state.recap != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.recap!.title != null) Text(state.recap!.title!, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  if (state.recap!.summary != null) ...[
                    const SizedBox(height: 6),
                    Text(state.recap!.summary!, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                  ],
                  if (state.recap!.winners.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Winners', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    ...state.recap!.winners.take(5).map((w) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text('#${w.rank ?? '-'} ${w.displayName ?? 'User #${w.userId}'} — ${w.score.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)))),
                  ],
                  if (state.recap!.stats.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Raw stats: ${state.recap!.stats.length} keys', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                  ],
                ],
              ),
            )
          else if (!state.isRecapLoading && state.recap == null && state.recapError == null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(12)),
              child: const Text('Recap available after contest ends.', style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _join() async {
    final ok = await ref.read(contestDetailControllerProvider.notifier).join(_id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Joined contest!' : 'Join failed'), backgroundColor: ok ? AppColors.correctGreen : AppColors.wrongRed));
  }

  Future<void> _enter() async {
    final attempt = await ref.read(contestDetailControllerProvider.notifier).enter(_id);
    if (!mounted) return;
    if (attempt != null) {
      // Navigate to quiz attempt if we have an attempt id — reuse quiz route
      unawaited(context.push('/quiz/${attempt.attemptId}'));
    }
  }

  Future<void> _leave() async {
    final ok = await ref.read(contestDetailControllerProvider.notifier).leave(_id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Left contest' : 'Leave failed'), backgroundColor: ok ? AppColors.brand : AppColors.wrongRed));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.detail, required this.theme});
  final ContestDetail detail;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final c = detail.contest;
    final color = switch (c.status.toLowerCase()) { 'active' => AppColors.correctGreen, 'upcoming' => AppColors.brand, 'ended' => Colors.grey, _ => AppColors.streakOrange };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Text(c.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color))),
              const Spacer(),
              if (c.isRegistered) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.correctGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_circle_rounded, size: 12, color: AppColors.correctGreen), SizedBox(width: 4), Text('REGISTERED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.correctGreen))])),
            ],
          ),
          const SizedBox(height: 10),
          Text(c.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          if (c.description != null && c.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(c.description!, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.65))),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _StatChip(icon: Icons.monetization_on_rounded, label: c.isFree ? 'FREE' : '${c.entryFeeCoins} coins', color: c.isFree ? AppColors.correctGreen : AppColors.coinYellow),
              _StatChip(icon: Icons.card_giftcard_rounded, label: '${c.prizePoolCoins} prize', color: AppColors.xpGold),
              if (c.maxParticipants != null) _StatChip(icon: Icons.group_rounded, label: 'Max ${c.maxParticipants}', color: AppColors.brand),
              if (c.startsAt != null) _StatChip(icon: Icons.schedule_rounded, label: 'Starts ${c.startsAt!.toLocal().toString().split(' ').first}', color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              if (c.endsAt != null) _StatChip(icon: Icons.flag_rounded, label: 'Ends ${c.endsAt!.toLocal().toString().split(' ').first}', color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 12, color: color), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color))]),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.state, required this.contest, required this.onJoin, required this.onEnter, required this.onLeave, required this.onRefresh});
  final ContestDetailState state;
  final Contest contest;
  final Future<void> Function() onJoin;
  final Future<void> Function() onEnter;
  final Future<void> Function() onLeave;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final isRegistered = state.detail?.isRegistered ?? contest.isRegistered;
    return Row(
      children: [
        if (!isRegistered)
          Expanded(
            child: FilledButton.icon(
              onPressed: state.isJoining ? null : onJoin,
              icon: state.isJoining ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.how_to_reg_rounded, size: 18),
              label: Text(contest.isFree ? 'Join (Free)' : 'Join (${contest.entryFeeCoins} coins)'),
            ),
          )
        else
          Expanded(
            child: FilledButton.icon(
              onPressed: state.isEntering ? null : onEnter,
              icon: state.isEntering ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Enter Contest'),
            ),
          ),
        const SizedBox(width: 10),
        if (isRegistered && contest.isUpcoming)
          OutlinedButton(
            onPressed: onLeave,
            child: const Text('Leave'),
          )
        else
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.leaderboard_rounded, size: 18),
            label: const Text('Refresh'),
          ),
      ],
    );
  }

}

class _LeaderTile extends StatelessWidget {
  const _LeaderTile({required this.entry});
  final ContestEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rank = entry.rank ?? 0;
    final isTop = rank > 0 && rank <= 3;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2))),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: isTop ? AppColors.xpGold.withValues(alpha: 0.12) : theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(rank > 0 ? '#$rank' : '—', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isTop ? AppColors.xpGold : null))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(entry.displayName ?? 'User #${entry.userId}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          Text(entry.score.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          if (entry.completed) const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.correctGreen),
        ],
      ),
    );
  }
}
