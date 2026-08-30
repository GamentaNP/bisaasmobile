import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../tutor/domain/entities/tutor.dart';
import '../controllers/coaching_controller.dart';
import '../../domain/entities/coaching.dart';

/// Coaching dashboard — aggregates readiness + today + weak areas + projected
/// score + weekly report + revisions. Tolerant: partial backend still renders.
class CoachingDashboardScreen extends ConsumerStatefulWidget {
  const CoachingDashboardScreen({super.key, this.goalId});

  /// Optional goal slug/id for readiness — passed via query param.
  final String? goalId;

  @override
  ConsumerState<CoachingDashboardScreen> createState() => _CoachingDashboardScreenState();
}

class _CoachingDashboardScreenState extends ConsumerState<CoachingDashboardScreen> {
  String? _goalInput;

  @override
  void initState() {
    super.initState();
    _goalInput = widget.goalId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = ref.read(coachingControllerProvider.notifier);
      if (widget.goalId != null && widget.goalId!.isNotEmpty) {
        ctrl.setGoal(widget.goalId);
      }
      ctrl.load(goalId: _goalInput);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coachingControllerProvider);
    final dashboard = state.dashboard;
    final theme = Theme.of(context);
    final isLoading = state.isLoading && dashboard == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coaching'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: state.isRefreshing ? null : () => ref.read(coachingControllerProvider.notifier).refresh(),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'tutor_chat') context.push('/tutor/chat');
              if (v == 'tutor_plan') context.push('/tutor/plan');
              if (v == 'tutor_onboarding') context.push('/tutor/onboarding');
            },
            itemBuilder: (c) => const [
              PopupMenuItem(value: 'tutor_chat', child: Text('Tutor chat')),
              PopupMenuItem(value: 'tutor_plan', child: Text('Study plan')),
              PopupMenuItem(value: 'tutor_onboarding', child: Text('Tutor onboarding')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(coachingControllerProvider.notifier).refresh(),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Goal input for readiness (when no goalId)
                  if (state.selectedGoalId == null || state.selectedGoalId!.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  hintText: 'Goal ID for readiness (e.g., psc-civil)',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  prefixIcon: Icon(Icons.flag_rounded),
                                ),
                                onChanged: (v) => _goalInput = v.trim(),
                                onSubmitted: (v) {
                                  ref.read(coachingControllerProvider.notifier).setGoal(v.trim());
                                  ref.read(coachingControllerProvider.notifier).load(goalId: v.trim());
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(onPressed: () {
                              final g = _goalInput?.trim() ?? '';
                              if (g.isEmpty) return;
                              ref.read(coachingControllerProvider.notifier).setGoal(g);
                              ref.read(coachingControllerProvider.notifier).load(goalId: g);
                            }, child: const Text('Load')),
                          ],
                        ),
                      ),
                    ),
                  if (state.error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.wrongRed.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [const Icon(Icons.error_outline_rounded, color: AppColors.wrongRed, size: 16), const SizedBox(width: 8), Expanded(child: Text(state.error!, style: const TextStyle(fontSize: 12, color: AppColors.wrongRed))), TextButton(onPressed: () => ref.read(coachingControllerProvider.notifier).clearError(), child: const Text('Dismiss'))]),
                    ),
                  if (dashboard == null)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('No coaching data yet — complete onboarding or chat with tutor to seed.', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center)),
                    )
                  else ...[
                    if (dashboard.isDegraded)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.xpGold.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.xpGold.withValues(alpha: 0.2))),
                        child: const Row(children: [Icon(Icons.info_outline_rounded, size: 16, color: AppColors.xpGold), SizedBox(width: 8), Expanded(child: Text('Some coaching surfaces are temporarily unavailable — showing available data.', style: TextStyle(fontSize: 12, color: AppColors.xpGold)))]),
                      ),
                    // Readiness
                    if (dashboard.readiness != null) _ReadinessCard(readiness: dashboard.readiness!) else if (state.selectedGoalId != null && state.selectedGoalId!.isNotEmpty) const Padding(padding: EdgeInsets.only(bottom: 12), child: Text('Readiness: no data for this goal yet.', style: TextStyle(fontSize: 12, color: Colors.grey))),
                    // Today
                    if (dashboard.today != null) _TodayCard(today: dashboard.today!),
                    // Projected score inline
                    if (dashboard.projectedScore != null) _ProjectedScoreCard(score: dashboard.projectedScore!),
                    // Weak areas
                    if (dashboard.weakAreas.isNotEmpty) _WeakAreasCard(areas: dashboard.weakAreas),
                    // Tracks
                    if (dashboard.tracks.isNotEmpty) _TracksCard(tracks: dashboard.tracks),
                    // Weekly snippet
                    if (dashboard.weeklyReport != null) _WeeklySnippet(report: dashboard.weeklyReport!),
                    // Revisions due count
                    _RevisionsSnippet(count: dashboard.revisionsDue.length, onTap: () => context.push('/tutor/plan')),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(onPressed: () => context.push('/tutor/chat'), icon: const Icon(Icons.smart_toy_rounded, size: 16), label: const Text('Ask tutor')),
                        OutlinedButton.icon(onPressed: () => context.push('/tutor/plan'), icon: const Icon(Icons.assignment_rounded, size: 16), label: const Text('Study plan')),
                        OutlinedButton.icon(onPressed: () => context.push('/tutor/onboarding'), icon: const Icon(Icons.auto_awesome_rounded, size: 16), label: const Text('Onboarding')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Coaching aggregates GET /learning/goals/{goal}/readiness, /learning/today, /learning/tracks + tutor insights. Tolerant to missing surfaces.', style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey)),
                  ],
                  if (state.isRefreshing) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
                ],
              ),
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({required this.readiness});
  final Readiness readiness;

  @override
  Widget build(BuildContext context) {
    final pct = readiness.percentage;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.verified_rounded, color: AppColors.brand, size: 18)), const SizedBox(width: 10), const Text('Readiness', style: TextStyle(fontWeight: FontWeight.bold)), const Spacer(), if (readiness.level != null) Chip(label: Text(readiness.level!, style: const TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact)]),
        const SizedBox(height: 10),
        if (readiness.hasData) ...[
          Text('${pct.toStringAsFixed(0)}%', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.brandDark)),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: pct / 100, color: AppColors.brand, backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest),
          if (readiness.missingTopics.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Focus next:', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ...readiness.missingTopics.take(3).map((t) => Padding(padding: const EdgeInsets.only(bottom: 2), child: Row(children: [const Icon(Icons.arrow_right_rounded, size: 14, color: Colors.grey), const SizedBox(width: 4), Expanded(child: Text(t, style: const TextStyle(fontSize: 12)))]))),
          ],
          if (readiness.nextSteps.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...readiness.nextSteps.take(2).map((s) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [const Icon(Icons.check_rounded, size: 12, color: AppColors.correctGreen), const SizedBox(width: 6), Expanded(child: Text(s, style: const TextStyle(fontSize: 12)))]))),
          ],
        ] else
          const Text('No readiness yet — attempt a few quizzes under this goal.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 6),
        Text('Goal ${readiness.goalId}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.today});
  final CoachingToday today;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.brand.withValues(alpha: 0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.today_rounded, color: AppColors.brand, size: 18), const SizedBox(width: 8), Text(today.title, style: const TextStyle(fontWeight: FontWeight.bold)), const Spacer(), Text('${today.completedCount}/${today.totalCount}', style: const TextStyle(fontSize: 11, color: Colors.grey))]),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: today.progress, color: AppColors.brand),
        if (today.tasks.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...today.tasks.take(3).map((t) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.correctGreen), const SizedBox(width: 6), Expanded(child: Text(t, style: const TextStyle(fontSize: 12)))]))),
          if (today.tasks.length > 3) Text('+ ${today.tasks.length - 3} more', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ] else
          const Text('No tasks today', style: TextStyle(fontSize: 12, color: Colors.grey)),
      ]),
    );
  }
}

