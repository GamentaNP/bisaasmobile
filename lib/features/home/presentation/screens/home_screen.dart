import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../shared/widgets/chunky/chunky_kit.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../../../shared/widgets/safe_area_scaffold.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../calculator/presentation/controllers/calculator_controller.dart';
import '../../../game/game_providers.dart';
import '../../../gamification/presentation/screens/rewards_screen.dart';
import '../../domain/entities/dashboard_data.dart';
import '../controllers/home_controller.dart';

/// Home — player HUD (streak / coins / XP), daily-streak hero, the real world
/// progression summary, and the explore grid.
///
/// Server-authoritative throughout. The old 15-node decorative trail was
/// removed on 2026-09-27: its completion was computed on-device as
/// `(user.level - 1) % 15` and every node opened the same screen.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userState = ref.watch(authControllerProvider);
    final dashboardState = ref.watch(homeControllerProvider);

    final user = userState.value;
    final name = user != null && user.name.isNotEmpty ? user.name : 'Engineer';

    // Stop nudging a user who has already done the daily. `cancelDaily()` was
    // written but never reachable — bootstrap built its notification service as
    // a local — so the 08:00 "keep the streak alive" reminder fired regardless.
    // Best-effort: a failure here must not break the dashboard.
    ref.listen(homeControllerProvider, (prev, next) {
      final done = next.value?.isDailyCompleted ?? false;
      final wasDone = prev?.value?.isDailyCompleted ?? false;
      if (!done || wasDone) return;
      unawaited(
        ref.read(localNotificationServiceProvider).cancelDaily().catchError((Object e) {
          AppLogger.i('cancelDaily failed (ignored): $e');
        }),
      );
    });

    return SafeAreaScaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(homeControllerProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // 1. Header — greeting (stats live in the ChunkyStatsBar below)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, $name 👋',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Level ${user?.level ?? 1} • ${user?.xp ?? 0} XP',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            ChunkyStatsBar(
              streak: user?.streakDays ?? 0,
              coins: user?.coins,
              xp: user?.xp,
            ),

            const SizedBox(height: 16),

            // 2. Daily streak hero card (green done / orange at risk / blue start)
            dashboardState.when(
              data: (data) => _DailyStreakCard(
                streakDays: data.streakDays,
                isDailyCompleted: data.isDailyCompleted,
                isScheduled: data.dailyQuizScheduled,
                dailyTitle: data.dailyQuizTitle,
                questionCount: data.dailyQuizQuestionsCount,
                xpReward: data.dailyQuizXpReward,
              ),
              loading: () => const _ShimmerCard(height: 120),
              error: (e, _) => _OfflineStreakCard(error: '$e'),
            ),

            const SizedBox(height: 20),

            // 3. Mode cards
            Row(
              children: [
                _ModeCard(
                  icon: Icons.bolt,
                  color: AppColors.xpGold,
                  shadow: AppColors.goldShadow,
                  title: 'Daily',
                  sub: 'Bonus XP',
                  onTap: () => context.go('/quiz'),
                ),
                const SizedBox(width: 12),
                _ModeCard(
                  icon: Icons.sports_kabaddi,
                  color: AppColors.wrongRed,
                  shadow: AppColors.errorShadow,
                  title: 'Battle',
                  sub: '1v1 duel',
                  onTap: () => context.go('/battle'),
                ),
                const SizedBox(width: 12),
                _ModeCard(
                  icon: Icons.grid_view,
                  color: AppColors.violet,
                  shadow: AppColors.purpleShadow,
                  title: 'Browse',
                  sub: 'All topics',
                  onTap: () => context.go('/quiz/browse'),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // 4. Learning path.
            //
            // This used to render 15 decorative nodes generated with
            // `List.generate(15)`, whose completion was derived on-device as
            // `(user.level - 1) % 15` and whose every node navigated to the
            // same screen. The server never computed any of it. The real
            // progression now lives in the world map (GET /quiz/game/worlds →
            // chapters → levels → stars), so the honest home affordance is a
            // real summary that opens it.
            _WorldsEntryCard(),

            const SizedBox(height: 16),

            // Missions — 49 live on the server, previously surfaced nowhere.
            _MissionsEntryCard(),

            const SizedBox(height: 16),

            // Rewards — daily check-in + spin wheel, both live server-side.
            _RewardsEntryCard(),

            const SizedBox(height: 24),

            // 5. Explore the ecosystem — chunky grid
            Text('Explore', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildQuickActionsGrid(context, ref),

            const SizedBox(height: 20),

            // 6. Active course progress — server value, never local math
            dashboardState.when(
              data: (data) => _buildActiveCourseCard(context, data),
              loading: () => const SizedBox.shrink(),
              // The card invents a title ('Structural Analysis & Design (RCC)')
              // when the server sends none, so on failure it is suppressed
              // rather than replaced with something invented. The hero card
              // above already reports the failure honestly.
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, WidgetRef ref) {
    // The catalogue count is server-supplied (`total_calculators`). It was
    // previously a hardcoded "232" in three places; the database actually
    // holds 32 civil calculators, so the badge overstated the product.
    final catalog = ref.watch(calculatorCatalogProvider);
    final total = catalog.value?.totalCalculators ?? 0;
    final calcTitle = total > 0 ? '$total Calculators' : 'Calculators';
    final actions = [
      {
        'title': 'Practice MCQs',
        'subtitle': 'Loksewa & Topic Sets',
        'icon': Icons.quiz_rounded,
        'color': AppColors.brand,
        'shadow': AppColors.brandShadow,
        'route': '/quiz',
      },
      {
        'title': calcTitle,
        'subtitle': 'Civil Formula Engines',
        'icon': Icons.calculate_rounded,
        'color': AppColors.brandAccent,
        'shadow': AppColors.blueShadow,
        'route': '/calculators',
      },
      {
        'title': 'Battle Arena',
        'subtitle': 'Realtime 1v1 PvP',
        'icon': Icons.flash_on_rounded,
        'color': AppColors.warnAmber,
        'shadow': AppColors.warningShadow,
        'route': '/battle',
      },
      {
        'title': 'Play Worlds',
        'subtitle': 'Chapters, Stars & Bosses',
        'icon': Icons.public_rounded,
        'color': AppColors.correctGreen,
        'shadow': AppColors.brandShadow,
        'route': '/game/worlds',
      },
      {
        'title': 'Streak',
        'subtitle': 'Repair, Insurance & Wager',
        'icon': Icons.local_fire_department_rounded,
        'color': AppColors.streakOrange,
        'shadow': AppColors.warningShadow,
        'route': '/streak',
      },
      {
        'title': 'Courses',
        'subtitle': 'Full Syllabus Tracks',
        'icon': Icons.school_rounded,
        'color': AppColors.violet,
        'shadow': AppColors.purpleShadow,
        'route': '/courses',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        // Room for a two-line title plus a one-line subtitle. At 1.35 the
        // subtitle wrapped and every tile threw a "BOTTOM OVERFLOWED BY
        // 10.0 PIXELS" banner on device.
        childAspectRatio: 1.2,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final item = actions[index];
        final color = item['color']! as Color;
        final shadow = item['shadow']! as Color;
        return GlassmorphicCard(
          padding: const EdgeInsets.all(14),
          onTap: () => context.go(item['route']! as String),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border(
                    bottom: BorderSide(color: shadow, width: 3),
                  ),
                ),
                child: Icon(item['icon']! as IconData, color: color, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title']! as String,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['subtitle']! as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveCourseCard(
    BuildContext context,
    DashboardData data,
  ) {
    final theme = Theme.of(context);
    final title = data.activeCourseTitle;
    final progress = data.activeCourseProgress.clamp(0.0, 1.0);
    return ChunkyCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CURRENT COURSE',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiaryLight,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '${(progress * 100).round()}% Done',
                style: const TextStyle(
                  color: AppColors.brand,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title ?? 'Structural Analysis & Design (RCC)',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          ChunkyProgressBar(value: progress, height: 10),
        ],
      ),
    );
  }
}

/// Shown when the dashboard request itself fails.
///
/// This used to render a full `_DailyStreakCard` with an invented
/// `dailyTitle: 'Daily Challenge'`, dressing an outage up as real data. It now
/// says what actually happened and offers a retry.
/// Real progression summary — `GET /api/v1/quiz/game/worlds`.
///
/// Replaces the decorative 15-node trail. Everything shown here is the
/// server's own star/completion figure; a failing read collapses the card
/// rather than inventing a progress bar.
/// Rewards summary — daily check-in + spin wheel.
///
/// Both have been live server-side all along; neither had a UI.
class _RewardsEntryCard extends ConsumerWidget {
  const _RewardsEntryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkIn = ref.watch(checkInStatusProvider);

    return ChunkyCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.go('/rewards'),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard_rounded, size: 20, color: AppColors.streakOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              checkIn.maybeWhen(
                // Only promise a reward when the server says one is waiting.
                data: (d) => d.canClaim
                    ? 'Check in for ${d.todayReward} coins'
                    : 'Rewards — spin the wheel',
                orElse: () => 'Rewards — spin the wheel',
              ),
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: checkIn.maybeWhen(data: (d) => d.canClaim ? AppColors.correctGreen : null, orElse: () => null),
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 20),
        ],
      ),
    );
  }
}

