// ignore_for_file: unnecessary_lambdas

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../domain/entities/leaderboard.dart';
import '../controllers/leaderboard_controller.dart';

/// Leaderboard — global/friends/league + my-rank + donors.
/// Uses `GET /quiz/leaderboards/{id}`, `GET /quiz/leaderboards/my-rank`,
/// `POST /quiz/leaderboard` (submit), `GET /donations/leaderboard`.
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) {
        final scopes = ['global', 'friends', 'league', 'donors'];
        final scope = scopes[_tab.index];
        ref.read(leaderboardControllerProvider.notifier).setScope(scope);
        if (scope == 'donors') {
          ref.read(leaderboardControllerProvider.notifier).fetchDonationLeaderboard();
        }
      }
    });
    Future.microtask(() {
      final c = ref.read(leaderboardControllerProvider.notifier);
      c.fetchMyRanks();
      c.fetchDonationLeaderboard();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final c = ref.read(leaderboardControllerProvider.notifier);
    final s = ref.read(leaderboardControllerProvider);
    await Future.wait([
      c.fetchMyRanks(),
      if (s.selectedLeaderboardId != null) c.fetchLeaderboard(s.selectedLeaderboardId!),
      c.fetchDonationLeaderboard(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaderboardControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        bottom: TabBar(
          controller: _tab,
          isScrollable: false,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Friends'),
            Tab(text: 'League'),
            Tab(text: 'Donors'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => _onRefresh(), tooltip: 'Refresh'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: TabBarView(
          controller: _tab,
          children: [
            _GlobalTab(state: state, theme: theme),
            _FriendsLeagueTab(state: state, theme: theme, scope: 'friends'),
            _FriendsLeagueTab(state: state, theme: theme, scope: 'league'),
            _DonorsTab(state: state, theme: theme),
          ],
        ),
      ),
    );
  }
}

class _MyRankCard extends StatelessWidget {
  const _MyRankCard({required this.myRanks, this.selectedId});
  final List<MyRank> myRanks;
  final int? selectedId;

  @override
  Widget build(BuildContext context) {
    if (myRanks.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3))),
        child: const Row(
          children: [
            Icon(Icons.emoji_events_rounded, color: AppColors.xpGold),
            SizedBox(width: 10),
            Expanded(child: Text('No rank yet — complete a quiz to enter the leaderboard.', style: TextStyle(fontSize: 12))),
          ],
        ),
      );
    }
    // Show best rank card
    final best = myRanks.where((r) => r.rank != null).toList()..sort((a, b) => (a.rank ?? 9999).compareTo(b.rank ?? 9999));
    final display = best.isNotEmpty ? best.first : myRanks.first;
    final rank = display.rank;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brand, AppColors.brandLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          bottom: BorderSide(
            color: AppColors.brandShadow,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.person_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MY RANK', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                Text(rank != null ? '#$rank in ${display.leaderboard.name}' : 'Unranked in ${display.leaderboard.name}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                if (display.score != null) Text('Score: ${display.score!.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (selectedId != null && selectedId == display.leaderboard.id)
            const Icon(Icons.check_circle_rounded, color: Colors.white),
        ],
      ),
    );
  }
}

class _GlobalTab extends ConsumerWidget {
  const _GlobalTab({required this.state, required this.theme});
  final LeaderboardState state;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Filter global leaderboards for picker
    final globalRanks = state.myRanks.where((r) => r.leaderboard.scope == 'global').toList();
    final leaderboardOptions = globalRanks.isNotEmpty ? globalRanks.map((r) => r.leaderboard).toList() : state.myRanks.map((r) => r.leaderboard).toList();

