import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/chunky/chunky_button.dart';
import '../../../../shared/widgets/chunky/chunky_kit.dart';
import '../../data/models/game_models.dart';

/// Pre-level briefing sheet for a world-map level node.
///
/// Every number rendered here comes from
/// `GET /api/v1/quiz/game/world/{slug}/map` — the same payload that drew the
/// node. Nothing is inferred client-side: when the server omits a field the
/// row is omitted too, rather than filled with a placeholder.
///
/// The play CTA routes through the proven course-question attempt path
/// (`POST /api/v1/quiz/attempts/start` via `QuizAttemptScreen`), which is the
/// only path today that yields a graded attempt, real XP and real stars:
/// there is no `POST /quiz/game/levels/{level}/start` on the server, and the
/// attempt screen seeds its own session from a course id. Levels are
/// therefore played through [courseId] — the world's `quiz_course_id`. When a
/// world has no linked course the CTA is disabled with an explicit message
/// instead of navigating somewhere that cannot work.
class GameLevelIntroSheet extends StatelessWidget {
  const GameLevelIntroSheet({
    super.key,
    required this.level,
    this.courseId,
  });

  final GameLevelDto level;

  /// `world.quiz_course_id` from the map payload. `null` ⇒ the level is
  /// display-only (no play path exists for it yet).
  final int? courseId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final face = isDark ? AppColors.cardDark : AppColors.surfaceLight;
    final side = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    final muted = isDark ? AppColors.textTertiaryDark : AppColors.textSecondaryLight;
    final heading = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final playable = courseId != null;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: face,
          borderRadius: AppRadii.sheet,
          border: Border(top: BorderSide(color: side, width: 3)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: side,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _LevelBadge(level: level),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          level.title?.trim().isNotEmpty == true
                              ? level.title!.trim()
                              : 'Level ${level.levelNumber}',
                          style: AppTypography.titleLarge.copyWith(color: heading),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          level.isBoss ? 'Boss level' : 'Chapter level',
                          style: AppTypography.bodySmall.copyWith(
                            color: level.isBoss ? AppColors.streakOrange : muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (level.description != null && level.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  level.description!.trim(),
                  style: AppTypography.bodyMedium.copyWith(color: muted),
                ),
              ],
              const SizedBox(height: 18),
              // Reward + shape row. Only rows the server actually sent.
              Row(
                children: [
                  if (level.questionCount > 0) ...[
                    Expanded(
                      child: _StatTile(
                        icon: Icons.help_outline_rounded,
                        label: '${level.questionCount}',
                        caption: 'Questions',
                        color: AppColors.brandAccent,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (level.xpReward > 0) ...[
                    Expanded(
                      child: _StatTile(
                        icon: Icons.bolt,
                        label: '${level.xpReward}',
                        caption: 'XP',
                        color: AppColors.xpGold,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (level.coinReward > 0)
                    Expanded(
                      child: _StatTile(
                        icon: Icons.monetization_on,
                        label: '${level.coinReward}',
                        caption: 'Coins',
                        color: AppColors.coinYellow,
                      ),
                    ),
                ],
              ),
              if (level.questionCount <= 0 &&
                  level.xpReward <= 0 &&
                  level.coinReward <= 0)
                Text(
                  'The server sent no reward data for this level yet.',
                  style: AppTypography.bodySmall.copyWith(color: muted),
                ),
              if (level.difficultyBand != null || level.timeLimitSeconds != null) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (level.difficultyBand != null)
                      _Chip(
                        text: _difficultyLabel(level.difficultyBand!),
                        color: _difficultyColor(level.difficultyBand!),
                      ),
                    if (level.timeLimitSeconds != null && level.timeLimitSeconds! > 0)
                      _Chip(
                        text: '${level.timeLimitSeconds}s per question',
                        color: AppColors.lifelineCyan,
                      ),
                  ],
                ),
              ],
              if (level.starsEarned > 0) ...[
                const SizedBox(height: 16),
                Row(
                  children: List.generate(
                    3,
                    (i) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        i < level.starsEarned ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 22,
                        color: i < level.starsEarned ? AppColors.xpGold : side,
                      ),
                    ),
                  ),
                ),
              ],
              if (level.bestScore != null || level.bestAccuracyPct != null) ...[
                const SizedBox(height: 14),
                ChunkyCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (level.bestScore != null)
                        _BestStat(label: 'Best score', value: level.bestScore!.toStringAsFixed(1)),
                      if (level.bestAccuracyPct != null)
                        _BestStat(
                          label: 'Best accuracy',
                          value: '${level.bestAccuracyPct!.toStringAsFixed(0)}%',
                        ),
                      if (level.bestTimeSeconds != null)
                        _BestStat(
                          label: 'Best time',
                          value: '${level.bestTimeSeconds}s',
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ChunkyButton(
                label: playable ? 'Start level' : 'Not playable yet',
                icon: playable ? Icons.play_arrow_rounded : Icons.lock_rounded,
                variant: level.isBoss ? ChunkyVariant.warning : ChunkyVariant.primary,
                onPressed: playable ? () => _start(context) : null,
              ),
              if (!playable) ...[
                const SizedBox(height: 10),
                Text(
                  'This world has no quiz course linked to it yet, so there is '
                  "nothing to play. Ask an admin to set the world's course.",
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(color: muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _start(BuildContext context) {
    final id = courseId;
    if (id == null) return;
    // The attempt screen seeds its own graded session from this course, which
    // is what awards XP/coins/stars server-side today.
    context.go('/quiz/$id');
  }

  static String _difficultyLabel(String band) => switch (band) {
        'easy' => 'Easy',
        'medium' => 'Medium',
        'hard' => 'Hard',
        'mixed' => 'Mixed',
        _ => band,
      };

  static Color _difficultyColor(String band) => switch (band) {
        'easy' => AppColors.correctGreen,
        'medium' => AppColors.warnAmber,
        'hard' => AppColors.wrongRed,
        _ => AppColors.lifelineCyan,
      };
}

/// The level's identity chip — crown for a boss, number otherwise.
class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final GameLevelDto level;

  @override
  Widget build(BuildContext context) {
    final isBoss = level.isBoss;
    final face = isBoss ? AppColors.streakOrange : AppColors.brand;
    final side = isBoss ? AppColors.warningShadow : AppColors.brandShadow;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: face,
        shape: BoxShape.circle,
        border: Border(bottom: BorderSide(color: side, width: 4)),
      ),
      alignment: Alignment.center,
      child: isBoss
          ? const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 30)
          : Text(
              '${level.levelNumber}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 24,
              ),
            ),
    );
  }
}

/// Reward / shape tile: big value, small caption.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.caption,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ChunkyCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleLarge.copyWith(fontSize: 19, color: color),
          ),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textTertiaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BestStat extends StatelessWidget {
  const _BestStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).brightness == Brightness.dark
        ? AppColors.textTertiaryDark
        : AppColors.textSecondaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        Text(label, style: AppTypography.bodySmall.copyWith(color: muted)),
      ],
    );
  }
}
