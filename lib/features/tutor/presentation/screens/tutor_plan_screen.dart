import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/tutor_controller.dart';
import '../../domain/entities/tutor.dart';

/// Tutor study plan + today + insights — GET /learning/ai-tutor/plan,
/// /today, /weak-areas, /projected-score, /weekly-report, /revisions/due
/// plus POST complete-day / adjust-plan with idempotency.
class TutorPlanScreen extends ConsumerStatefulWidget {
  const TutorPlanScreen({super.key});

  @override
  ConsumerState<TutorPlanScreen> createState() => _TutorPlanScreenState();
}

class _TutorPlanScreenState extends ConsumerState<TutorPlanScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tutorPlanControllerProvider.notifier).fetchAll();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planState = ref.watch(tutorPlanControllerProvider);
    final weakAsync = ref.watch(tutorWeakAreasProvider);
    final scoreAsync = ref.watch(tutorProjectedScoreProvider);
    final reportAsync = ref.watch(tutorWeeklyReportProvider);
    final revisionsAsync = ref.watch(tutorRevisionsDueProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Plan'),
        actions: [
          IconButton(icon: const Icon(Icons.chat_bubble_outline_rounded), tooltip: 'Chat', onPressed: () => context.push('/tutor/chat')),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => ref.read(tutorPlanControllerProvider.notifier).fetchAll()),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Plan'),
            Tab(text: 'Insights'),
            Tab(text: 'Revisions'),
            Tab(text: 'Weekly'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _PlanTab(planState: planState),
          _InsightsTab(weakAsync: weakAsync, scoreAsync: scoreAsync),
          _RevisionsTab(revisionsAsync: revisionsAsync),
          _WeeklyTab(reportAsync: reportAsync),
        ],
      ),
    );
  }
}

// ── Plan tab ────────────────────────────────────────────────────────────────

