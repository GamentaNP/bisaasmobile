import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/practice.dart';
import 'practice_browser_screen.dart';

/// Untimed practice drill.
///
/// Per spec 4.6: no coin cost, no leaderboard effect, no streak risk.
///
/// **No invented content, and no invented grading.** The previous version of
/// this screen rendered a literal `['A','B','C','D']` option list labelled
/// "Option X — tap to select", and decided correctness with
/// `_current.id.isEven && opt.hashCode.isEven` — i.e. it showed fake questions
/// and reported a made-up score.
///
/// The server withholds answer keys until an attempt is graded
/// (`QuizQuestionResource` exposure policy), so this drill genuinely *cannot*
/// know whether an answer was right. It therefore records selections and says
/// exactly that, instead of asserting a verdict the client has no basis for.
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

  PracticeQuestion get _current => widget.args.questions[_index];
  bool get _isLast => _index >= widget.args.questions.length - 1;
  String? get _selected => _answers[_index];

  void _select(String optionKey) {
    setState(() {
      if (_answers.containsKey(_index)) return; // already answered
      _answers[_index] = optionKey;
      _answered++;
    });
  }

  void _skip() {
    setState(() {
      if (_answers.containsKey(_index)) return;
      _answers[_index] = '__skip__';
      _skipped++;
    });
    _next();
  }

  void _next() {
    if (_isLast) {
      _showResult();
      return;
    }
    setState(() => _index++);
  }

  void _prev() {
    if (_index == 0) return;
    setState(() => _index--);
  }

  void _showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text('Drill complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: const Row(children: [Icon(Icons.info_outline_rounded, size: 16, color: AppColors.brand), SizedBox(width: 8), Expanded(child: Text('Practice — does not affect rank, XP or streak', style: TextStyle(fontSize: 12, color: AppColors.brand)))]),
            ),
            const SizedBox(height: 12),
            Text('${widget.args.questions.length} questions', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text('$_answered answered • $_skipped skipped', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            const Text(
              'No score is shown because the server grades answers and does not '
              'publish answer keys to the client. Run this as a graded quiz from '
              'the Quiz tab to see a real result.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Continue')),
          FilledButton(onPressed: () { Navigator.of(c).pop(); Navigator.of(context).pop(); }, child: const Text('Done')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qs = widget.args.questions;
    if (qs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.args.title)),
        body: const Center(child: Text('No questions in this set')),
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
                  child: Text('Q ${_index + 1}/${qs.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.brand)),
                ),
                const SizedBox(width: 8),
                Text('$_answered answered • $_skipped skipped', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.xpGold.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Untimed • Practice', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.xpGold)),
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
                          Expanded(child: Text('Question #${_current.id}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey))),
                          if (_current.type != null) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)), child: Text(_current.type!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _current.questionText.isEmpty
                            // An empty body is a server gap, not an invitation
                            // to render placeholder prose.
                            ? 'This question has no text on the server.'
                            : _current.questionText,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, height: 1.4),
                      ),
                      if (_current.difficulty != null) ...[
                        const SizedBox(height: 6),
                        Text('Difficulty: ${_current.difficulty}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.report_gmailerrorred_rounded, size: 18, color: AppColors.warningShadow),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'The server sent this question without answer options, so '
                            'it cannot be drilled here. Try the graded Quiz tab, which '
                            'loads a full session.',
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
                    child: const Row(children: [Icon(Icons.schedule_rounded, size: 16, color: AppColors.lifelineCyan), SizedBox(width: 8), Expanded(child: Text('Answer recorded. The server grades it — this drill does not and will not guess a score.', style: TextStyle(fontSize: 11, color: AppColors.lifelineCyan)))]),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    OutlinedButton.icon(onPressed: _index == 0 ? null : _prev, icon: const Icon(Icons.arrow_back_rounded, size: 16), label: const Text('Prev')),
                    const Spacer(),
                    TextButton.icon(onPressed: answered ? null : _skip, icon: const Icon(Icons.skip_next_rounded, size: 16), label: const Text('Skip')),
                    const SizedBox(width: 8),
                    FilledButton.icon(onPressed: _next, icon: Icon(_isLast ? Icons.flag_rounded : Icons.arrow_forward_rounded, size: 16), label: Text(_isLast ? 'Finish' : 'Next')),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Practice is untimed and carries no score, XP, coins or streak effect.',
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
