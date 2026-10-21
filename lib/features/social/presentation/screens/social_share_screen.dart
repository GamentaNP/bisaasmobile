import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../domain/entities/social.dart';
import '../controllers/social_controller.dart';

/// The guest share flow — the destination of a `https://bisaas.com/s/{token}`
/// share link.
///
/// The server owns the whole flow:
///
///  * `GET  /public/social/share/{token}` resolves the link.
///  * `POST /public/social/sandbox/{token}` starts an attempt and publishes
///    the questions it picked.
///  * `PUT  /public/social/sandbox/{attempt}/answer` grades one answer.
///  * `PUT  /public/social/sandbox/{attempt}/completion` closes it.
///
/// A sandbox attempt runs against a sentinel user and completes with **zero**
/// progression grants, so a guest can play without touching anyone's balance.
/// The screen says so rather than letting the guest wonder why they earned
/// nothing.
class SocialShareScreen extends ConsumerStatefulWidget {
  const SocialShareScreen({super.key, required this.token});
  final String token;

  @override
  ConsumerState<SocialShareScreen> createState() => _SocialShareScreenState();
}

class _SocialShareScreenState extends ConsumerState<SocialShareScreen> {
  SharedLink? _link;
  SandboxAttempt? _attempt;
  SandboxResult? _result;

  /// The question the guest is looking at.
  int _index = 0;

  /// The option the guest picked for the current question, if any.
  String? _selected;

  /// The server's verdict for the current question. Null until it answers.
  bool? _isCorrect;

  String? _error;
  bool _loading = true;
  bool _busy = false;

  /// The guest session id the attempt is bound to.
  ///
  /// Generated on the device, 8..64 characters (the server's rule), and
  /// stable for the life of this screen so a retry re-uses it.
  late final String _guestSessionId = _generateGuestSessionId();

  static const _uuid = Uuid();

  static String _generateGuestSessionId() => 'guest-${_uuid.v4()}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final link = await ref
          .read(socialControllerProvider.notifier)
          .resolveShare(widget.token);
      if (!mounted) return;
      setState(() {
        _link = link;
        _loading = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _startSandbox() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final attempt = await ref
          .read(socialControllerProvider.notifier)
          .startSandbox(
            token: widget.token,
            guestSessionId: _guestSessionId,
          );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _attempt = attempt;
        _index = 0;
        _selected = null;
        _isCorrect = null;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _answer() async {
    final attempt = _attempt;
    final question = _currentQuestion;
    final selected = _selected;
    if (attempt == null || question == null || selected == null) return;

    setState(() => _busy = true);
    try {
      final verdict = await ref
          .read(socialControllerProvider.notifier)
          .answerSandbox(
            attemptId: attempt.attemptId,
            questionId: question.id,
            answer: selected,
          );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _isCorrect = verdict.isCorrect;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _next() async {
    final attempt = _attempt;
    if (attempt == null) return;

    final isLast = _index >= attempt.questions.length - 1;
    if (!isLast) {
      setState(() {
        _index++;
        _selected = null;
        _isCorrect = null;
      });
      return;
    }

    setState(() => _busy = true);
    try {
      final result = await ref
          .read(socialControllerProvider.notifier)
          .completeSandbox(attempt.attemptId);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _result = result;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  SandboxQuestion? get _currentQuestion {
    final attempt = _attempt;
    if (attempt == null) return null;
    if (attempt.questions.isEmpty) return null;
    if (_index >= attempt.questions.length) return null;
    return attempt.questions[_index];
  }

  @override
  Widget build(BuildContext context) {
    final link = _link;

    return Scaffold(
      appBar: AppBar(title: const Text('Shared challenge')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _result != null
              ? _ResultView(result: _result!, creatorName: link?.creatorName)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (link == null)
                      ErrorView(
                        message: _error ?? 'That share link could not be found.',
                        onRetry: _resolve,
                      )
                    else ...[
                      _LinkHeader(link: link),
                      const SizedBox(height: 16),
                      if (_error != null) ...[
                        _ErrorBanner(message: _error!),
                        const SizedBox(height: 12),
                      ],
                      if (_attempt == null)
                        _StartPrompt(
                          busy: _busy,
                          available: link.sandboxAvailable && !link.isExpired,
                          onStart: _startSandbox,
                        )
                      else
                        _PlayView(
                          attempt: _attempt!,
                          index: _index,
                          question: _currentQuestion,
                          selected: _selected,
                          isCorrect: _isCorrect,
                          busy: _busy,
                          onSelect: (key) => setState(() => _selected = key),
                          onAnswer: _answer,
                          onNext: _next,
                        ),
                    ],
                  ],
                ),
    );
  }
}

/// The header of the shared link.
class _LinkHeader extends StatelessWidget {
  const _LinkHeader({required this.link});
  final SharedLink link;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Someone shared a challenge with you',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          if (link.creatorName != null)
            Text(
              'Shared by ${link.creatorName}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          if (link.isExpired) ...[
            const SizedBox(height: 6),
            const Text(
              'This link has expired.',
              style: TextStyle(fontSize: 12, color: AppColors.wrongRed),
            ),
          ],
        ],
      ),
    );
  }
}

/// The "play the challenge" prompt, before the attempt exists.
class _StartPrompt extends StatelessWidget {
  const _StartPrompt({
    required this.busy,
    required this.available,
    required this.onStart,
  });

