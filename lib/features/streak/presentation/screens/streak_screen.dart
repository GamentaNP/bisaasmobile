// ignore_for_file: unnecessary_non_null_assertion, avoid_escaping_inner_quotes

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../domain/entities/streak.dart';
import '../controllers/streak_controller.dart';
import '../widgets/streak_calendar.dart';

/// Streak screen — `GET /quiz/streak` (+ `POST /donations/freeze-streak`).
/// Server-authoritative: Flutter never computes streak locally, only visualizes.
/// Calendar + repair/insurance/wager placeholders gated on WO-6 if no API.
class StreakScreen extends ConsumerStatefulWidget {
  const StreakScreen({super.key});

  @override
  ConsumerState<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends ConsumerState<StreakScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(streakControllerProvider.notifier).fetchStreak());
  }

  Future<void> _onRefresh() async {
    await ref.read(streakControllerProvider.notifier).fetchStreak();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(streakControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Streak'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: state.isLoading ? null : () => ref.read(streakControllerProvider.notifier).fetchStreak(),
            tooltip: 'Refresh',
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
        children: const [
          SizedBox(height: 80),
          EmptyState(title: 'No streak yet', subtitle: 'Complete a quiz to start your fire streak.', icon: Icons.local_fire_department_rounded),
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
        Text('Calendar', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
              ? 'You are on fire today — keep it up!'
              : streak.isAtRisk
                  ? 'At risk — complete a quiz before midnight to keep ${streak.currentStreak} days alive.'
                  : 'Complete today\'s quiz to grow your streak.',
          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 20),
        _FreezeSection(state: state, streak: streak, onFreeze: _freeze),
        const SizedBox(height: 20),
        Text('Protect your streak', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const _ComingSoonRow(),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _freeze() async {
    final ok = await ref.read(streakControllerProvider.notifier).freezeStreak();
    if (!mounted) return;
    final state = ref.read(streakControllerProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Streak frozen for 30 days!' : (state.freezeError ?? 'Freeze failed — check coins or donor badge.')),
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
                const Text('Current streak', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${streak.currentStreak}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, height: 1)),
                    const SizedBox(width: 6),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text('days', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Best: ${streak.longestStreak} days', style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
              const Text('multiplier', style: TextStyle(color: Colors.white70, fontSize: 10)),
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
              Text('×${streak.streakMultiplier.toStringAsFixed(1)} XP', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.streakOrange)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress, backgroundColor: theme.colorScheme.surfaceContainerHighest, color: AppColors.streakOrange, minHeight: 6, borderRadius: BorderRadius.circular(6)),
          const SizedBox(height: 6),
          Text(
            nextThreshold == null ? 'Max multiplier reached — legendary!' : '${streak.currentStreak} / $nextThreshold days to next tier',
            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 6),
          Text(
            '1–6d → 1.0× • 7–29d → 1.5× • 30–99d → 2.0× • 100+d → 3.0×',
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
              Text('Streak freeze', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (streak.freezeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.correctGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text('${streak.freezeCount} left', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.correctGreen)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasFreeze ? 'Frozen until ${frozenUntil!.toLocal().toString().split('.').first}' : 'Spend 50 coins to freeze streak for 30 days when you cannot play. Donor badge required.',
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
              label: Text(hasFreeze ? 'Extend freeze' : 'Freeze streak (50 coins)'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonRow extends StatelessWidget {
  const _ComingSoonRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // WO-6 gated placeholders: repair / insurance / wager — show as disabled with coming-soon.
    Widget chip(IconData icon, String label) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Icon(icon, size: 22, color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
                const SizedBox(height: 6),
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                  child: const Text('WO-6', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.brand)),
                ),
              ],
            ),
          ),
        );

    return Row(
      children: [
        chip(Icons.build_rounded, 'Repair'),
        const SizedBox(width: 10),
        chip(Icons.shield_outlined, 'Insurance'),
        const SizedBox(width: 10),
        chip(Icons.casino_rounded, 'Wager'),
      ],
    );
  }
}
