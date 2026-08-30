// ignore_for_file: avoid_dynamic_calls, body_might_complete_normally_catch_error

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/learning_controller.dart';

class LearningHomeScreen extends ConsumerWidget {
  const LearningHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tracksAsync = ref.watch(learningTracksProvider);
    final todayAsync = ref.watch(todayPlanProvider);
    final reviewsAsync = ref.watch(reviewsDueProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Learning')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(learningTracksProvider);
          ref.invalidate(todayPlanProvider);
          ref.invalidate(reviewsDueProvider);
          await ref.read(learningTracksProvider.future).catchError((_) {});
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            todayAsync.when(
              data: (plan) => _TodayCard(plan: plan),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => _ErrorCard(msg: e.toString(), onRetry: () => ref.invalidate(todayPlanProvider)),
            ),
            const SizedBox(height: 16),
            reviewsAsync.when(
              data: (list) => _ReviewsCard(count: list.length, onOpen: () {}),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            Text('Tracks', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            tracksAsync.when(
              data: (tracks) => tracks.isEmpty
                  ? const Text('No tracks yet — backend will publish via GET /learning/tracks', style: TextStyle(color: Colors.grey, fontSize: 12))
                  : Column(
                      children: tracks
                          .map((t) => Card(
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                                    child: const Icon(Icons.school_rounded, color: AppColors.brand, size: 18),
                                  ),
                                  title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  subtitle: t.description != null ? Text(t.description!, style: const TextStyle(fontSize: 11, color: Colors.grey)) : null,
                                  trailing: const Icon(Icons.chevron_right_rounded),
                                  onTap: () {},
                                ),
                              ))
                          .toList(),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorCard(msg: e.toString(), onRetry: () => ref.invalidate(learningTracksProvider)),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiTutorScreen())),
              icon: const Icon(Icons.smart_toy_rounded),
              label: const Text('Ask AI Tutor (non-streaming POST /learning/tutor)'),
            ),
            const SizedBox(height: 8),
            const Text('Day-one uses non-streaming tutor per MOBILE_API_INTEGRATION_GUIDE.md:112 — SSE is web-only.', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.plan});
  final dynamic plan;
  @override
  Widget build(BuildContext context) {
    // Tolerant: plan may be DailyPlan (new) or TodayPlan (legacy) or null
    if (plan == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: const Text('No tasks — check back tomorrow', style: TextStyle(fontSize: 12, color: Colors.grey)),
      );
    }
    var tasks = <String>[];
    var title = 'Today';
    try {
      // Legacy TodayPlan: has tasks + title
      if (plan.tasks is List) {
        tasks = (plan.tasks as List).cast<String>();
        title = (plan.title as String?) ?? 'Today';
      } else if (plan.items is List) {
        // DailyPlan: items are DailyPlanItem with label
        final items = plan.items as List;
        tasks = items.map((e) => (e.label ?? e.toString()).toString()).cast<String>().toList();
        title = 'Plan #${plan.id}';
      }
    } catch (_) {
      try {
        title = (plan.title as String?) ?? 'Today';
      } catch (_) {}
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (tasks.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...tasks.map((t) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.correctGreen), const SizedBox(width: 6), Expanded(child: Text(t, style: const TextStyle(fontSize: 12)))]))),
          ] else
            const Text('No tasks — check back tomorrow', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ReviewsCard extends StatelessWidget {
  const _ReviewsCard({required this.count, required this.onOpen});
  final int count;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.xpGold.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.xpGold.withValues(alpha: 0.2))),
      child: Row(
        children: [
          const Icon(Icons.repeat_rounded, color: AppColors.xpGold),
          const SizedBox(width: 10),
          Expanded(child: Text('$count reviews due (SRS)', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.xpGold))),
          TextButton(onPressed: onOpen, child: const Text('Review')),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.msg, required this.onRetry});
  final String msg;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.wrongRed.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [Expanded(child: Text(msg, style: const TextStyle(color: AppColors.wrongRed, fontSize: 12))), TextButton(onPressed: onRetry, child: const Text('Retry'))]),
    );
  }
}

class AiTutorScreen extends ConsumerStatefulWidget {
  const AiTutorScreen({super.key});
  @override
  ConsumerState<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends ConsumerState<AiTutorScreen> {
  final _ctrl = TextEditingController();
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tutorControllerProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('AI Tutor')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.messages.length,
              itemBuilder: (context, i) {
                final m = state.messages[i];
                final isUser = m.role == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.brand.withValues(alpha: 0.15) : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(m.content, style: const TextStyle(fontSize: 13, height: 1.4)),
                  ),
                );
              },
            ),
          ),
          if (state.loading) const LinearProgressIndicator(),
          if (state.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: AppColors.wrongRed.withValues(alpha: 0.08),
              child: Text(state.error!, style: const TextStyle(color: AppColors.wrongRed, fontSize: 12)),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(hintText: 'Ask tutor…', border: OutlineInputBorder(), isDense: true),
                      onSubmitted: (v) { ref.read(tutorControllerProvider.notifier).send(v); _ctrl.clear(); },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: state.loading ? null : () { ref.read(tutorControllerProvider.notifier).send(_ctrl.text); _ctrl.clear(); }, child: const Icon(Icons.send_rounded)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
