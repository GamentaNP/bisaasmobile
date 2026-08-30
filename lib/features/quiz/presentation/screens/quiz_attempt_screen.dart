import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../controllers/quiz_controller.dart';
import '../state/quiz_state.dart';
import 'quiz_result_screen.dart';

/// Live quiz attempt screen — full session UI with timer, question body,
/// answer options, and server-graded feedback overlay.
class QuizAttemptScreen extends ConsumerStatefulWidget {
  const QuizAttemptScreen({required this.quizId, super.key});
  final String quizId;

  @override
  ConsumerState<QuizAttemptScreen> createState() => _QuizAttemptScreenState();
}

class _QuizAttemptScreenState extends ConsumerState<QuizAttemptScreen> {
  @override
  void initState() {
    super.initState();
    // Start session after frame — avoids setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizControllerProvider.notifier).startSession(widget.quizId);
    });
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color _timerColor(int remaining, int total) {
    if (total == 0) return AppColors.brand;
    final fraction = remaining / total;
    if (fraction > 0.4) return AppColors.brand;
    if (fraction > 0.15) return AppColors.streakOrange;
    return AppColors.wrongRed;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizControllerProvider);

    // Navigate to results when finished
    ref.listen(quizControllerProvider, (prev, next) {
      if (next.phase == QuizPhase.finished && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => QuizResultScreen(quizState: next),
          ),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: switch (state.phase) {
          QuizPhase.loading => const Center(child: CircularProgressIndicator()),
          QuizPhase.error => _buildError(context, state),
          QuizPhase.finished => const Center(child: CircularProgressIndicator()),
          _ => _buildQuizBody(context, state),
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, QuizState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.wrongRed),
            const SizedBox(height: 16),
            Text(
              'Could not load quiz',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              state.errorMessage ?? 'Network error',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () =>
                  ref.read(quizControllerProvider.notifier).startSession(widget.quizId),
              child: const Text('Retry'),
            ),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizBody(BuildContext context, QuizState state) {
    final theme = Theme.of(context);
    final session = state.session!;
    final question = state.currentQuestion!;
    final remaining = state.remainingSeconds;
    final total = session.durationSeconds;
    final timerColor = _timerColor(remaining, total);
    final progress = (state.currentIndex + 1) / session.totalQuestions;

    return Column(
      children: [
        // ── Top bar ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded),
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        color: AppColors.brand,
                        minHeight: 6,
                      ),
                    ),
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
                    'Offline practice — not official. XP/coins will reconcile when back online.',
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
                // Subject chip
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
                const SizedBox(height: 14),
                Text(
                  question.body,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.6,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Answer options ────────────────────────────────────────
                ...question.options.map((option) {
                  final isSelected = state.selectedOptionId == option.id;
                  final result = state.lastResult;
                  final inFeedback = state.phase == QuizPhase.feedback;
                  final isGrading = state.phase == QuizPhase.grading;

                  Color? borderColor;
                  Color? bgColor;
                  IconData? trailingIcon;

                  if (inFeedback && result != null) {
                    final isCorrectOption = option.id == result.correctOptionId;
                    if (isCorrectOption) {
                      borderColor = AppColors.correctGreen;
                      bgColor = AppColors.correctGreen.withValues(alpha: 0.1);
                      trailingIcon = Icons.check_circle_rounded;
                    } else if (isSelected && !result.isCorrect) {
                      borderColor = AppColors.wrongRed;
                      bgColor = AppColors.wrongRed.withValues(alpha: 0.1);
                      trailingIcon = Icons.cancel_rounded;
                    }
                  } else if (isGrading && isSelected) {
                    borderColor = AppColors.brand;
                    bgColor = AppColors.brand.withValues(alpha: 0.08);
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: state.phase == QuizPhase.answering
                          ? () => ref
                              .read(quizControllerProvider.notifier)
                              .selectAnswer(option.id)
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgColor ?? theme.colorScheme.surface,
                          border: Border.all(
                            color: borderColor ??
                                theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                            width: borderColor != null ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Text(
                              String.fromCharCode(65 + question.options.indexOf(option)),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: borderColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                option.text,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (trailingIcon != null)
                              Icon(trailingIcon, color: borderColor, size: 22),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

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
            child: FilledButton(
              onPressed: () =>
                  ref.read(quizControllerProvider.notifier).nextQuestion(),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                state.isLastQuestion ? 'See Results' : 'Next Question',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFeedbackPanel(BuildContext context, QuizState state) {
    final result = state.lastResult!;
    final theme = Theme.of(context);
    final isCorrect = result.isCorrect;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppColors.correctGreen.withValues(alpha: 0.1)
            : AppColors.wrongRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCorrect
              ? AppColors.correctGreen.withValues(alpha: 0.4)
              : AppColors.wrongRed.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isCorrect ? AppColors.correctGreen : AppColors.wrongRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Correct!' : 'Incorrect',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? AppColors.correctGreen : AppColors.wrongRed,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              if (result.xpEarned > 0) ...[
                const Icon(Icons.bolt_rounded, size: 14, color: AppColors.xpGold),
                Text(
                  '+${result.xpEarned} XP',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.xpGold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (state.comboCount > 1) ...[
                const Icon(Icons.local_fire_department_rounded,
                    size: 14, color: AppColors.comboFire),
                Text(
                  '×${state.comboCount} Combo!',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.comboFire,
                    fontSize: 12,
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showExitDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Quiz?'),
        content: const Text(
          'Your current progress will be lost. Are you sure you want to exit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.pop();
    }
  }
}
