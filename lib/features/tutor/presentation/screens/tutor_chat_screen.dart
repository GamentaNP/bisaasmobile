// ignore_for_file: prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/tutor_controller.dart';
import '../../domain/entities/tutor.dart';

/// AI Tutor chat — non-streaming POST /learning/ai-tutor/chat + fallback POST /learning/tutor.
/// Per AGENTS.md streaming is web-only; v1 shows typing indicator then full response.
/// Handles sentinels NO_DATA / RETRIEVAL_FAILED and degraded flag distinctly.
class TutorChatScreen extends ConsumerStatefulWidget {
  const TutorChatScreen({super.key});

  @override
  ConsumerState<TutorChatScreen> createState() => _TutorChatScreenState();
}

class _TutorChatScreenState extends ConsumerState<TutorChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _useLegacy = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await ref.read(tutorChatControllerProvider.notifier).send(text, useLegacy: _useLegacy);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tutorChatControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tutor'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'clear') ref.read(tutorChatControllerProvider.notifier).clear();
              if (v == 'toggle_legacy') setState(() => _useLegacy = !_useLegacy);
              if (v == 'plan') context.push('/tutor/plan');
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'plan', child: Row(children: [const Icon(Icons.assignment_rounded, size: 18), const SizedBox(width: 8), const Text('Study Plan')])),
              PopupMenuItem(
                value: 'toggle_legacy',
                child: Row(children: [
                  Icon(_useLegacy ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(_useLegacy ? 'Using legacy POST /learning/tutor' : 'Use legacy tutor'),
                ]),
              ),
              const PopupMenuItem(value: 'clear', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18), SizedBox(width: 8), Text('Clear chat')])),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Sentinel / degraded banners — distinct per spec
          if (state.hasDegradedBanner)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: state.isNoData
                  ? AppColors.xpGold.withValues(alpha: 0.12)
                  : state.isRetrievalFailed
                      ? AppColors.wrongRed.withValues(alpha: 0.08)
                      : AppColors.brand.withValues(alpha: 0.08),
              child: Row(
                children: [
                  Icon(
                    state.isNoData
                        ? Icons.info_outline_rounded
                        : state.isRetrievalFailed
                            ? Icons.cloud_off_rounded
                            : Icons.tips_and_updates_rounded,
                    size: 16,
                    color: state.isNoData
                        ? AppColors.xpGold
                        : state.isRetrievalFailed
                            ? AppColors.wrongRed
                            : AppColors.brand,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.isNoData
                          ? 'Not enough history yet — complete a few quizzes to personalize.'
                          : state.isRetrievalFailed
                              ? 'Retrieval temporarily failed — showing deterministic plan.'
                              : 'Answers may be less personalized (degraded).',
                      style: TextStyle(
                        fontSize: 12,
                        color: state.isNoData
                            ? AppColors.xpGold
                            : state.isRetrievalFailed
                                ? AppColors.wrongRed
                                : AppColors.brandDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (state.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: AppColors.wrongRed.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.wrongRed),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.error!, style: const TextStyle(fontSize: 12, color: AppColors.wrongRed))),
                  TextButton(onPressed: () => ref.read(tutorChatControllerProvider.notifier).clearError(), child: const Text('Dismiss')),
                ],
              ),
            ),
          // Legacy toggle note
          if (_useLegacy)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              child: const Text(
                'Using non-streaming POST /learning/tutor (day-one, per MOBILE_API_INTEGRATION_GUIDE).',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          Expanded(
            child: state.messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.smart_toy_rounded, size: 32, color: AppColors.brand),
                          ),
                          const SizedBox(height: 16),
                          Text('Ask anything', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text(
                            'Exam concepts, beam deflection, soil mechanics — AI answers via Laravel gateway (never direct provider).',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              _SuggestionChip(label: 'Explain proctor compaction', onTap: () => _fillAndSend('Explain proctor compaction simply')),
                              _SuggestionChip(label: 'Weekly plan help', onTap: () => _fillAndSend('Help me plan this week')),
                              _SuggestionChip(label: 'Weak areas?', onTap: () => context.push('/tutor/plan')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: state.messages.length,
                    itemBuilder: (context, i) {
                      final m = state.messages[i];
                      return _MessageBubble(message: m);
                    },
                  ),
          ),
          if (state.isSending)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(children: [SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 8), Text('Tutor is typing…', style: TextStyle(fontSize: 12, color: Colors.grey))]),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: _useLegacy ? 'Ask tutor (legacy)…' : 'Ask tutor…',
                        hintStyle: const TextStyle(fontSize: 13),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: state.isSending ? null : _send,
                    style: FilledButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(12)),
                    child: const Icon(Icons.send_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _fillAndSend(String text) {
    _controller.text = text;
    _send();
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final TutorMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final theme = Theme.of(context);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          color: isUser ? AppColors.brand.withValues(alpha: 0.14) : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
          border: Border.all(color: isUser ? AppColors.brand.withValues(alpha: 0.2) : Colors.transparent),
        ),
        child: SelectableText(
          message.content,
          style: TextStyle(fontSize: 13, height: 1.45, color: theme.colorScheme.onSurface),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      backgroundColor: Theme.of(context).colorScheme.surface,
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
    );
  }
}
