import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/safe_area_scaffold.dart';
import '../../../gamification/presentation/widgets/answer_feedback_lottie.dart';
import '../../../gamification/presentation/widgets/lottie_overlay.dart';
import '../state/quiz_state.dart';
import '../../../../l10n/app_localizations.dart';

/// Results screen shown after quiz completion — summarizes server-authoritative
/// totals (XP, coins, accuracy, streak).
class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({required this.quizState, super.key});
  final QuizState quizState;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final session = quizState.session;
    final answered = quizState.answers.length;
    final localCorrect =
        quizState.answers.values.where((r) => r.isCorrect).length;
    final serverResult = quizState.quizResult;
    final correct = serverResult?.correctAnswers ?? localCorrect;
    final accuracy = serverResult?.accuracy ??
        (answered > 0 ? localCorrect / answered : 0.0);
    final totalQ = serverResult?.totalQuestions ?? session?.totalQuestions ?? answered;
    final xpEarned = serverResult?.totalXpEarned ?? quizState.totalXpEarned;
    final coinsEarned = serverResult?.totalCoinsEarned ?? quizState.totalCoinsEarned;

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

    return SafeAreaScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Celebratory confetti on first frame (server-graded only).
            _ConfettiOnMount(
              celebrate: !quizState.isOfflinePractice,
              coinsEarned: coinsEarned,
            ),
            const SizedBox(height: 8),

            // ── Duolongo hero: gradient slab + trophy ───────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                gradient: accuracy >= 0.8
                    ? AppColors.brandGradient
                    : AppColors.infoGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  bottom: BorderSide(
                    color: accuracy >= 0.8
                        ? AppColors.brandShadow
                        : AppColors.blueShadow,
                    width: 4,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      accuracy >= 0.8 ? Icons.emoji_events : Icons.military_tech,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    gradeLabel,
                    style: AppTypography.headlineMedium
                        .copyWith(color: Colors.white, fontSize: 34),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session?.title ?? 'Quiz Complete',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

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
                      l10n.quizResultAccuracy,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.quizResultCorrectOf(correct, totalQ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textTertiaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 28),

            // ── Stats Row ───────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatCard(
                  value: '$correct/$totalQ',
                  label: l10n.quizResultCorrect,
                  icon: Icons.check_circle_rounded,
                  color: AppColors.correctGreen,
                ),
                _StatCard(
                  value: '+$xpEarned',
                  label: l10n.quizResultXpEarned,
                  icon: Icons.bolt_rounded,
                  color: AppColors.xpGold,
                ),
                _StatCard(
                  value: '+$coinsEarned',
                  label: l10n.quizResultCoins,
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
                  l10n.quizResultAnswerReview,
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
              onPressed: () => _shareResult(context, accuracy, correct, totalQ, quizState, xpEarned: xpEarned, coinsEarned: coinsEarned),
              icon: const Icon(Icons.share_rounded, size: 18),
              label: Text(l10n.commonShareResult),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.mdAll,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── CTAs ─────────────────────────────────────────────────────
            GradientButton(
              label: l10n.quizResultBackToHome,
              icon: Icons.home_rounded,
              onPressed: () => context.go('/home'),
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
              label: Text(l10n.quizResultReviewAll),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.mdAll,
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go('/quiz'),
              icon: const Icon(Icons.replay_rounded),
              label: Text(l10n.quizResultMorePractice),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.mdAll,
                ),
              ),
            ),
          ],
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
    return GlassmorphicCard(
      padding: const EdgeInsets.all(16),
      color: color.withValues(alpha: 0.08),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiaryLight,
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
  QuizState quizState, {
  required int xpEarned,
  required int coinsEarned,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final pct = (accuracy * 100).round();
  final title = quizState.session?.title ?? 'CivilCal Quiz';
  final grade = pct >= 80 ? 'Excellent' : pct >= 50 ? 'Good Job' : 'Keep Practicing';
  final clientCopy = 'I scored $correct/$totalQ ($pct%) on "$title" — $grade! '
      'XP +$xpEarned · Coins +$coinsEarned '
      'via CivilCal (BiSaaS). Try: https://bisaas.com';

  // Prefer the server's own copy. The share line makes a claim about what
  // the user achieved, and the server is the only party that has reviewed
  // the wording — the client's fallback is used only when the server
  // publishes no proof.
  var msg = clientCopy;
  // The proof endpoint takes a numeric subject id.
  final courseId = int.tryParse(quizState.session?.id ?? '');
  if (courseId != null) {
    try {
      // The screen is a plain StatelessWidget, so the container is read from
      // the context rather than through a WidgetRef.
      final container = ProviderScope.containerOf(context, listen: false);
      final proof = await container.read(
        socialProofProvider((subject: 'course', id: courseId)).future,
      );
      final serverCopy = proof?.shareText;
      if (serverCopy != null && serverCopy.trim().isNotEmpty) {
        msg = serverCopy;
      }
    } catch (e) {
      // The proof is an enhancement, not a precondition for sharing.
      AppLogger.w('Share proof unavailable: $e');
    }
  }

  try {
    AppLogger.i('Share quiz result $pct% $title');
    await SharePlus.instance.share(ShareParams(text: msg, subject: 'My CivilCal Result — $title'));
  } catch (e) {
    AppLogger.w('Share failed: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.quizResultShareFailed(e))),
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
    final l10n = AppLocalizations.of(context)!;
    if (_fired || !widget.celebrate || !mounted) return;
    _fired = true;
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return;
    unawaited(
      LottieOverlay.show(
        context,
        LottieOverlay(
          asset: 'assets/animations/confetti.json',
          title: l10n.quizResultTitle,
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