/// Missions summary — `GET /api/v1/quiz/game/missions/dashboard`.
///
/// 49 missions are live server-side and were previously surfaced nowhere in the
/// app. Shows how many are ready to claim, straight from the server's flags.
class _MissionsEntryCard extends ConsumerWidget {
  const _MissionsEntryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionsAsync = ref.watch(gameMissionsProvider);

    return missionsAsync.when(
      loading: () => const _ShimmerCard(height: 64),
      error: (_, __) => ChunkyCard(
        padding: const EdgeInsets.all(14),
        onTap: () => context.go('/game/missions'),
        child: const Row(
          children: [
            Icon(Icons.flag_outlined, size: 20, color: AppColors.textTertiaryLight),
            SizedBox(width: 10),
            Expanded(
              child: Text('Missions unavailable', style: TextStyle(fontSize: 13)),
            ),
            Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
      ),
      data: (missions) {
        final claimable = missions.where((m) => m.isClaimable).length;
        return ChunkyCard(
          padding: const EdgeInsets.all(14),
          onTap: () => context.go('/game/missions'),
          child: Row(
            children: [
              Icon(
                claimable > 0 ? Icons.card_giftcard_rounded : Icons.flag_outlined,
                size: 20,
                color: claimable > 0 ? AppColors.correctGreen : AppColors.textTertiaryLight,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  claimable > 0
                      ? '$claimable mission${claimable == 1 ? '' : 's'} ready to claim'
                      : 'Missions — ${missions.length} active',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: claimable > 0 ? AppColors.correctGreen : null,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
        );
      },
    );
  }
}

class _WorldsEntryCard extends ConsumerWidget {
  const _WorldsEntryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worldsAsync = ref.watch(gameWorldsProvider);

    return worldsAsync.when(
      loading: () => const _ShimmerCard(height: 96),
      error: (_, __) => ChunkyCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.public_off_rounded, size: 24, color: AppColors.textTertiaryLight),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Could not load your worlds',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(gameWorldsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (worlds) {
        if (worlds.isEmpty) {
          return ChunkyCard(
            padding: const EdgeInsets.all(16),
            child: const Row(
              children: [
                Icon(Icons.public_rounded, size: 24, color: AppColors.textTertiaryLight),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No worlds published yet — browse topics to keep practising.',
                    style: TextStyle(fontSize: 13, color: AppColors.textTertiaryLight),
                  ),
                ),
              ],
            ),
          );
        }

        final totalStars = worlds.fold<int>(0, (sum, w) => sum + w.totalStarsEarned);
        final maxStars = worlds.fold<int>(0, (sum, w) => sum + w.totalMaxStars);
        final next = worlds.firstWhere(
          (w) => w.isUnlocked,
          orElse: () => worlds.first,
        );
        final overall = maxStars > 0 ? (totalStars / maxStars).clamp(0.0, 1.0) : 0.0;

        return ChunkyCard(
          padding: const EdgeInsets.all(16),
          onTap: () => context.go('/game/worlds'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.public_rounded, size: 22, color: AppColors.brand),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your worlds',
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '$totalStars / $maxStars ⭐',
                    style: AppTypography.titleSmall.copyWith(color: AppColors.xpGold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ChunkyProgressBar(value: overall, color: AppColors.xpGold, height: 10),
              const SizedBox(height: 10),
              Text(
                'Continue: ${next.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OfflineStreakCard extends StatelessWidget {
  const _OfflineStreakCard({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return ChunkyCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 26, color: AppColors.textTertiaryLight),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Could not load your dashboard',
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Nothing is shown rather than guessing. Pull to refresh, or retry below.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiaryLight),
                ),
                const SizedBox(height: 4),
                Text(
                  error,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiaryLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyStreakCard extends StatelessWidget {
  const _DailyStreakCard({
    required this.streakDays,
    required this.isDailyCompleted,
    required this.isScheduled,
    required this.dailyTitle,
    required this.questionCount,
    required this.xpReward,
  });

  final int streakDays;
  final bool isDailyCompleted;

  /// The server has a daily quiz scheduled for today.
  final bool isScheduled;

  /// `null` when the server published no title.
  final String? dailyTitle;
  final int questionCount;

  /// `null` when the server published no reward — the card then omits the
  /// figure rather than printing a made-up "+N XP".
  final int? xpReward;

  /// One-line summary of the scheduled quiz, built only from fields the
  /// server actually sent. Omitted entirely when it would be empty.
  String get _scheduleDetail {
    final parts = <String>[
      if (dailyTitle != null && dailyTitle!.isNotEmpty) dailyTitle!,
      if (questionCount > 0) '$questionCount questions',
      if (xpReward != null && xpReward! > 0) '+$xpReward XP',
    ];
    return parts.isEmpty ? 'Ready to play' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final gradient = isDailyCompleted
        ? AppColors.brandGradient
        : streakDays > 0
            ? AppColors.streakGradient
            : AppColors.infoGradient;

    // Copy is derived from real state only. When no daily quiz is scheduled we
    // say so — we never imply a quiz exists.
    final (tag, title, desc) = switch ((isDailyCompleted, isScheduled, streakDays)) {
      (true, _, _) => (
          'DONE FOR TODAY',
          'Streak safe · $streakDays🔥',
          'Come back tomorrow to keep it going',
        ),
      (false, true, 0) => (
          'DAILY QUIZ READY',
          'Play today’s daily quiz',
          _scheduleDetail,
        ),
      (false, true, _) => (
          'STREAK AT RISK',
          'Keep your $streakDays-day streak alive',
          _scheduleDetail,
        ),
      (false, false, 0) => (
          'START YOUR STREAK',
          'Play 1 quiz to start',
          'No daily quiz is scheduled today — any quiz counts',
        ),
      (false, false, _) => (
          'STREAK AT RISK',
          'Keep your $streakDays-day streak alive',
          'No daily quiz today — play any quiz to keep it',
        ),
    };

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/quiz'),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              bottom: BorderSide(
                color: Colors.black.withValues(alpha: 0.18),
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tag,
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: AppTypography.headlineSmall.copyWith(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isDailyCompleted
                      ? Icons.check_circle
                      : streakDays > 0
                          ? Icons.local_fire_department
                          : Icons.flag,
                  size: 48,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.color,
    required this.shadow,
    required this.title,
    required this.sub,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color shadow;
  final String title;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            height: 96,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              border: Border(bottom: BorderSide(color: shadow, width: 4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, size: 26, color: Colors.white),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleMedium
                            .copyWith(color: Colors.white),
                      ),
                      Text(
                        sub,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
