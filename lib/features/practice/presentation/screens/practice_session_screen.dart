import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/practice.dart';
import '../controllers/practice_controller.dart';
import '../practice_session_args.dart';
import '../../../../l10n/app_localizations.dart';

/// Untimed practice drill, backed by a live server attempt.
///
/// Per spec 4.6: no coin cost, no leaderboard effect, no streak risk. The
/// server decides that, not the client — the client only asks for a
/// `mode: 'practice'` attempt and shows what the server returns.
///
/// **No invented content, and no invented grading.** The previous version of
/// this screen rendered a literal `['A','B','C','D']` option list labelled
/// "Option X — tap to select", and decided correctness with
/// `_current.id.isEven && opt.hashCode.isEven` — i.e. it showed fake questions
/// and reported a made-up score.
///
/// The screen now submits every answer to the attempt and completes it, so the
/// score in the result dialog is the **server's** score
/// (`PUT /quiz/attempts/{attempt}/completion`). The server withholds answer
/// keys until an attempt is graded (`QuizQuestionResource` exposure policy),
/// so during the drill the only honest thing to show is "submitted" — never
/// right/wrong.
class PracticeSessionScreen extends ConsumerStatefulWidget {
  const PracticeSessionScreen({super.key, required this.args});
  final PracticeSessionArgs args;

