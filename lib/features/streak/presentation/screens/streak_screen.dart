// ignore_for_file: unnecessary_non_null_assertion, avoid_escaping_inner_quotes

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../data/models/streak_dto.dart';
import '../../domain/entities/streak.dart';
import '../controllers/streak_controller.dart';
import '../widgets/streak_calendar.dart';
import '../../../../l10n/app_localizations.dart';

/// Streak screen — `GET /quiz/streak` (+ `POST /donations/freeze-streak`).
/// Server-authoritative: Flutter never computes streak locally, only visualizes.
/// The calendar is decorative; repair / insurance / wager are all live server
/// features (`/quiz/streak/repair`, `/quiz/streak/insurance`, `/quiz/streak/wager`)
/// whose eligibility the server decides — the buttons stay disabled until it says yes.
class StreakScreen extends ConsumerStatefulWidget {
  const StreakScreen({super.key});

  @override
  ConsumerState<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends ConsumerState<StreakScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(streakControllerProvider.notifier).refreshAll());
  }

  Future<void> _onRefresh() async {
    await ref.read(streakControllerProvider.notifier).refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(streakControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileStreak),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: state.isLoading ? null : () => ref.read(streakControllerProvider.notifier).fetchStreak(),
            tooltip: l10n.streakRefresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _buildBody(context, theme, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, StreakState state) {
    final l10n = AppLocalizations.of(context)!;
    if (state.isLoading && state.streak == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.streak == null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          ErrorView(message: state.error!, onRetry: () => ref.read(streakControllerProvider.notifier).fetchStreak()),
        ],
      );
    }
    final streak = state.streak;
    if (streak == null) {
      return ListView(
        children: [
          SizedBox(height: 80),
          EmptyState(title: l10n.streakNoneTitle, subtitle: l10n.streakNoneBody, icon: Icons.local_fire_department_rounded),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeaderCard(streak: streak),
        const SizedBox(height: 12),
        _MultiplierCard(streak: streak),
        const SizedBox(height: 16),
        Text(l10n.streakCalendar, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: StreakCalendar(streak: streak),
        ),
        const SizedBox(height: 8),
        Text(
          streak.isActiveToday
              ? l10n.streakOnFire
              : streak.isAtRisk
                  ? 'At risk — complete a quiz before midnight to keep ${streak.currentStreak} days alive.'
                  : 'Complete today\'s quiz to grow your streak.',
          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 20),
        _FreezeSection(state: state, streak: streak, onFreeze: _freeze),
        const SizedBox(height: 20),
        Text(l10n.streakProtect, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _ProtectStreakSection(state: state),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _freeze() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await ref.read(streakControllerProvider.notifier).freezeStreak();
    if (!mounted) return;
    final state = ref.read(streakControllerProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? l10n.streakFrozen : (state.freezeError ?? 'Freeze failed — check coins or donor badge.')),
        backgroundColor: ok ? AppColors.correctGreen : AppColors.wrongRed,
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.streak});
  final Streak streak;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEA580C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.streakCurrent, style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${streak.currentStreak}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, height: 1)),
                    const SizedBox(width: 6),
                    Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text(l10n.streakDaysUnit, style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(l10n.streakBest(streak.longestStreak), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: Text('${streak.streakMultiplier.toStringAsFixed(1)}×', style: const TextStyle(color: Color(0xFFEA580C), fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 6),
              Text(l10n.streakMultiplier, style: TextStyle(color: Colors.white70, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MultiplierCard extends StatelessWidget {
  const _MultiplierCard({required this.streak});
  final Streak streak;

  String _tierLabel(double m) {
    if (m >= 3.0) return 'Legend 100+';
    if (m >= 2.0) return 'Champion 30+';
    if (m >= 1.5) return 'Warrior 7+';
    return 'Starter';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final label = _tierLabel(streak.streakMultiplier);
    final nextThreshold = streak.streakMultiplier < 1.5
        ? 7
        : streak.streakMultiplier < 2.0
            ? 30
            : streak.streakMultiplier < 3.0
                ? 100
                : null;
    final progress = nextThreshold == null ? 1.0 : (streak.currentStreak / nextThreshold).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, size: 18, color: AppColors.streakOrange),
              const SizedBox(width: 6),
              Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(l10n.streakXpMultiplier(streak.streakMultiplier.toStringAsFixed(1)), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.streakOrange)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress, backgroundColor: theme.colorScheme.surfaceContainerHighest, color: AppColors.streakOrange, minHeight: 6, borderRadius: BorderRadius.circular(6)),
          const SizedBox(height: 6),
          Text(
            nextThreshold == null ? l10n.streakMaxMultiplier : l10n.streakDaysToNextTier(streak.currentStreak, nextThreshold),
            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.streakTiers,
            style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
          ),
        ],
      ),
    );
  }
}

