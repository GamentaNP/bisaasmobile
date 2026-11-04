import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/chunky/chunky_button.dart';
import '../../../../shared/widgets/chunky/chunky_kit.dart';
import '../../domain/entities/arcade_mode.dart';
import '../controllers/arcade_controller.dart';

/// The server's verdict on the run.
///
/// Every figure on this screen comes from the completion or results payload.
/// The screen adds no arithmetic the server did not already do — accuracy is a
/// presentation of `correct / (correct + wrong + skipped)`.
class ArcadeResultScreen extends ConsumerWidget {
  const ArcadeResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final run = ref.watch(arcadeControllerProvider);
    final result = run.result;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.arcadeResultTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.arcadeEmptyTitle, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go('/arcade'),
                  child: Text(l10n.arcadeBackToArcade),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.arcadeResultTitle),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: l10n.arcadeBackToArcade,
            onPressed: () {
              ref.read(arcadeControllerProvider.notifier).reset();
              context.go('/arcade');
            },
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          if (run.gameOver)
            _GameOverBanner(
              title: l10n.arcadeGameOver,
              body: l10n.arcadeGameOverBody,
            ),
          _ScoreHero(
            scoreLabel: l10n.arcadeScore,
            score: result.score,
            modeLabel: _modeLabel(run.mode, l10n),
          ),
          const SizedBox(height: 18),
          _Accuracy(
            label: l10n.arcadeAccuracy,
            value: result.accuracy,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: l10n.arcadeCorrect,
                  value: result.correctCount,
                  color: AppColors.brandDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: l10n.arcadeWrong,
                  value: result.wrongCount,
                  color: AppColors.errorShadow,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: l10n.arcadeSkipped,
                  value: result.skippedCount,
                  color: AppColors.warningShadow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          ChunkyButton(
            label: l10n.arcadePlayAgain,
            icon: Icons.replay_rounded,
            onPressed: () {
              final mode = run.mode;
              if (mode == null) {
                context.go('/arcade');
                return;
              }
              ref
                  .read(arcadeControllerProvider.notifier)
                  .start(mode, category: run.category);
              context.pushReplacement('/arcade/play', extra: mode);
            },
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              ref.read(arcadeControllerProvider.notifier).reset();
              context.go('/arcade');
            },
            child: Text(l10n.arcadeBackToArcade),
          ),
        ],
      ),
    );
  }

  static String _modeLabel(ArcadeMode? mode, AppLocalizations l10n) =>
      switch (mode) {
        ArcadeMode.survival => l10n.arcadeSurvivalTitle,
        ArcadeMode.lightning => l10n.arcadeLightningTitle,
        ArcadeMode.trueFalse => l10n.arcadeTrueFalseTitle,
        null => l10n.arcadeTitle,
      };
}

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({
    required this.scoreLabel,
    required this.score,
    required this.modeLabel,
  });

  final String scoreLabel;
  final int score;
  final String modeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          modeLabel.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            letterSpacing: 1.4,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$score',
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.brand,
            height: 1.05,
          ),
        ),
        Text(
          scoreLabel,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _Accuracy extends StatelessWidget {
  const _Accuracy({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (value * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            Text(
              '$percent%',
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ChunkyProgressBar(value: value.clamp(0, 1)),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChunkyCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        children: [
          Text(
            '$value',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameOverBanner extends StatelessWidget {
  const _GameOverBanner({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorShadow.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.errorShadow.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.local_fire_department_rounded,
              color: AppColors.errorShadow, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(body, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