  @override
  ConsumerState<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends ConsumerState<PracticeSessionScreen> {
  int _index = 0;
  int _answered = 0;
  int _skipped = 0;

  /// index → selected option key. Absence means "not answered / skipped".
  final Map<int, String> _answers = {};

  /// When the question was first shown — the timing evidence the server's
  /// integrity engine consumes.
  final Map<int, DateTime> _shownAt = {};

  bool _submitting = false;
  bool _completing = false;

  PracticeQuestion get _current => widget.args.questions[_index];
  bool get _isLast => _index >= widget.args.questions.length - 1;
  String? get _selected => _answers[_index];

  @override
  void initState() {
    super.initState();
    _shownAt[0] = DateTime.now();
  }

  Future<void> _select(String optionKey) async {
    if (_answers.containsKey(_index)) return; // already answered
    setState(() {
      _answers[_index] = optionKey;
      _answered++;
    });
    await _submitCurrent();
  }

  Future<void> _skip() async {
    if (_answers.containsKey(_index)) return;
    setState(() {
      _answers[_index] = '__skip__';
      _skipped++;
    });
    _next();
  }

  /// Sends the answer for the current question to the server.
  ///
  /// The attempt id is empty for a review-only drill (a bookmark tap with no
  /// live attempt), in which case there is nothing to submit.
  Future<void> _submitCurrent() async {
    final attemptId = widget.args.attemptId;
    final answer = _answers[_index];
    if (attemptId.isEmpty || answer == null || answer == '__skip__') return;

    setState(() => _submitting = true);
    final startedAt = _shownAt[_index] ?? DateTime.now();
    final elapsed = DateTime.now().difference(startedAt).inSeconds;
    await ref.read(practiceControllerProvider.notifier).submitAnswer(
          attemptId: attemptId,
          questionId: _current.id,
          answer: answer,
          timeTakenSeconds: elapsed.clamp(0, 86400),
        );
    if (mounted) setState(() => _submitting = false);
  }

  void _next() {
    if (_isLast) {
      _showResult();
      return;
    }
    setState(() {
      _index++;
      _shownAt[_index] = DateTime.now();
    });
  }

  void _prev() {
    if (_index == 0) return;
    setState(() => _index--);
  }

  Future<void> _showResult() async {
    final l10n = AppLocalizations.of(context)!;
    final attemptId = widget.args.attemptId;
    PracticeResult? result;

    if (attemptId.isNotEmpty) {
      setState(() => _completing = true);
      result = await ref.read(practiceControllerProvider.notifier).completeAttempt(attemptId);
      if (mounted) setState(() => _completing = false);
    }

    if (!mounted) return;

    final completionError = result == null && attemptId.isNotEmpty
        ? ref.read(practiceControllerProvider).startError
        : null;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: Text(l10n.practiceDrillComplete),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [Icon(Icons.info_outline_rounded, size: 16, color: AppColors.brand), SizedBox(width: 8), Expanded(child: Text(l10n.practiceDoesNotAffect, style: TextStyle(fontSize: 12, color: AppColors.brand)))]),
            ),
            const SizedBox(height: 12),
            Text(l10n.practiceQuestionsCount(widget.args.questions.length), style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text(l10n.practiceAnsweredSkipped(_answered, _skipped), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (result != null) ...[
              const SizedBox(height: 12),
              // The score comes from the server's completion payload. The client
              // never grades.
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.correctGreen.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.correctGreen.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.score != null ? l10n.practiceScore(result.score!) : l10n.practiceGradedByServer,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.correctGreen),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.practiceCorrectWrongSkipped(result.correctCount, result.wrongCount, result.skippedCount),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ] else if (completionError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.wrongRed.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.wrongRed.withValues(alpha: 0.25)),
                ),
                child: Text(
                  l10n.practiceGradingFailed(completionError),
                  style: const TextStyle(fontSize: 12, color: AppColors.wrongRed),
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                l10n.practiceReviewPassNote,
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(), child: Text(l10n.onboardingContinue)),
          FilledButton(onPressed: () { Navigator.of(c).pop(); Navigator.of(context).pop(); }, child: Text(l10n.tutorDone)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final qs = widget.args.questions;
    if (qs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.args.title)),
        body: Center(child: Text(l10n.practiceNoQuestionsInSet)),
      );
    }

    final progress = (_index + 1) / qs.length;
    final answered = _selected != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.args.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: progress, minHeight: 4, backgroundColor: theme.colorScheme.surfaceContainerHighest, color: AppColors.brand),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.brand.withValues(alpha: 0.06),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.brand.withValues(alpha: 0.2))),
                  child: Text(l10n.practiceQuestionCounter(_index + 1, qs.length), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.brand)),
                ),
                const SizedBox(width: 8),
                Text(l10n.practiceAnsweredSkipped(_answered, _skipped), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.xpGold.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(l10n.practiceUntimedPractice, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.xpGold)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.help_outline_rounded, size: 16, color: AppColors.brand)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(l10n.practiceQuestionNumber(_current.id), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey))),
                          if (_current.type != null) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)), child: Text(_current.type!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _current.questionText.isEmpty
                            // An empty body is a server gap, not an invitation
                            // to render placeholder prose.
                            ? l10n.quizNoQuestionText
                            : _current.questionText,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, height: 1.4),
                      ),
                      if (_current.difficulty != null) ...[
                        const SizedBox(height: 6),
                        Text(l10n.practiceDifficultyLabel(_current.difficulty ?? '—'), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_current.hasOptions)
                  ..._current.options.map(
                    (option) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: answered ? null : () => _select(option.key),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _selected == option.key
                                ? AppColors.brand.withValues(alpha: 0.08)
                                : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selected == option.key ? AppColors.brand : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                              width: _selected == option.key ? 1.5 : 1,
                            ),
                          ),
                          child: Row(children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(color: _selected == option.key ? AppColors.brand : theme.colorScheme.surfaceContainerHighest, shape: BoxShape.circle),
                              child: Center(child: Text(option.key, style: TextStyle(fontWeight: FontWeight.bold, color: _selected == option.key ? Colors.white : theme.colorScheme.onSurface))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(option.text, style: const TextStyle(fontSize: 13))),
                            if (_selected == option.key) const Icon(Icons.check_circle_rounded, color: AppColors.brand, size: 18),
                          ]),
                        ),
                      ),
                    ),
                  )
                else
                  // Honest about the gap instead of inventing four choices.
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warnAmberBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warnAmber.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.report_gmailerrorred_rounded, size: 18, color: AppColors.warningShadow),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.practiceNoOptionsNotice,
                            style: TextStyle(fontSize: 12, color: AppColors.warningShadow),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (answered) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.lifelineCyan.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.lifelineCyan.withValues(alpha: 0.25))),
                    child: Row(children: [
                      if (_submitting)
                        const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      else
                        const Icon(Icons.schedule_rounded, size: 16, color: AppColors.lifelineCyan),
                      const SizedBox(width: 8),
                      Expanded(child: Text(l10n.practiceAnswerSentNotice, style: TextStyle(fontSize: 11, color: AppColors.lifelineCyan))),
                    ]),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    OutlinedButton.icon(onPressed: _index == 0 ? null : _prev, icon: const Icon(Icons.arrow_back_rounded, size: 16), label: Text(l10n.practicePrev)),
                    const Spacer(),
                    TextButton.icon(onPressed: answered ? null : _skip, icon: const Icon(Icons.skip_next_rounded, size: 16), label: Text(l10n.commonSkip)),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _completing ? null : _next,
                      icon: Icon(_isLast ? Icons.flag_rounded : Icons.arrow_forward_rounded, size: 16),
                      label: Text(_completing ? l10n.practiceGrading : (_isLast ? 'Finish' : 'Next')),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.practiceNoEffectNote,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
