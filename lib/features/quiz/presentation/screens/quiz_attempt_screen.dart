import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/consent/consent_gate.dart';
import '../../../../core/security/sensitive_screen_guard.dart';
import '../../../../shared/widgets/ambient_glow_background.dart';
import '../../../../shared/widgets/chunky/chunky_button.dart';
import '../../../../shared/widgets/chunky/chunky_kit.dart';
import '../../../../shared/widgets/answer_feedback_lottie.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../domain/entities/question.dart';
import '../controllers/quiz_controller.dart';
import '../state/quiz_state.dart';
import '../widgets/difficulty_badge.dart';
import '../widgets/lifeline_bar.dart';
import '../widgets/question_answer_input.dart';
import '../widgets/question_image.dart';
import '../../../../l10n/app_localizations.dart';

/// Live quiz attempt screen — full session UI with timer, question body,
/// answer options, and server-graded feedback overlay.
class QuizAttemptScreen extends ConsumerStatefulWidget {
  const QuizAttemptScreen({
    required this.quizId,
    this.categoryId,
    this.attemptId,
    super.key,
  });
  final String quizId;
  final int? categoryId;

  /// When supplied, an interrupted server attempt is resumed via
  /// `GET /quiz/attempts/{attempt}` instead of starting a brand-new one.
  final String? attemptId;

  @override
  ConsumerState<QuizAttemptScreen> createState() => _QuizAttemptScreenState();
}

class _QuizAttemptScreenState extends ConsumerState<QuizAttemptScreen> {
  String? _lastAnimatedQuestionId;