class _FreezeSection extends StatelessWidget {
  const _FreezeSection({required this.state, required this.streak, required this.onFreeze});
  final StreakState state;
  final Streak streak;
  final Future<void> Function() onFreeze;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final frozenUntil = streak.frozenUntil;
    final hasFreeze = frozenUntil != null && frozenUntil.isAfter(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (hasFreeze ? AppColors.correctGreen : theme.colorScheme.outlineVariant).withValues(alpha: hasFreeze ? 0.4 : 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.correctGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.ac_unit_rounded, size: 16, color: AppColors.correctGreen),
              ),
              const SizedBox(width: 8),
              Text(l10n.streakFreezeSection, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (streak.freezeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.correctGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(l10n.streakFreezeLeft(streak.freezeCount), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.correctGreen)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasFreeze ? l10n.streakFrozenUntil(frozenUntil!.toLocal().toString().split('.').first) : l10n.streakFreezeHint,
            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.65)),
          ),
          if (state.freezeError != null) ...[
            const SizedBox(height: 8),
            Text(state.freezeError!, style: const TextStyle(fontSize: 12, color: AppColors.wrongRed)),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: state.isFreezing ? null : onFreeze,
              icon: state.isFreezing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.shield_rounded, size: 18),
              label: Text(hasFreeze ? l10n.streakExtendFreeze : l10n.streakFreezeAction),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProtectStreakSection extends StatelessWidget {
  const _ProtectStreakSection({required this.state});

  final StreakState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.selfServiceError != null) ...[
          _InlineError(message: state.selfServiceError!),
          const SizedBox(height: 10),
        ],
        _RepairCard(state: state),
        const SizedBox(height: 10),
        _InsuranceCard(state: state),
        const SizedBox(height: 10),
        _WagerCard(state: state),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.wrongRed.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.wrongRed.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.wrongRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: AppColors.wrongRed, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _RepairCard extends ConsumerWidget {
  const _RepairCard({required this.state});
  final StreakState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final elig = state.repairEligibility;
    // Until eligibility loads, the action stays disabled — never optimistically
    // enabled, and never enabled on a guess.
    final eligible = elig?.eligible ?? false;
    final busy = state.isSelfServiceBusy;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (eligible ? AppColors.correctGreen : theme.colorScheme.outlineVariant).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.correctGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.build_rounded, size: 16, color: AppColors.correctGreen),
              ),
              const SizedBox(width: 8),
              Text(l10n.streakRepairTitle, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              const _CoinTag(50),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _describe(elig),
            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.65)),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (!eligible || busy)
                  ? null
                  : () async {
                      final reason = await ref.read(streakControllerProvider.notifier).repairStreak();
                      if (!context.mounted) return;
                      _toast(context, reason ?? 'Streak repaired!', ok: reason == null);
                    },
              icon: busy
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.handyman_rounded, size: 18),
              label: Text(l10n.streakRepairAction),
            ),
          ),
        ],
      ),
    );
  }

  static String _describe(StreakRepairEligibilityDto? e) {
    if (e == null) return 'Checking repair eligibility…';
    if (e.eligible) {
      final when = e.missedDate?.toLocal().toString().split('.').first;
      return when == null
          ? 'You missed a day. Repair it now to keep the streak.'
          : 'You missed $when. Repair it now to keep the streak.';
    }
    return switch (e.reason) {
      'not_missed_one_day' => 'No missed day to repair — you are up to date.',
      'repair_window_expired' => 'The repair window for your missed day has closed.',
      'monthly_repair_limit_reached' =>
        'Monthly repair limit reached (${e.repairsUsedThisMonth} used).',
      'insufficient_balance' => 'A repair costs 50 coins — top up first.',
      _ => 'No repair available right now.',
    };
  }
}

