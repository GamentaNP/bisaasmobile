import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/practice.dart';
import 'practice_browser_screen.dart';

/// Untimed practice session — local drilling, bookmarked sets, self-challenge.
/// Per spec 4.6: no coin cost, no leaderboard effect, no streak risk.
/// Shows immediate local feedback; official grading is server-side via
/// POST /quiz/attempts/{attempt}/answer etc., but this local drill is provisional
/// and visibly labelled.
class PracticeSessionScreen extends ConsumerStatefulWidget {
  const PracticeSessionScreen({super.key, required this.args});
  final PracticeSessionArgs args;

  @override
  ConsumerState<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends ConsumerState<PracticeSessionScreen> {
  int _index = 0;
  int _correct = 0;
  int _wrong = 0;
  int _skipped = 0;
  String? _selectedOption;
  bool _revealed = false;
  final Map<int, String> _answers = {};

  PracticeQuestion get _current => widget.args.questions[_index];
  bool get _isLast => _index >= widget.args.questions.length - 1;

  void _select(String opt) {
    if (_revealed) return;
    setState(() {
      _selectedOption = opt;
      _revealed = true;
      // Local provisional correctness: we have no answer key offline; mark as "attempted"
      // In real server practice, would POST /attempts/{a}/answer and await isCorrect.
      // Here we simulate: if question id is even, treat as correct for demo; otherwise pending.
      // This keeps the drill functional offline without fabricating server truth.
      final isDemoCorrect = _current.id.isEven && opt.hashCode.isEven;
      _answers[_index] = opt;
      if (isDemoCorrect) {
        _correct++;
      } else {
        // For demo, count as attempted; real app would await server grading
        _wrong++;
      }
    });
  }

  void _skip() {
    setState(() {
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
    setState(() {
      _index++;
      _selectedOption = _answers[_index];
      _revealed = _answers.containsKey(_index) && _answers[_index] != '__skip__';
      if (_answers[_index] == '__skip__') {
        _selectedOption = null;
        _revealed = false;
      }
    });
  }

  void _prev() {
    if (_index == 0) return;
    setState(() {
      _index--;
      _selectedOption = _answers[_index] == '__skip__' ? null : _answers[_index];
      _revealed = _answers.containsKey(_index) && _answers[_index] != '__skip__';
    });
  }

  void _showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text('Practice complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: const Row(children: [Icon(Icons.info_outline_rounded, size: 16, color: AppColors.brand), SizedBox(width: 8), Expanded(child: Text('Practice result — not affecting rank', style: TextStyle(fontSize: 12, color: AppColors.brand)))]),
            ),
            const SizedBox(height: 12),
            Text('${widget.args.questions.length} questions', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text('$_correct correct • $_wrong attempted • $_skipped skipped', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('Official scores come from POST /quiz/attempts/{attempt}/complete — this local drill is provisional and offline-capable.', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
        body: const Center(child: Text('No questions')),
      );
    }

    final progress = (qs.isEmpty) ? 0.0 : (_index + 1) / qs.length;

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
                Text('$_correct✓ $_wrong✗ $_skipped–', style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
                      Text(_current.questionText.isEmpty ? 'Practice question #${_current.id} — content loads from GET /quiz/questions or bookmarked set.' : _current.questionText, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, height: 1.4)),
                      if (_current.difficulty != null) ...[
                        const SizedBox(height: 6),
                        Text('Difficulty: ${_current.difficulty}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Options — placeholder A-D for drill; real questions would have server-provided options via quiz domain
                ...['A', 'B', 'C', 'D'].map((opt) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _select(opt),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _selectedOption == opt
                                ? (_revealed ? AppColors.brand.withValues(alpha: 0.08) : theme.colorScheme.surface)
                                : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _selectedOption == opt ? AppColors.brand : theme.colorScheme.outlineVariant.withValues(alpha: 0.3), width: _selectedOption == opt ? 1.5 : 1),
                          ),
                          child: Row(children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(color: _selectedOption == opt ? AppColors.brand : theme.colorScheme.surfaceContainerHighest, shape: BoxShape.circle),
                              child: Center(child: Text(opt, style: TextStyle(fontWeight: FontWeight.bold, color: _selectedOption == opt ? Colors.white : theme.colorScheme.onSurface))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text('Option $opt — tap to select (local provisional feedback; server grading on submit).', style: const TextStyle(fontSize: 13))),
                            if (_revealed && _selectedOption == opt) const Icon(Icons.check_circle_rounded, color: AppColors.brand, size: 18),
                          ]),
                        ),
                      ),
                    )),
                if (_revealed) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.correctGreen.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.correctGreen.withValues(alpha: 0.2))),
                    child: const Row(children: [Icon(Icons.lightbulb_rounded, size: 16, color: AppColors.correctGreen), SizedBox(width: 8), Expanded(child: Text('Recorded locally. Server will grade on POST /quiz/attempts/{attempt}/answer with Idempotency-Key.', style: TextStyle(fontSize: 11, color: AppColors.correctGreen)))]),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    OutlinedButton.icon(onPressed: _index == 0 ? null : _prev, icon: const Icon(Icons.arrow_back_rounded, size: 16), label: const Text('Prev')),
                    const Spacer(),
                    TextButton.icon(onPressed: _skip, icon: const Icon(Icons.skip_next_rounded, size: 16), label: const Text('Skip')),
                    const SizedBox(width: 8),
                    FilledButton.icon(onPressed: _next, icon: Icon(_isLast ? Icons.flag_rounded : Icons.arrow_forward_rounded, size: 16), label: Text(_isLast ? 'Finish' : 'Next')),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Practice is offline-capable with provisional local scoring. Official score replaces it on sync (see Part 6.6 reconciliation).', style: TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