class _ProjectedScoreCard extends StatelessWidget {
  const _ProjectedScoreCard({required this.score});
  final ProjectedScore score;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.xpGold.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.xpGold.withValues(alpha: 0.18))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.xpGold.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.trending_up_rounded, color: AppColors.xpGold, size: 18)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Projected score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text('${score.score.toStringAsFixed(1)} / ${score.maxScore.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.xpGold)),
            if (score.confidence != null) Text('Confidence ${(score.confidence! * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
        ),
        if (score.trend != null) Chip(label: Text(score.trend!, style: const TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact),
      ]),
    );
  }
}

class _WeakAreasCard extends StatelessWidget {
  const _WeakAreasCard({required this.areas});
  final List<WeakArea> areas;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.25))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.warning_amber_rounded, color: AppColors.wrongRed, size: 18), const SizedBox(width: 8), const Text('Weak areas', style: TextStyle(fontWeight: FontWeight.bold)), const Spacer(), Text('${areas.length}', style: const TextStyle(fontSize: 12, color: Colors.grey))]),
        const SizedBox(height: 8),
        ...areas.take(3).map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Expanded(child: Text(a.topic, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                if (a.accuracy != null) Text('${(a.accuracy! * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, color: AppColors.wrongRed)),
              ]),
            )),
      ]),
    );
  }
}

class _TracksCard extends StatelessWidget {
  const _TracksCard({required this.tracks});
  final List<CoachingTrack> tracks;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Learning tracks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: tracks.take(6).map((t) => Chip(label: Text(t.name, style: const TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact)).toList()),
        if (tracks.length > 6) Padding(padding: const EdgeInsets.only(top: 6), child: Text('+ ${tracks.length - 6} more', style: const TextStyle(fontSize: 11, color: Colors.grey))),
      ]),
    );
  }
}

class _WeeklySnippet extends StatelessWidget {
  const _WeeklySnippet({required this.report});
  final WeeklyReport report;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.brandDark.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.brandDark.withValues(alpha: 0.08))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.calendar_view_week_rounded, size: 16, color: AppColors.brandDark), SizedBox(width: 6), Text('This week', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))]),
        const SizedBox(height: 6),
        Text('${report.tasksCompleted}/${report.tasksPlanned} tasks • avg ${report.averageScore?.toStringAsFixed(1) ?? '—'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        if (report.summary != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(report.summary!, style: const TextStyle(fontSize: 12, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

class _RevisionsSnippet extends StatelessWidget {
  const _RevisionsSnippet({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: count == 0 ? AppColors.correctGreen.withValues(alpha: 0.06) : AppColors.xpGold.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: count == 0 ? AppColors.correctGreen.withValues(alpha: 0.14) : AppColors.xpGold.withValues(alpha: 0.18))),
        child: Row(children: [
          Icon(count == 0 ? Icons.check_circle_rounded : Icons.repeat_rounded, color: count == 0 ? AppColors.correctGreen : AppColors.xpGold, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(count == 0 ? 'No revisions due' : '$count revisions due', style: TextStyle(fontWeight: FontWeight.bold, color: count == 0 ? AppColors.correctGreen : AppColors.xpGold))),
          const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
        ]),
      ),
    );
  }
}