class _InsuranceCard extends ConsumerWidget {
  const _InsuranceCard({required this.state});
  final StreakState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final ins = state.insurance;
    final active = ins?.activeCount ?? 0;
    final max = ins?.maxActive ?? 0;
    final cost = ins?.costCoins ?? 0;
    final busy = state.isSelfServiceBusy;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.lifelineCyan.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.shield_outlined, size: 16, color: AppColors.lifelineCyan),
              ),
              const SizedBox(width: 8),
              Text(l10n.streakInsurance, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (cost > 0) _CoinTag(cost),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ins == null
                ? l10n.streakInsuranceChecking
                : active > 0
                    ? '$active of $max insurance token${max == 1 ? '' : 's'} banked. One auto-repairs a missed day.'
                    : max > 0
                        ? 'Bank a token and it auto-repairs one missed day for you. Up to $max at a time.'
                        : 'Insurance is not available on your account yet.',
            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.65)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (ins == null || !ins.canPurchase || busy)
                      ? null
                      : () async {
                          final reason = await ref.read(streakControllerProvider.notifier).buyInsurance();
                          if (!context.mounted) return;
                          _toast(context, reason ?? 'Insurance bought!', ok: reason == null);
                        },
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: Text(l10n.streakBuy),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: (active == 0 || busy)
                      ? null
                      : () async {
                          final reason = await ref.read(streakControllerProvider.notifier).useInsurance();
                          if (!context.mounted) return;
                          _toast(context, reason ?? 'Insurance used — streak restored!', ok: reason == null);
                        },
                  icon: busy
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.bolt_rounded, size: 18),
                  label: Text(l10n.streakUseNow),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WagerCard extends ConsumerWidget {
  const _WagerCard({required this.state});
  final StreakState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final wager = state.wager?.wager;
    final busy = state.isSelfServiceBusy;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (wager != null ? AppColors.warnAmber : theme.colorScheme.outlineVariant).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.warnAmber.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.casino_rounded, size: 16, color: AppColors.warnAmber),
              ),
              const SizedBox(width: 8),
              Text(l10n.streakWager, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (wager != null) _CoinTag(wager.coins),
            ],
          ),
          const SizedBox(height: 8),
          if (wager == null)
            Text(
              l10n.streakWagerDescription,
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.65)),
            )
          else ...[
            Text(
              l10n.streakWagerDay(wager.current, wager.days, wager.reward),
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (wager.progressPercent / 100).clamp(0.0, 1.0),
                minHeight: 8,
                color: AppColors.warnAmber,
                backgroundColor: AppColors.warnAmber.withValues(alpha: 0.15),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.streakWagerProgress(wager.progressPercent),
              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (wager != null || busy)
                  ? null
                  : () => _openWagerSheet(context, ref),
              icon: busy
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.local_fire_department_rounded, size: 18),
              label: Text(wager == null ? l10n.streakWagerStart : l10n.streakWagerInProgress),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openWagerSheet(BuildContext context, WidgetRef ref) async {
    final picked = await showModalBottomSheet<(int, int)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => const _WagerSheet(),
    );
    if (picked == null || !context.mounted) return;
    final reason = await ref.read(streakControllerProvider.notifier).openWager(coins: picked.$1, days: picked.$2);
    if (!context.mounted) return;
    _toast(context, reason ?? 'Wager started — good luck!', ok: reason == null);
  }
}

class _WagerSheet extends StatefulWidget {
  const _WagerSheet();

  @override
  State<_WagerSheet> createState() => _WagerSheetState();
}

class _WagerSheetState extends State<_WagerSheet> {
  // Server bounds: coins 50..10000, days 3..30 (routes/api/v1/quiz.php:274-295).
  static const _coinOptions = [50, 100, 250, 500, 1000];
  static const _dayOptions = [3, 7, 14, 30];

  int _coins = 100;
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.streakWagerStartTitle, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              l10n.streakWagerStartBody,
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.65)),
            ),
            const SizedBox(height: 18),
            Text(l10n.streakWagerStake, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final c in _coinOptions)
                  ChoiceChip(
                    label: Text('$c'),
                    selected: _coins == c,
                    onSelected: (_) => setState(() => _coins = c),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(l10n.streakWagerDays, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final d in _dayOptions)
                  ChoiceChip(
                    label: Text(d == 30 ? l10n.streakFreezeDuration : l10n.streakWagerDaysCount(d)),
                    selected: _days == d,
                    onSelected: (_) => setState(() => _days = d),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop((_coins, _days)),
              icon: const Icon(Icons.casino_rounded, size: 18),
              label: Text(l10n.streakWagerSummary(_coins, _days)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinTag extends StatelessWidget {
  const _CoinTag(this.amount);
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppColors.coinYellow.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, size: 13, color: AppColors.coinYellow),
          const SizedBox(width: 3),
          Text('$amount', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.coinYellow)),
        ],
      ),
    );
  }
}

void _toast(BuildContext context, String message, {required bool ok}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: ok ? AppColors.correctGreen : AppColors.wrongRed,
    ),
  );
}
