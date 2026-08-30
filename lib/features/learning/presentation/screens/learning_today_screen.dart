import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../domain/entities/learning.dart';
import '../controllers/learning_controller.dart';

/// Today plan — GET /learning/today + POST /learning/today/{plan}/complete-item
/// Server is source of truth; client never computes progress locally beyond display.
/// Idempotency-Key on complete-item, handled in data source.
class LearningTodayScreen extends ConsumerStatefulWidget {
  const LearningTodayScreen({super.key});

  @override
  ConsumerState<LearningTodayScreen> createState() => _LearningTodayScreenState();
}

class _LearningTodayScreenState extends ConsumerState<LearningTodayScreen> {
  @override
  Widget build(BuildContext context) {
    final todayAsync = ref.watch(todayPlanProvider);
    final ctrl = ref.watch(learningControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Plan"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => ref.invalidate(todayPlanProvider)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayPlanProvider);
          try {
            await ref.read(todayPlanProvider.future);
          } catch (_) {}
        },
        child: todayAsync.when(
          data: (plan) {
            if (plan == null) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const EmptyState(
                    title: 'No active goal',
                    subtitle: 'Create a learning goal from Tracks to get a Today plan. Server returns {data: null} when none exists.',
                    icon: Icons.flag_outlined,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(onPressed: () => context.go('/learning/tracks'), icon: const Icon(Icons.track_changes_rounded), label: const Text('Browse tracks')),
                ],
              );
            }
            return _TodayPlanView(plan: plan, isCompleting: ctrl.isCompletingItem, error: ctrl.completeItemError);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(padding: const EdgeInsets.all(16), children: [ErrorView(message: e.toString(), onRetry: () => ref.invalidate(todayPlanProvider))]),
        ),
      ),
    );
  }
}

class _TodayPlanView extends ConsumerWidget {
  const _TodayPlanView({required this.plan, required this.isCompleting, this.error});
  final DailyPlan plan;
  final bool isCompleting;
  final String? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progress = plan.progress;
    return ListView(
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
                    child: const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.brand),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Plan #${plan.id}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      Text('${plan.planDate.toLocal().toIso8601String().split('T').first} • Goal #${plan.goalId}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ]),
                  ),
                  if (plan.status != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: (plan.isCompleted ? AppColors.correctGreen : AppColors.brand).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                      child: Text(plan.status!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: plan.isCompleted ? AppColors.correctGreen : AppColors.brand)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: theme.colorScheme.surfaceContainerHighest, color: AppColors.brand),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text('${plan.completedItems}/${plan.totalItems} completed', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (plan.minutesBudget != null)
                    Row(children: [const Icon(Icons.timer_outlined, size: 14, color: Colors.grey), const SizedBox(width: 4), Text('${plan.minutesBudget} min budget', style: const TextStyle(fontSize: 11, color: Colors.grey))]),
                ],
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.wrongRed.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [Expanded(child: Text(error!, style: const TextStyle(color: AppColors.wrongRed, fontSize: 12))), TextButton(onPressed: () => ref.read(learningControllerProvider.notifier).clearErrors(), child: const Text('Dismiss'))]),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (plan.items.isEmpty)
          const EmptyState(title: 'No tasks today', subtitle: 'Check back tomorrow — daily autopilot builds Review-first + new topics.', icon: Icons.check_circle_outline_rounded)
        else
          ...plan.items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final completed = item.completed;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: (completed ? AppColors.correctGreen : _colorForType(item.type)).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(completed ? Icons.check_rounded : _iconForType(item.type), size: 16, color: completed ? AppColors.correctGreen : _colorForType(item.type)),
                ),
                title: Text(item.label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, decoration: completed ? TextDecoration.lineThrough : null)),
                subtitle: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
                      child: Text(item.type, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 6),
                    if (item.estimatedMinutes > 0)
                      Text('${item.estimatedMinutes} min', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                trailing: completed
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.correctGreen)
                    : (isCompleting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : IconButton(
                            icon: const Icon(Icons.check_circle_outline_rounded),
                            onPressed: () async {
                              final notifier = ref.read(learningControllerProvider.notifier);
                              final updated = await notifier.completeItem(plan.id, idx);
                              if (updated != null && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item completed'), backgroundColor: AppColors.correctGreen));
                              }
                            },
                          )),
                onTap: completed ? null : () {},
              ),
            );
          }),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(onPressed: () => context.push('/learning/reviews'), icon: const Icon(Icons.repeat_rounded), label: const Text('Reviews due')),
      ],
    );
  }

  Color _colorForType(String type) {
    return switch (type) {
      'review' => AppColors.xpGold,
      'topic' => AppColors.brand,
      _ => Colors.grey,
    };
  }

  IconData _iconForType(String type) {
    return switch (type) {
      'review' => Icons.repeat_rounded,
      'topic' => Icons.menu_book_rounded,
      _ => Icons.task_alt_rounded,
    };
  }
}