class _PlanTab extends ConsumerWidget {
  const _PlanTab({required this.planState});
  final TutorPlanState planState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = planState.plan;
    final today = planState.today;
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () => ref.read(tutorPlanControllerProvider.notifier).fetchAll(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (planState.isPlanLoading || planState.isTodayLoading) const LinearProgressIndicator(),
          if (planState.planError != null)
            _ErrorCard(msg: planState.planError!, onRetry: () => ref.read(tutorPlanControllerProvider.notifier).fetchPlan()),
          if (planState.todayError != null)
            _ErrorCard(msg: planState.todayError!, onRetry: () => ref.read(tutorPlanControllerProvider.notifier).fetchToday()),
          // Today card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: today == null
                ? const Text('No tasks today — check back tomorrow', style: TextStyle(fontSize: 12, color: Colors.grey))
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.today_rounded, color: AppColors.brand, size: 18)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(today.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                      if (today.isCompleted) const Chip(label: Text('Done', style: TextStyle(fontSize: 11)), backgroundColor: AppColors.correctGreenBg, visualDensity: VisualDensity.compact),
                    ]),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: today.progress, backgroundColor: theme.colorScheme.surfaceContainerHighest, color: AppColors.brand),
                    const SizedBox(height: 6),
                    Text('${today.completedCount}/${today.totalCount} tasks', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    if (today.tasks.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ...today.tasks.map((t) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(children: [const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.correctGreen), const SizedBox(width: 6), Expanded(child: Text(t, style: const TextStyle(fontSize: 13)))]),
                          )),
                    ],
                    if (today.summary != null) ...[
                      const SizedBox(height: 8),
                      Text(today.summary!, style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: planState.isCompletingDay || today.isCompleted
                            ? null
                            : () async {
                                final ok = await ref.read(tutorPlanControllerProvider.notifier).completeDay();
                                if (ok && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Day completed — plan updated.')));
                              },
                        icon: planState.isCompletingDay
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_rounded, size: 18),
                        label: Text(today.isCompleted ? 'Completed' : 'Mark day complete'),
                      ),
                    ),
                  ]),
          ),
          const SizedBox(height: 16),
          // Plan overview
          if (plan != null) ...[
            Text('Your plan — ${plan.title}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            if (plan.description != null) Text(plan.description!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Text('${plan.days.length} days • current ${plan.currentDayIndex ?? '-'}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 10),
            if (plan.days.isEmpty)
              const Text('Plan has no days yet — onboarding will generate it.', style: TextStyle(fontSize: 12, color: Colors.grey))
            else
              ...plan.days.take(7).map((d) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: d.isCurrent ? AppColors.brand.withValues(alpha: 0.14) : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${d.dayIndex}', style: TextStyle(fontWeight: FontWeight.bold, color: d.isCurrent ? AppColors.brandDark : Colors.grey)),
                      ),
                      title: Text(d.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: d.tasks.isEmpty ? null : Text(d.tasks.take(2).join(' • '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      trailing: d.completed ? const Icon(Icons.check_circle_rounded, color: AppColors.correctGreen, size: 18) : null,
                    ),
                  )),
            if (plan.days.length > 7) Text('+ ${plan.days.length - 7} more days', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: planState.isAdjusting
                  ? null
                  : () => _showAdjustSheet(context, ref),
              icon: const Icon(Icons.tune_rounded, size: 16),
              label: const Text('Adjust plan'),
            ),
            if (planState.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(planState.error!, style: const TextStyle(fontSize: 12, color: AppColors.wrongRed)),
              ),
          ] else if (!planState.isPlanLoading)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('No plan yet', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Complete tutor onboarding to generate your personalized study plan.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 10),
                  FilledButton(onPressed: () => context.push('/tutor/onboarding'), child: const Text('Start onboarding')),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  void _showAdjustSheet(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Adjust plan', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('e.g., "I can do 3h/day" or "Focus more on soil mechanics"', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'How should we adjust?', border: OutlineInputBorder(), isDense: true), maxLines: 3),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final text = ctrl.text.trim();
                  if (text.isEmpty) return;
                  Navigator.of(ctx).pop();
                  final ok = await ref.read(tutorPlanControllerProvider.notifier).adjustPlan({'feedback': text, 'adjustment': text});
                  if (ok && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan adjustment requested.')));
                },
                child: const Text('Submit'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Insights tab ────────────────────────────────────────────────────────────

class _InsightsTab extends StatelessWidget {
  const _InsightsTab({required this.weakAsync, required this.scoreAsync});
  final AsyncValue<List<WeakArea>> weakAsync;
  final AsyncValue<ProjectedScore> scoreAsync;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        scoreAsync.when(
          data: (s) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.brand.withValues(alpha: 0.12), AppColors.brandLight.withValues(alpha: 0.08)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.brand.withValues(alpha: 0.18)),
            ),
            child: Column(children: [
              const Text('Projected score', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${s.score.toStringAsFixed(1)} / ${s.maxScore.toStringAsFixed(0)}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.brandDark)),
              if (s.confidence != null) Text('Confidence ${(s.confidence! * 100).toStringAsFixed(0)}% • ${s.trend ?? 'stable'}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              if (s.breakdown.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...s.breakdown.entries.take(4).map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(children: [Expanded(child: Text(e.key, style: const TextStyle(fontSize: 12))), Text(e.value.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))]),
                    )),
              ],
            ]),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorCard(msg: e.toString(), onRetry: () {}),
        ),
        const SizedBox(height: 16),
        Text('Weak areas', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        weakAsync.when(
          data: (list) => list.isEmpty
              ? const Text('No weak areas — great work! Keep practicing to stay sharp.', style: TextStyle(fontSize: 12, color: Colors.grey))
              : Column(
                  children: list.take(6).map((w) => Card(
                        child: ListTile(
                          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.wrongRedBg, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.warning_amber_rounded, color: AppColors.wrongRed, size: 18)),
                          title: Text(w.topic, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            if (w.accuracy != null) Text('Accuracy ${(w.accuracy! * 100).toStringAsFixed(0)}% • ${w.attempts} attempts', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            if (w.recommendation != null) Text(w.recommendation!, style: const TextStyle(fontSize: 11, color: AppColors.brandDark)),
                          ]),
                        ),
                      )).toList(),
                ),
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => _ErrorCard(msg: e.toString(), onRetry: () {}),
        ),
      ],
    );
  }
}

