import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/cached_remote_image.dart';
import '../../../../shared/widgets/chunky/chunky_button.dart';
import '../../../../shared/widgets/chunky/chunky_kit.dart';
import '../../domain/entities/arcade_mode.dart';
import '../../domain/entities/arcade_question.dart';
import '../controllers/arcade_controller.dart';

/// One arcade run.
///
/// The screen never says "correct" or "wrong": the API withholds grading until
/// the attempt completes, so the honest feedback is "answer saved" and a score
/// at the end. Survival is the exception in feel but not in mechanism — the
/// server ends that attempt on a wrong answer, the screen finds out when the
/// re-fetch says so, and the result screen explains it.
class ArcadePlayScreen extends ConsumerWidget {
  const ArcadePlayScreen({super.key, this.mode});

  /// Passed by the hub so a deep link without state can restart the right mode.
  final ArcadeMode? mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final run = ref.watch(arcadeControllerProvider);

    ref.listen<ArcadeState>(arcadeControllerProvider, (previous, next) {
      if (next.phase == ArcadePhase.finished &&
          previous?.phase != ArcadePhase.finished) {
        context.pushReplacement('/arcade/result');
      }
    });

    if (run.phase == ArcadePhase.starting) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.arcadeStarting)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (run.phase == ArcadePhase.failed) {
      return _RunFailure(
        message: ErrorHandler.handle(run.error ?? StateError('arcade'))
            .message,
        onRetry: mode == null && run.mode == null
            ? null
            : () => ref.read(arcadeControllerProvider.notifier).start(
                  run.mode ?? mode!,
                  category: run.category,
                ),
      );
    }

    final question = run.current;
    if (run.phase == ArcadePhase.idle || question == null) {
      // Reached by a deep link, or after the run was reset. Not an error, but
      // there is nothing to play.
      return Scaffold(
        appBar: AppBar(title: Text(l10n.arcadeTitle)),
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

    return _RunScaffold(run: run, question: question);
  }
}

class _RunScaffold extends ConsumerWidget {
  const _RunScaffold({required this.run, required this.question});

  final ArcadeState run;
  final ArcadeQuestion question;

  Future<void> _confirmQuit(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.arcadeQuitTitle),
        content: Text(l10n.arcadeQuitBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.arcadeQuitCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.arcadeQuitConfirm),
          ),
        ],
      ),
    );
    if (leave != true || !context.mounted) return;
    await ref.read(arcadeControllerProvider.notifier).quit();
    if (context.mounted) context.go('/arcade');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final mode = run.mode;
    final submitting = run.phase == ArcadePhase.submitting ||
        run.phase == ArcadePhase.finishing;
    final timedOutThisQuestion = submitting && run.selectedOptionId == null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmQuit(context, ref);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _RunHeader(
                title: _title(mode, l10n),
                progressLabel: l10n.arcadeQuestionProgress(
                  run.questionNumber,
                  run.totalQuestions,
                ),
                progress: run.totalQuestions == 0
                    ? 0
                    : run.questionNumber / run.totalQuestions,
                secondsLeft: mode?.isTimed ?? false ? run.secondsLeft : null,
                onQuit: () => _confirmQuit(context, ref),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    if (timedOutThisQuestion)
                      _TimeUpBanner(label: l10n.arcadeTimeUp)
                    else if (submitting)
                      _SavedBanner(label: l10n.arcadeAnswerSaved),
                    const SizedBox(height: 8),
                    ChunkyCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (question.imageUrl != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedRemoteImage(
                                url: question.imageUrl!,
                                fit: BoxFit.contain,
                                height: 180,
                                fallback: Container(
                                  height: 180,
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  child: const Icon(Icons.image_not_supported_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          Text(
                            question.body,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!question.hasOptions)
                      Text(
                        l10n.arcadeEmptyBody,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    for (final option in question.options)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _OptionButton(
                          label: option.text,
                          selected: run.selectedOptionId == option.id,
                          enabled: !submitting,
                          onTap: () => ref
                              .read(arcadeControllerProvider.notifier)
                              .answer(option.id),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _title(ArcadeMode? mode, AppLocalizations l10n) =>
      switch (mode) {
        ArcadeMode.survival => l10n.arcadeSurvivalTitle,
        ArcadeMode.lightning => l10n.arcadeLightningTitle,
        ArcadeMode.trueFalse => l10n.arcadeTrueFalseTitle,
        null => l10n.arcadeTitle,
      };
}

class _RunHeader extends StatelessWidget {
  const _RunHeader({
    required this.title,
    required this.progressLabel,
    required this.progress,
    required this.secondsLeft,
    required this.onQuit,
  });

  final String title;
  final String progressLabel;
  final double progress;
  final int? secondsLeft;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seconds = secondsLeft;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      progressLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              if (seconds != null)
                _TimerBadge(
                  seconds: seconds,
                  danger: seconds <= 2,
                ),
              IconButton(
                onPressed: onQuit,
                icon: const Icon(Icons.close_rounded),
                tooltip: AppLocalizations.of(context)!.arcadeQuitConfirm,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ChunkyProgressBar(value: progress.clamp(0, 1)),
        ],
      ),
    );
  }
}

class _TimerBadge extends StatelessWidget {
  const _TimerBadge({required this.seconds, required this.danger});

  final int seconds;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = danger ? AppColors.errorShadow : AppColors.warningShadow;
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: danger ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_rounded, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            l10n.arcadeTimeLeft(seconds),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final face = selected
        ? AppColors.brand.withValues(alpha: 0.14)
        : theme.colorScheme.surface;
    final side = selected ? AppColors.brand : AppColors.dividerLight;

    return Opacity(
      opacity: enabled || selected ? 1 : 0.6,
      child: Material(
        color: side,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled ? onTap : null,
          child: Ink(
            decoration: BoxDecoration(
              color: face,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? AppColors.brand
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: selected ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.brand, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeUpBanner extends StatelessWidget {
  const _TimeUpBanner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return _Banner(
      color: AppColors.errorShadow,
      icon: Icons.timer_off_rounded,
      label: label,
    );
  }
}

class _SavedBanner extends StatelessWidget {
  const _SavedBanner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return _Banner(
      color: AppColors.brandDark,
      icon: Icons.cloud_done_rounded,
      label: label,
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RunFailure extends StatelessWidget {
  const _RunFailure({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.arcadeLoadError)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 48, color: AppColors.errorShadow),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              if (onRetry != null)
                ChunkyButton(
                  label: l10n.arcadeRetry,
                  size: ChunkySize.md,
                  onPressed: onRetry,
                ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => context.go('/arcade'),
                child: Text(l10n.arcadeBackToArcade),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