    return ListView(
      children: [
        if (state.isMyRankLoading) const LinearProgressIndicator(),
        if (state.myRanksError != null) Padding(padding: const EdgeInsets.all(16), child: ErrorView(message: state.myRanksError!, onRetry: () => ref.read(leaderboardControllerProvider.notifier).fetchMyRanks())),
        _MyRankCard(myRanks: state.myRanks, selectedId: state.selectedLeaderboardId),
        if (leaderboardOptions.isNotEmpty)
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: leaderboardOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final lb = leaderboardOptions[i];
                final sel = lb.id == state.selectedLeaderboardId;
                return ChoiceChip(
                  label: Text(lb.name),
                  selected: sel,
                  onSelected: (_) => ref.read(leaderboardControllerProvider.notifier).fetchLeaderboard(lb.id),
                );
              },
            ),
          ),
        if (state.isLoading) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
        if (state.error != null) Padding(padding: const EdgeInsets.all(16), child: ErrorView(message: state.error!, onRetry: () => state.selectedLeaderboardId != null ? ref.read(leaderboardControllerProvider.notifier).fetchLeaderboard(state.selectedLeaderboardId!) : ref.read(leaderboardControllerProvider.notifier).fetchMyRanks())),
        if (!state.isLoading && state.entries.isEmpty && state.error == null)
          const Padding(
            padding: EdgeInsets.all(16),
            child: EmptyState(title: 'No entries yet', subtitle: 'Be the first to claim the top spot!', icon: Icons.leaderboard_rounded),
          ),
        ...state.entries.map((e) => _EntryTile(entry: e, myRank: state.myRank)),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _FriendsLeagueTab extends ConsumerWidget {
  const _FriendsLeagueTab({required this.state, required this.theme, required this.scope});
  final LeaderboardState state;
  final ThemeData theme;
  final String scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtered = state.myRanks.where((r) => r.leaderboard.scope == scope).toList();
    if (filtered.isEmpty && !state.isMyRankLoading) {
      return ListView(
        children: [
          _MyRankCard(myRanks: state.myRanks, selectedId: state.selectedLeaderboardId),
          Padding(
            padding: const EdgeInsets.all(24),
            child: EmptyState(
              title: scope == 'friends' ? 'Friends leaderboard' : 'League leaderboard',
              subtitle: scope == 'friends' ? 'Add friends to compete — server segments friends automatically.' : 'League is seasonal — join via events/contests to qualify.',
              icon: scope == 'friends' ? Icons.group_rounded : Icons.shield_rounded,
            ),
          ),
        ],
      );
    }
    final lbOptions = filtered.map((r) => r.leaderboard).toList();
    final entriesToShow = state.leaderboard?.scope == scope ? state.entries : const <LeaderboardEntry>[];
    return ListView(
      children: [
        if (state.isMyRankLoading) const LinearProgressIndicator(),
        _MyRankCard(myRanks: filtered.isNotEmpty ? filtered : state.myRanks, selectedId: state.selectedLeaderboardId),
        if (lbOptions.isNotEmpty)
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: lbOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final lb = lbOptions[i];
                final sel = lb.id == state.selectedLeaderboardId;
                return ChoiceChip(label: Text(lb.name), selected: sel, onSelected: (_) => ref.read(leaderboardControllerProvider.notifier).fetchLeaderboard(lb.id));
              },
            ),
          ),
        if (state.isLoading) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
        if (state.error != null) Padding(padding: const EdgeInsets.all(16), child: ErrorView(message: state.error!, onRetry: () => state.selectedLeaderboardId != null ? ref.read(leaderboardControllerProvider.notifier).fetchLeaderboard(state.selectedLeaderboardId!) : null)),
        if (!state.isLoading && entriesToShow.isEmpty && state.error == null && filtered.isNotEmpty)
          const Padding(padding: EdgeInsets.all(16), child: EmptyState(title: 'No entries', subtitle: 'Compete to appear here.', icon: Icons.leaderboard_outlined)),
        ...entriesToShow.map((e) => _EntryTile(entry: e, myRank: state.myRank)),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _DonorsTab extends ConsumerWidget {
  const _DonorsTab({required this.state, required this.theme});
  final LeaderboardState state;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isDonorLoading && state.donorEntries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.donorError != null && state.donorEntries.isEmpty) {
      return ListView(children: [const SizedBox(height: 80), ErrorView(message: state.donorError!, onRetry: () => ref.read(leaderboardControllerProvider.notifier).fetchDonationLeaderboard())]);
    }
    if (state.donorEntries.isEmpty) {
      return const Center(child: EmptyState(title: 'No donors yet', subtitle: 'Support the platform to appear here.', icon: Icons.favorite_rounded));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: state.donorEntries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final d = state.donorEntries[i];
        final rank = i + 1;
        final isTop3 = rank <= 3;
        var borderColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.25);
        if (isTop3) {
          borderColor = rank == 1 ? AppColors.xpGold : rank == 2 ? const Color(0xFF94A3B8) : const Color(0xFFB45309);
        }
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor, width: isTop3 ? 2 : 1)),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isTop3 ? (rank == 1 ? AppColors.xpGold.withValues(alpha: 0.15) : rank == 2 ? Colors.grey.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15)) : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text('$rank', style: TextStyle(fontWeight: FontWeight.bold, color: isTop3 ? (rank == 1 ? AppColors.xpGold : rank == 2 ? Colors.grey[700] : const Color(0xFFB45309)) : theme.colorScheme.onSurface))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.donorName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                          child: Text(d.badgeLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple)),
                        ),
                        const SizedBox(width: 6),
                        Text(d.totalDonatedFormatted, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                        if (d.streakMonths > 0) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.local_fire_department_rounded, size: 14, color: AppColors.streakOrange),
                          Text('${d.streakMonths}m', style: const TextStyle(fontSize: 11, color: AppColors.streakOrange)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (rank <= 3) Icon(rank == 1 ? Icons.emoji_events_rounded : rank == 2 ? Icons.workspace_premium_rounded : Icons.military_tech_rounded, color: borderColor),
            ],
          ),
        );
      },
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, this.myRank});
  final LeaderboardEntry entry;
  final int? myRank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMe = entry.isMe || (myRank != null && entry.rank == myRank);
    final isTop = entry.rank <= 3;

    // Duolongo medal row: 🥇🥈🥉 for the podium, chunky borders everywhere.
    final medal = entry.rank == 1
        ? '🥇'
        : entry.rank == 2
            ? '🥈'
            : entry.rank == 3
                ? '🥉'
                : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.selectedGreenBg
            : isTop && !isDark
                ? AppColors.surfaceSecondary
                : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          bottom: BorderSide(
            color: isMe
                ? AppColors.brand
                : isDark
                    ? AppColors.dividerDark
                    : AppColors.dividerLight,
            width: isMe ? 3 : 2,
          ),
          top: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 1.5,
          ),
          left: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 1.5,
          ),
          right: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              medal ?? '#${entry.rank}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: medal != null ? 20 : 14,
                color: isTop ? AppColors.goldShadow : null,
              ),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isMe ? AppColors.selectedGreenBg : AppColors.brand.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.brand, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.displayName ?? 'User #${entry.userId}'}${isMe ? '  (You)' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isMe ? AppColors.brandShadow : null,
                  ),
                ),
                Text(
                  'Score ${entry.score.toStringAsFixed(0)} • ${entry.attemptsCount} attempts',
                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const Icon(Icons.bolt_rounded, size: 16, color: AppColors.xpGold),
          const SizedBox(width: 4),
          Text(
            entry.score.toStringAsFixed(0),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isMe ? AppColors.brandShadow : AppColors.goldShadow,
            ),
          ),
        ],
      ),
    );
  }
}
