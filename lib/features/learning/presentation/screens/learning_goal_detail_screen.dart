import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/error_view.dart';
import '../controllers/learning_controller.dart';

/// Goal detail — GET /learning/goals/{goal} (envelope) + GET /learning/goals/{goal}/readiness
/// + DELETE /learning/goals/{goal}. All verified via artisan route:list.
/// Readiness is 0-100 mastery average; client never computes it.
class LearningGoalDetailScreen extends ConsumerStatefulWidget {
  const LearningGoalDetailScreen({super.key, required this.goalId});
  final String goalId;

  @override
  ConsumerState<LearningGoalDetailScreen> createState() => _LearningGoalDetailScreenState();
}

class _LearningGoalDetailScreenState extends ConsumerState<LearningGoalDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final goalIdInt = int.tryParse(widget.goalId) ?? 0;
    final goalAsync = ref.watch(learningGoalDetailProvider(goalIdInt));
    final readinessAsync = ref.watch(learningGoalReadinessProvider(goalIdInt));
    final ctrl = ref.watch(learningControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Goal #${widget.goalId}'),
        actions: [
          IconButton(icon: const Icon(Icons.today_rounded), tooltip: 'Today', onPressed: () => context.push('/learning/today')),
        ],
      ),
      body: goalAsync.when(
        data: (goal) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(learningGoalDetailProvider(goalIdInt));
              ref.invalidate(learningGoalReadinessProvider(goalIdInt));
              try {
                await Future.wait([
                  ref.read(learningGoalDetailProvider(goalIdInt).future),
                  ref.read(learningGoalReadinessProvider(goalIdInt).future),
                ]);
              } catch (_) {}
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.flag_rounded, size: 18, color: AppColors.brand),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(goal.track?.title ?? 'Track #${goal.trackId}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          ),
                          if (goal.status != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: (goal.isActive ? AppColors.correctGreen : Colors.grey).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                              child: Text(goal.status!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: goal.isActive ? AppColors.correctGreen : Colors.grey)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _Row(label: 'Goal ID', value: '${goal.id}'),
                      _Row(label: 'Track ID', value: '${goal.trackId}'),
                      if (goal.targetDate != null) _Row(label: 'Target date', value: DateFormat.yMMMEd().format(goal.targetDate!.toLocal())),
                      if (goal.dailyMinutes != null) _Row(label: 'Daily minutes', value: '${goal.dailyMinutes}'),
                      if (goal.intensity != null) _Row(label: 'Intensity', value: goal.intensity!),
                      if (goal.placementMeta != null && goal.placementMeta!.isNotEmpty) _Row(label: 'Placement', value: goal.placementMeta.toString()),
                      const SizedBox(height: 12),
                      readinessAsync.when(
                        data: (r) => Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.xpGold.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.xpGold.withValues(alpha: 0.2))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.insights_rounded, size: 18, color: AppColors.xpGold),
                                  const SizedBox(width: 6),
                                  Text('Readiness', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.xpGold)),
                                  const Spacer(),
                                  Text('${r.readiness}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.xpGold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: r.readinessFraction, minHeight: 8, backgroundColor: Colors.white, color: AppColors.xpGold)),
                              const SizedBox(height: 6),
                              Text('${r.readiness}% mastery across ${r.topicCount} topics (MasteryService::computeReadiness)', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('Readiness: $e', style: const TextStyle(fontSize: 11, color: AppColors.wrongRed)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (ctrl.deleteGoalError != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.wrongRed.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [Expanded(child: Text(ctrl.deleteGoalError!, style: const TextStyle(color: AppColors.wrongRed, fontSize: 12))), TextButton(onPressed: () => ref.read(learningControllerProvider.notifier).clearErrors(), child: const Text('Dismiss'))]),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: ctrl.isDeletingGoal
                      ? null
                      : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('Delete goal?'),
                              content: const Text('This will permanently delete the goal. Daily plans remain but no new plans will be built.'),
                              actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete'))],
                            ),
                          );
                          if (confirm != true || !context.mounted) return;
                          final ok = await ref.read(learningControllerProvider.notifier).deleteGoal(goal.id);
                          if (ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Goal deleted'), backgroundColor: AppColors.correctGreen));
                            context.pop();
                          }
                        },
                  icon: ctrl.isDeletingGoal ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.delete_rounded, color: AppColors.wrongRed),
                  label: Text(ctrl.isDeletingGoal ? 'Deleting…' : 'Delete goal', style: const TextStyle(color: AppColors.wrongRed)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.wrongRed)),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(onPressed: () => context.push('/learning/today'), icon: const Icon(Icons.calendar_today_rounded), label: const Text('Open Today plan')),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(onPressed: () => context.push('/learning/tracks'), icon: const Icon(Icons.track_changes_rounded), label: const Text('Back to tracks')),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(16), child: ErrorView(message: e.toString(), onRetry: () => ref.invalidate(learningGoalDetailProvider(goalIdInt))))),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))), Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)))]),
    );
  }
}
