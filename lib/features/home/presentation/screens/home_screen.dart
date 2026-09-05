import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../../../shared/widgets/safe_area_scaffold.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../gamification/presentation/widgets/xp_progress_bar.dart';
import '../controllers/home_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userState = ref.watch(authControllerProvider);
    final dashboardState = ref.watch(homeControllerProvider);

    final user = userState.value;

    return SafeAreaScaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(homeControllerProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 1. Top HUD Header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.brand.withValues(alpha: 0.2),
                  child: Text(
                    user != null && user.name.isNotEmpty
                        ? user.name[0].toUpperCase()
                        : 'C',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brand,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user != null ? 'Hello, ${user.name}' : 'Welcome, Engineer',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Level ${user?.level ?? 1} Scholar',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                // Coins balance pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.coinYellow.withValues(alpha: 0.15),
                    border: Border.all(
                      color: AppColors.coinYellow.withValues(alpha: 0.4),
                    ),
                    borderRadius: AppRadii.pillAll,
                    boxShadow: AppShadows.glowGold,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.monetization_on_rounded,
                        size: 18,
                        color: AppColors.coinYellow,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${user?.coins ?? 120}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.coinYellow,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 2. Streak Card
            dashboardState.when(
              data: (data) => _buildStreakCard(context, data.streakDays),
              loading: () => _buildShimmerCard(context, height: 72),
              error: (_, __) => _buildStreakCard(context, 1),
            ),

            const SizedBox(height: 14),

            // 2b. XP Progress — server level, never computed locally
            dashboardState.when(
              data: (data) => XpProgressBar(
                level: data.level,
                currentXp: data.currentXp,
                nextLevelXp: data.nextLevelXp,
              ),
              loading: () => _buildShimmerCard(context, height: 86),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 20),

            // 3. Daily Quiz Flagship Challenge Card
            dashboardState.when(
              data: (data) => _buildDailyQuizCard(context, data),
              loading: () => _buildShimmerCard(context, height: 160),
              error: (_, __) => _buildDailyQuizCard(
                context,
                null,
              ),
            ),

            const SizedBox(height: 24),

            // 4. Quick Actions Section
            Text(
              'Explore Ecosystem',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickActionsGrid(context),

            const SizedBox(height: 24),

            // 5. Active Course Progress
            dashboardState.when(
              data: (data) => _buildActiveCourseCard(context, data),
              loading: () => _buildShimmerCard(context, height: 110),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, int streakDays) {
    return GlassmorphicCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      glow: true,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.streakOrange.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: AppColors.streakOrange,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streakDays Day Streak Active!',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.streakOrange,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Complete your daily quiz to keep the momentum going.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyQuizCard(BuildContext context, dynamic data) {
    final theme = Theme.of(context);
    final isCompleted = data?.isDailyCompleted == true;
    return GlassmorphicCard(
      padding: const EdgeInsets.all(20),
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.15),
                  borderRadius: AppRadii.smAll,
                ),
                child: const Text(
                  'DAILY SPRINT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brand,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.bolt_rounded, size: 16, color: AppColors.xpGold),
                  const SizedBox(width: 4),
                  Text(
                    '+${data?.dailyQuizXpReward ?? 150} XP',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.xpGold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data?.dailyQuizTitle ?? 'Civil Engineering Daily Challenge',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${data?.dailyQuizQuestionsCount ?? 10} calibrated MCQs covering Surveying, RCC, & Fluid Mechanics.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 16),
          GradientButton(
            label: isCompleted ? 'Completed — Play Again' : 'Start Daily Quiz',
            icon: Icons.play_arrow_rounded,
            onPressed: () => context.go('/quiz'),
          ),
        ],
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
        'route': '/quiz',
      },
      {
        'title': '232 Calculators',
        'subtitle': 'Civil Formula Engines',
        'icon': Icons.calculate_rounded,
        'color': const Color(0xFF10B981),
        'route': '/calculators',
      },
      {
        'title': 'Battle Arena',
        'subtitle': 'Realtime 1v1 PvP',
        'icon': Icons.flash_on_rounded,
        'color': const Color(0xFFF59E0B),
        'route': '/battle',
      },
      {
        'title': 'Courses',
        'subtitle': 'Full Syllabus Tracks',
        'icon': Icons.school_rounded,
        'color': const Color(0xFFA855F7),
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
                  borderRadius: AppRadii.smAll,
                ),
                child: Icon(item['icon']! as IconData, color: color, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title']! as String,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['subtitle']! as String,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiaryDark,
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

  Widget _buildActiveCourseCard(BuildContext context, dynamic data) {
    final theme = Theme.of(context);
    final title = data?.activeCourseTitle;
    final progress = (data?.activeCourseProgress ?? 0.0).clamp(0.0, 1.0);
    return GlassmorphicCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Course',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondaryDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(progress * 100).round()}% Done',
                style: const TextStyle(
                  color: AppColors.brand,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title ?? 'Structural Analysis & Design (RCC)',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: AppRadii.pillAll,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceRaisedDark,
              color: AppColors.brand,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerCard(BuildContext context, {required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: AppRadii.card,
      ),
    );
  }
}
