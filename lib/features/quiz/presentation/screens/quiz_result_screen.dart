import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../gamification/presentation/widgets/answer_feedback_lottie.dart';
import '../../../gamification/presentation/widgets/lottie_overlay.dart';
import '../state/quiz_state.dart';

/// Results screen shown after quiz completion — summarizes server-authoritative
/// totals (XP, coins, accuracy, streak).
class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({required this.quizState, super.key});
  final QuizState quizState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = quizState.session;
    final answered = quizState.answers.length;
    final correct =
        quizState.answers.values.where((r) => r.isCorrect).length;
    final accuracy = answered > 0 ? correct / answered : 0.0;
    final totalQ = session?.totalQuestions ?? answered;

    Color gradeColor;
    String gradeLabel;
    if (accuracy >= 0.8) {
      gradeColor = AppColors.correctGreen;
      gradeLabel = 'Excellent!';
    } else if (accuracy >= 0.5) {
      gradeColor = AppColors.brand;
      gradeLabel = 'Good Job!';
    } else {
      gradeColor = AppColors.wrongRed;
      gradeLabel = 'Keep Practicing';
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Celebratory confetti on first frame (server-graded only).
              _ConfettiOnMount(
                celebrate: !quizState.isOfflinePractice,
                coinsEarned: quizState.totalCoinsEarned,
              ),
              const SizedBox(height: 16),

              // ── Accuracy Ring ───────────────────────────────────────────
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: accuracy,
                      strokeWidth: 12,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(accuracy * 100).round()}%',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: gradeColor,
                        ),
                      ),
                      Text(
                        'Accuracy',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                gradeLabel,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                session?.title ?? 'Quiz Complete',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 28),

              // ── Stats Row ───────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatCard(
                    value: '$correct/$totalQ',
                    label: 'Correct',
                    icon: Icons.check_circle_rounded,
                    color: AppColors.correctGreen,
                  ),
                  _StatCard(
                    value: '+${quizState.totalXpEarned}',
                    label: 'XP Earned',
                    icon: Icons.bolt_rounded,
                    color: AppColors.xpGold,
                  ),
                  _StatCard(
                    value: '+${quizState.totalCoinsEarned}',
                    label: 'Coins',
                    icon: Icons.monetization_on_rounded,
                    color: AppColors.coinYellow,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Per-question breakdown ──────────────────────────────────
              if (quizState.answers.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Answer Review',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...quizState.session?.questions.mapIndexed(
                      (i, q) {
                        final result = quizState.answers[q.id];
                        return _ReviewTile(
                          index: i + 1,
                          questionBody: q.body,
                          isCorrect: result?.isCorrect,
                          skipped: result == null,
                        );
                      },
                    ) ??
                    [],
              ],

              const SizedBox(height: 24),

              // ── Share (server never mints locally — share is native sheet only) ──
              OutlinedButton.icon(
                onPressed: () => _shareResult(context, accuracy, correct, totalQ, quizState),
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Share Result'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── CTAs ─────────────────────────────────────────────────────
              FilledButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Back to Home'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  final id = quizState.attemptId;
                  if (id != null && !id.startsWith('offline-')) {
                    context.go('/quiz/attempt/$id/result/review');
                  } else {
                    context.go('/quiz');
                  }
                },
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Review All Answers'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.go('/quiz'),
                icon: const Icon(Icons.replay_rounded),
                label: const Text('More Practice'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.index,
    required this.questionBody,
    required this.isCorrect,
    required this.skipped,
  });

  final int index;
  final String questionBody;
  final bool? isCorrect;
  final bool skipped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color statusColor;
    IconData statusIcon;

    if (skipped) {
      statusColor = theme.colorScheme.onSurface.withValues(alpha: 0.3);
      statusIcon = Icons.remove_circle_outline_rounded;
    } else if (isCorrect == true) {
      statusColor = AppColors.correctGreen;
      statusIcon = Icons.check_circle_rounded;
    } else {
      statusColor = AppColors.wrongRed;
      statusIcon = Icons.cancel_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              questionBody.length > 100
                  ? '${questionBody.substring(0, 100)}…'
                  : questionBody,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(statusIcon, color: statusColor, size: 20),
        ],
      ),
    );
  }
}

Future<void> _shareResult(
  BuildContext context,
  double accuracy,
  int correct,
  int totalQ,
  QuizState quizState,
) async {
  final pct = (accuracy * 100).round();
  final title = quizState.session?.title ?? 'CivilCal Quiz';
  final grade = pct >= 80 ? 'Excellent' : pct >= 50 ? 'Good Job' : 'Keep Practicing';
  final msg = 'I scored $correct/$totalQ ($pct%) on "$title" — $grade! '
      'XP +${quizState.totalXpEarned} · Coins +${quizState.totalCoinsEarned} '
      'via CivilCal (BiSaaS). Try: https://bisaas.com';
  try {
    AppLogger.i('Share quiz result $pct% $title');
    await SharePlus.instance.share(ShareParams(text: msg, subject: 'My CivilCal Result — $title'));
  } catch (e) {
    AppLogger.w('Share failed: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share unavailable: $e')),
      );
    }
  }
}

extension _MapIndexed<T> on Iterable<T> {
  Iterable<R> mapIndexed<R>(R Function(int index, T item) f) sync* {
    var i = 0;
    for (final item in this) {
      yield f(i++, item);
    }
  }
}

/// Fires a one-shot confetti overlay on the first frame after the result
/// screen mounts. Respects the platform reduce-motion setting and only
/// celebrates server-graded completions (never offline practice). Renders
/// nothing itself.
class _ConfettiOnMount extends StatefulWidget {
  const _ConfettiOnMount({required this.celebrate, this.coinsEarned = 0});
  final bool celebrate;
  final int coinsEarned;

  @override
  State<_ConfettiOnMount> createState() => _ConfettiOnMountState();
}

class _ConfettiOnMountState extends State<_ConfettiOnMount> {
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeFire());
  }

  void _maybeFire() {
    if (_fired || !widget.celebrate || !mounted) return;
    _fired = true;
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return;
    unawaited(
      LottieOverlay.show(
        context,
        const LottieOverlay(
          asset: 'assets/animations/confetti.json',
          title: 'Quiz Complete!',
          autoDismiss: Duration(milliseconds: 2200),
        ),
      ),
    );
    if (widget.coinsEarned > 0) {
      final size = MediaQuery.sizeOf(context);
      final entry = CoinFloat.show(
        context,
        amount: widget.coinsEarned,
        from: Offset(size.width / 2, size.height * 0.4),
      );
      Future.delayed(const Duration(milliseconds: 1050), entry.remove);
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