  @override
  void initState() {
    super.initState();
    // Start session after frame — avoids setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizControllerProvider.notifier).startSession(
            widget.quizId,
            categoryId: widget.categoryId,
            attemptId: widget.attemptId,
          );
    });
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Spend a lifeline on the current question.
  ///
  /// The controller performs the server call and applies the server's effect.
  /// This only surfaces the outcome: an effect the client cannot render is
  /// reported as such instead of being silently dropped.
  Future<void> _useLifeline(String slug) async {
    final l10n = AppLocalizations.of(context)!;
    final effect = await ref.read(quizControllerProvider.notifier).useLifeline(slug);
    if (!mounted) return;
    if (effect != null && !effect.hasVisibleOutcome) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.quizAttemptUnsupportedEffect(slug)),
          backgroundColor: AppColors.warnAmber,
        ),
      );
    }
  }

  Color _timerColor(int remaining, int total) {
    if (total == 0) return AppColors.brand;
    final fraction = remaining / total;
    if (fraction > 0.4) return AppColors.brand;
    if (fraction > 0.15) return AppColors.streakOrange;
    return AppColors.wrongRed;
  }

  /// Fires the correct/wrong Lottie + XP float once per question when the
  /// server (or offline cache) returns a REAL graded result. Online exam-mode
  /// answers come back as synthetic "pending" (empty correctOptionId) because
  /// the server grades on complete — we deliberately do NOT animate those, so
  /// the client never fakes server-authoritative feedback.
  void _maybeCelebrate(QuizState? prev, QuizState next) {
    if (next.phase != QuizPhase.feedback) return;
    final result = next.lastResult;
    if (result == null) return;
    if (result.correctOptionId.isEmpty) return; // synthetic/pending → skip
    if (_lastAnimatedQuestionId == result.questionId) return; // once per question
    _lastAnimatedQuestionId = result.questionId;

    final overlay = AnswerFeedbackLottie.show(context, isCorrect: result.isCorrect);
    Future.delayed(const Duration(milliseconds: 700), overlay.remove);
    if (result.xpEarned > 0) {
      final xp = XpFloat.show(context, amount: result.xpEarned,
          from: Offset(MediaQuery.sizeOf(context).width / 2, MediaQuery.sizeOf(context).height * 0.55));
      Future.delayed(const Duration(milliseconds: 950), xp.remove);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizControllerProvider);

    // Navigate to results when finished (via go_router so deep links and
    // the browser back button work correctly — never Navigator.pushReplacement).
    ref.listen(quizControllerProvider, (prev, next) {
      if (next.phase == QuizPhase.finished && mounted) {
        final attemptId = next.attemptId ?? widget.quizId;
        if (context.mounted) {
          context.go('/quiz/attempt/$attemptId/result');
        }
      }
      _maybeCelebrate(prev, next);
    });

    final body = AmbientGlowBackground(
      child: SafeArea(
        child: switch (state.phase) {
          QuizPhase.loading => const Center(child: CircularProgressIndicator()),
          QuizPhase.error => _buildError(context, state),
          QuizPhase.finished => const Center(child: CircularProgressIndicator()),
          _ => _buildQuizBody(context, state),
        },
      ),
    );

    // FLAG_SECURE on official online attempts only (security plan W2.7):
    // offline practice stays screenshot-friendly, graded official runs do not.
    return Scaffold(
      body: state.isOfflinePractice
          ? body
          : SensitiveScreenGuard.guard(child: body),
    );
  }

  Widget _buildError(BuildContext context, QuizState state) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.wrongRed),
            const SizedBox(height: 16),
            Text(
              l10n.quizAttemptLoadError,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              state.errorMessage ?? l10n.errRequestFailed,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            // A completion failure is a retry of the SAME attempt. Starting a
            // new session here would orphan the attempt the user just worked
            // through (and any coins/XP already earned on it).
            FilledButton(
              onPressed: () {
                final notifier = ref.read(quizControllerProvider.notifier);
                if (notifier.hasFailedCompletion) {
                  unawaited(notifier.retryCompletion());
                } else {
                  unawaited(notifier.startSession(
                    widget.quizId,
                    categoryId: widget.categoryId,
                    attemptId: widget.attemptId,
                  ));
                }
              },
              child: Text(l10n.retry),
            ),
            TextButton(
              onPressed: () => context.pop(),
              child: Text(l10n.commonGoBack),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizBody(BuildContext context, QuizState state) {
    final l10n = AppLocalizations.of(context)!;
    final hintView = ref.watch(quizHintViewProvider);
    final theme = Theme.of(context);
    final session = state.session!;
    final question = state.currentQuestion!;
    final remaining = state.remainingSeconds;
    final total = session.durationSeconds;
    final timerColor = _timerColor(remaining, total);
    final progress = (state.currentIndex + 1) / session.totalQuestions;
    final retryOption =
        state.errorMessage != null ? state.selectedOptionId : null;
    // Feedback colours come from the server verdict only. A pending verdict
    // (empty correctOptionId, because grading happens on complete) paints no
    // right/wrong on any renderer.
    final lastResult = state.lastResult;
    final correctKeys = lastResult == null || lastResult.correctOptionId.isEmpty
        ? const <String>{}
        : lastResult.correctOptionId
            .split(',')
            .map((key) => key.trim())
            .where((key) => key.isNotEmpty)
            .toSet();
    final isWrongAnswer = state.phase == QuizPhase.feedback &&
        lastResult != null &&
        lastResult.correctOptionId.isNotEmpty &&
        !lastResult.isCorrect;

    return Column(
      children: [
        if (retryOption != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(color: AppColors.wrongRed),
                  ),
                ),
                TextButton(
                  onPressed: () => ref
                      .read(quizControllerProvider.notifier)
                      .selectAnswer(retryOption),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        // ── Top bar ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: l10n.commonExit,
                onPressed: () => _showExitDialog(context),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${state.currentIndex + 1} / ${session.totalQuestions}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ChunkyProgressBar(value: progress),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Timer pill
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: timerColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: timerColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_rounded, size: 14, color: timerColor),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(remaining),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: timerColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // XP + Combo HUD
              const SizedBox(width: 8),
              if (state.comboCount > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.comboFire.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '🔥 ×${state.comboCount}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.comboFire,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),

        if (state.isOfflinePractice)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.streakOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.streakOrange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_off_rounded, size: 14, color: AppColors.streakOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.quizAttemptOfflineNotice,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.streakOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // ── Question body ─────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Subject + difficulty chips
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.brand.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        question.subjectSlug.toUpperCase().replaceAll('-', ' '),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.brand,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DifficultyBadge(difficulty: question.difficulty, compact: true),
                  ],
                ),
                const SizedBox(height: 14),
                // Image-based questions render their own allow-listed figure
                // beside their answer control. Other families may still carry
                // a past-paper crop in metadata, so show it here for them.
                if (question.inputKind != QuizQuestionType.imageBased)
                  QuestionImage(
                    imageUrl: question.imageUrl,
                    heroTag: 'q-${question.id}',
                  ),
                Text(
                  question.body,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.6,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                if (state.hasLifelines && state.phase == QuizPhase.answering)
                  LifelineBar(
                    lifelines: state.lifelines,
                    walletBalance: state.lifelineWalletBalance,
                    enabled: state.lifelinesEnabled,
                    busySlug: state.busyLifelineSlug,
                    onUse: (lifeline) => _useLifeline(lifeline.slug),
                  ),
                if (state.lifelineNotice != null) ...[
                  const SizedBox(height: 10),
                  _LifelineNotice(text: state.lifelineNotice!),
                ],
                if (state.phase == QuizPhase.answering) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: hintView.busy
                            ? null
                            : () => ref
                                .read(quizControllerProvider.notifier)
                                .loadHint(),
                        icon: const Icon(Icons.lightbulb_outline_rounded, size: 16),
                        label: Text(l10n.quizAttemptHint),
                      ),
                      if (hintView.busy) ...[
                        const SizedBox(width: 10),
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ],
                  ),
                  if (hintView.error != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            hintView.error!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.wrongRed,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => ref
                              .read(quizControllerProvider.notifier)
                              .loadHint(),
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  ] else if (hintView.hint != null) ...[
                    const SizedBox(height: 8),
                    _LifelineNotice(text: hintView.hint!),
                  ],
                ],
                const SizedBox(height: 8),

                // ── Answer control (type-driven) ──────────────────────────
                // The server owns the question family; the client picks only
                // a renderer. Unknown families fail loudly with a localised
                // error and retry — never a fabricated MCQ.
                QuestionAnswerInput(
                  key: ValueKey('answer-${question.id}'),
                  question: question,
                  value: state.selectedOptionId ?? '',
                  enabled: state.phase == QuizPhase.answering,
                  // Lifeline-suppressed options return once the verdict lands,
                  // exactly as the pre-type-aware screen did.
                  hiddenKeys: state.phase == QuizPhase.answering
                      ? state.hiddenOptionKeys
                      : const <String>{},
                  correctKeys: correctKeys,
                  isWrong: isWrongAnswer,
                  onSubmit: (value) => ref
                      .read(quizControllerProvider.notifier)
                      .selectAnswer(value),
                  onRetry: () {
                    final attemptId = widget.attemptId;
                    ref.read(quizControllerProvider.notifier).startSession(
                          widget.quizId,
                          // An offline practice id cannot be resumed from the
                          // server; re-read the cached session instead.
                          attemptId: (attemptId == null ||
                                  attemptId.startsWith('offline-'))
                              ? null
                              : attemptId,
                        );
                  },
                ),

                // ── Feedback panel ────────────────────────────────────────
                if (state.phase == QuizPhase.feedback && state.lastResult != null) ...[
                  const SizedBox(height: 8),
                  _buildFeedbackPanel(context, state),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),

        // ── Bottom CTA ────────────────────────────────────────────────────
        if (state.phase == QuizPhase.feedback)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: ChunkyButton(
              label: state.isLastQuestion ? l10n.quizSeeResults : l10n.quizNextQuestion,
              onPressed: () =>
                  ref.read(quizControllerProvider.notifier).nextQuestion(),
            ),
          ),
      ],
    );
  }

  Widget _buildFeedbackPanel(BuildContext context, QuizState state) {

    final l10n = AppLocalizations.of(context)!;    final result = state.lastResult!;
    final theme = Theme.of(context);
    // The API withholds grading until complete/results — an empty
    // correctOptionId means "saved, verdict pending", never "wrong".
    final isPending = result.correctOptionId.isEmpty;
    final isCorrect = !isPending && result.isCorrect;
    final verdictColor =
        isPending ? AppColors.brandShadow : (isCorrect ? AppColors.brandShadow : AppColors.errorShadow);

    return GlassmorphicCard(
      padding: const EdgeInsets.all(16),
      color: isPending
          ? AppColors.selectedBlueBg
          : (isCorrect ? AppColors.correctGreenBg : AppColors.wrongRedBg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPending ? Icons.check_circle_rounded : (isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded),
                color: verdictColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                isPending
                    ? l10n.quizAnswerSubmitted
                    : (isCorrect ? l10n.quizFeedbackGreatJob : l10n.quizFeedbackNotQuite),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: verdictColor,
                  fontSize: 17,
                ),
              ),
              const Spacer(),
              if (result.xpEarned > 0) ...[
                const Icon(Icons.bolt_rounded, size: 16, color: AppColors.goldShadow),
                Text(
                  l10n.commonXpGained(result.xpEarned),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.goldShadow,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (state.comboCount > 1) ...[
                const Icon(Icons.local_fire_department_rounded,
                    size: 16, color: AppColors.warningShadow),
                Text(
                  l10n.quizAttemptCombo(state.comboCount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.warningShadow,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
          if (result.explanation != null && result.explanation!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              result.explanation!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showExitDialog(BuildContext context) async {

      final l10n = AppLocalizations.of(context)!;    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.quizAttemptExitTitle),
        content: Text(
          l10n.quizAttemptExitBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonStay),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.commonExit),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      // Only an explicit confirmation is an abandon — closing the dialog with
      // "Stay" must not count, and a timeout is not a user action.
      final notifier = ref.read(quizControllerProvider.notifier);
      // Standard attempts are abandoned server-side just like arcade runs, so
      // an interrupted attempt does not linger in progress forever. The write
      // is best effort: the user has already confirmed the exit.
      await notifier.abandonSession();
      if (!mounted) return;
      unawaited(ref.read(analyticsProvider).log(
        AnalyticsEvents.quizAbandon,
        params: {'quiz_id': widget.quizId},
      ));
      context.pop();
    }
  }
}

/// Renders the text of a server-built lifeline effect (hint, explanation, poll,
/// shield, extra time …). The wording comes from `LifelineEffectService`; this
/// widget only displays it.
class _LifelineNotice extends StatelessWidget {
  const _LifelineNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lifelineCyan.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lifelineCyan.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.lifelineCyan),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