  final bool busy;
  final bool available;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    if (!available) {
      return const EmptyState(
        title: 'No playable challenge here',
        subtitle:
            'This link does not offer a playable challenge. You can still '
            'browse the public catalogue.',
        icon: Icons.link_off_rounded,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: busy ? null : onStart,
          icon: busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.play_arrow_rounded),
          label: Text(busy ? 'Starting…' : 'Play the challenge'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        const SizedBox(height: 12),
        const Text(
          'A guest challenge never awards coins, XP or streak. Create a free '
          'account to keep your progress.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
        ),
      ],
    );
  }
}

/// The playable part: the questions, the answers and the verdicts.
class _PlayView extends StatelessWidget {
  const _PlayView({
    required this.attempt,
    required this.index,
    required this.question,
    required this.selected,
    required this.isCorrect,
    required this.busy,
    required this.onSelect,
    required this.onAnswer,
    required this.onNext,
  });

  final SandboxAttempt attempt;
  final int index;
  final SandboxQuestion? question;
  final String? selected;
  final bool? isCorrect;
  final bool busy;
  final ValueChanged<String> onSelect;
  final VoidCallback onAnswer;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = question;

    if (q == null) {
      return const EmptyState(
        title: 'This challenge has no questions',
        subtitle:
            'The server opened the attempt without sending any questions, so '
            'there is nothing to play.',
        icon: Icons.quiz_outlined,
      );
    }

    final answered = isCorrect != null;
    final isLast = index >= attempt.questions.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Question ${index + 1} of ${attempt.questions.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brand,
                ),
              ),
            ),
            const Spacer(),
            if (q.difficulty != null)
              Text(
                q.difficulty!,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            q.questionText.isEmpty
                ? 'This question has no text on the server.'
                : q.questionText,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600, height: 1.4),
          ),
        ),
        const SizedBox(height: 14),
        ...q.options.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: answered || busy ? null : () => onSelect(option.key),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected == option.key
                      ? AppColors.brand.withValues(alpha: 0.08)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected == option.key
                        ? AppColors.brand
                        : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: selected == option.key ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected == option.key
                            ? AppColors.brand
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        option.key,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: selected == option.key
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option.text,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    if (selected == option.key)
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.brand, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (answered) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isCorrect == true ? AppColors.correctGreen : AppColors.wrongRed)
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (isCorrect == true ? AppColors.correctGreen : AppColors.wrongRed)
                    .withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isCorrect == true
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  size: 18,
                  color: isCorrect == true
                      ? AppColors.correctGreen
                      : AppColors.wrongRed,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isCorrect == true
                        ? 'Correct.'
                        : 'Not this time — the server has marked it.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isCorrect == true
                          ? AppColors.correctGreen
                          : AppColors.wrongRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (!answered)
          FilledButton.icon(
            onPressed: (busy || selected == null) ? null : onAnswer,
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: const Text('Submit answer'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          )
        else
          FilledButton.icon(
            onPressed: busy ? null : onNext,
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    isLast ? Icons.flag_rounded : Icons.arrow_forward_rounded,
                    size: 18,
                  ),
            label: Text(isLast ? 'Finish' : 'Next'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
      ],
    );
  }
}

/// The finished challenge.
class _ResultView extends StatelessWidget {
  const _ResultView({required this.result, this.creatorName});
  final SandboxResult result;
  final String? creatorName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 24),
        const Icon(Icons.emoji_events_rounded, size: 56, color: AppColors.coinYellow),
        const SizedBox(height: 12),
        Text(
          'Challenge complete',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'You scored ${result.score.toStringAsFixed(0)}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.coinYellow,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${result.correct} correct • ${result.wrong} wrong • ${result.skipped} skipped • ${result.total} questions',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Text(
          creatorName == null
              ? 'A guest challenge never awards coins, XP or streak.'
              : "Nice one — that was $creatorName's challenge. A guest challenge "
                  'never awards coins, XP or streak.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => context.go('/register'),
          icon: const Icon(Icons.person_add_alt_rounded),
          label: const Text('Create a free account'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => context.go('/quiz/funnel'),
          icon: const Icon(Icons.explore_outlined),
          label: const Text('Browse sample questions'),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.wrongRedBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.wrongRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.wrongRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: AppColors.wrongRed),
            ),
          ),
        ],
      ),
    );
  }
}