// ── Revisions tab ───────────────────────────────────────────────────────────

class _RevisionsTab extends StatelessWidget {
  const _RevisionsTab({required this.revisionsAsync});
  final AsyncValue<List<RevisionItem>> revisionsAsync;

  @override
  Widget build(BuildContext context) {
    return revisionsAsync.when(
      data: (items) => items.isEmpty
          ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No revisions due — you are on track.', style: TextStyle(color: Colors.grey))))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final r = items[i];
                return Card(
                  child: ListTile(
                    leading: Icon(r.isOverdue ? Icons.alarm_rounded : Icons.schedule_rounded, color: r.isOverdue ? AppColors.wrongRed : AppColors.xpGold),
                    title: Text(r.title ?? r.questionId, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text('${r.topic ?? 'Revision'} • due ${r.dueAt.toLocal().toString().substring(0, 16)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: r.isOverdue ? AppColors.wrongRedBg : AppColors.xpGold.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                      child: Text(r.isOverdue ? 'Overdue' : 'Due', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: r.isOverdue ? AppColors.wrongRed : AppColors.xpGold)),
                    ),
                  ),
                );
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: _ErrorCard(msg: e.toString(), onRetry: () {})),
    );
  }
}

// ── Weekly tab ──────────────────────────────────────────────────────────────

class _WeeklyTab extends StatelessWidget {
  const _WeeklyTab({required this.reportAsync});
  final AsyncValue<WeeklyReport> reportAsync;

  @override
  Widget build(BuildContext context) {
    return reportAsync.when(
      data: (r) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.calendar_view_week_rounded, color: AppColors.brand),
                const SizedBox(width: 8),
                Text('Week ${r.weekStart?.toLocal().toString().substring(0, 10) ?? ''} → ${r.weekEnd?.toLocal().toString().substring(0, 10) ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                _Stat(label: 'Completed', value: '${r.tasksCompleted}/${r.tasksPlanned}', color: AppColors.correctGreen),
                const SizedBox(width: 12),
                _Stat(label: 'Avg score', value: r.averageScore == null ? '—' : r.averageScore!.toStringAsFixed(1), color: AppColors.brand),
                const SizedBox(width: 12),
                _Stat(label: 'Hours', value: r.hoursStudied == null ? '—' : r.hoursStudied!.toStringAsFixed(1), color: AppColors.xpGold),
              ]),
              LinearProgressIndicator(value: r.completionRate, color: AppColors.brand),
              const SizedBox(height: 6),
              Text('${(r.completionRate * 100).toStringAsFixed(0)}% completion', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          ),
          const SizedBox(height: 12),
          if (r.summary != null) ...[
            Text(r.summary!, style: const TextStyle(fontSize: 13, height: 1.4)),
            const SizedBox(height: 12),
          ],
          if (r.insights.isNotEmpty) ...[
            Text('Highlights', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...r.insights.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [const Icon(Icons.lightbulb_rounded, size: 14, color: AppColors.xpGold), const SizedBox(width: 6), Expanded(child: Text(s, style: const TextStyle(fontSize: 12)))]),
                )),
          ] else
            const Text('Weekly report appears after a week of activity.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(16), child: _ErrorCard(msg: e.toString(), onRetry: () {}))),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)), const SizedBox(height: 2), Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey))]),
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
      decoration: BoxDecoration(color: AppColors.wrongRed.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [Expanded(child: Text(msg, style: const TextStyle(fontSize: 12, color: AppColors.wrongRed))), TextButton(onPressed: onRetry, child: const Text('Retry'))]),
    );
  }
}
