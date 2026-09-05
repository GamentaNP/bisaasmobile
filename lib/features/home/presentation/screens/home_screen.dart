import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/chunky/chunky_kit.dart';
import '../../../../shared/widgets/chunky/chunky_path_node.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../../../shared/widgets/safe_area_scaffold.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../home/domain/entities/dashboard_data.dart';
import '../controllers/home_controller.dart';

/// Learning Path home — the sample's zig-zag trail of chunky level nodes
/// with the gamified header (streak / coins / XP) and daily-streak hero.
/// Server-authoritative: node progress derives from the backend level.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _nodeCount = 15;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userState = ref.watch(authControllerProvider);
    final dashboardState = ref.watch(homeControllerProvider);

    final user = userState.value;
    final name = user != null && user.name.isNotEmpty ? user.name : 'Engineer';

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
                dailyTitle: data.dailyQuizTitle,
                questionCount: data.dailyQuizQuestionsCount,
                xpReward: data.dailyQuizXpReward,
              ),
              loading: () => const _ShimmerCard(height: 120),
              error: (_, __) => const _DailyStreakCard(
                streakDays: 0,
                isDailyCompleted: false,
                dailyTitle: 'Daily Challenge',
                questionCount: 0,
                xpReward: 0,
              ),
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

            // 4. Zig-zag learning path
            Center(
              child: Column(
                children: [
                  ...List.generate(_nodeCount, (i) {
                    final current = (user?.level ?? 1) - 1;
                    final status = i < (current % _nodeCount)
                        ? PathNodeStatus.completed
                        : i == (current % _nodeCount)
                            ? PathNodeStatus.current
                            : PathNodeStatus.locked;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: ChunkyPathNode(
                        status: status,
                        index: i,
                        onTap: () => context.go('/quiz/browse'),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  const PathTrophyEnd(),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 5. Explore the ecosystem — chunky grid
            Text('Explore', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildQuickActionsGrid(context),

            const SizedBox(height: 20),

            // 6. Active course progress — server value, never local math
            dashboardState.when(
              data: (data) => _buildActiveCourseCard(context, data),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
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
        'title': '232 Calculators',
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
        childAspectRatio: 1.35,
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

class _DailyStreakCard extends StatelessWidget {
  const _DailyStreakCard({
    required this.streakDays,
    required this.isDailyCompleted,
    required this.dailyTitle,
    required this.questionCount,
    required this.xpReward,
  });

  final int streakDays;
  final bool isDailyCompleted;
  final String dailyTitle;
  final int questionCount;
  final int xpReward;

  @override
  Widget build(BuildContext context) {
    final gradient = isDailyCompleted
        ? AppColors.brandGradient
        : streakDays > 0
            ? AppColors.streakGradient
            : AppColors.infoGradient;
    final tag = isDailyCompleted
        ? 'DONE FOR TODAY'
        : streakDays > 0
            ? 'STREAK AT RISK'
            : 'START YOUR STREAK';
    final title = isDailyCompleted
        ? 'Streak safe · $streakDays🔥'
        : streakDays > 0
            ? 'Keep your $streakDays-day streak alive'
            : 'Play 1 quiz to start';
    final desc = isDailyCompleted
        ? 'Come back tomorrow for +XP'
        : questionCount > 0
            ? '$dailyTitle · $questionCount questions · +$xpReward XP'
            : 'Complete today\'s quiz to grow the streak';

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
