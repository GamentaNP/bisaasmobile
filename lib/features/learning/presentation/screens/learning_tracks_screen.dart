import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../controllers/learning_controller.dart';

/// Learning tracks — GET /learning/tracks (server-verified, envelope {success,data,message}).
/// Tolerant additive parsing; never throws on new server fields.
/// Hub for creating a goal (POST /learning/goals with Idempotency-Key).
class LearningTracksScreen extends ConsumerStatefulWidget {
  const LearningTracksScreen({super.key});

  @override
  ConsumerState<LearningTracksScreen> createState() => _LearningTracksScreenState();
}

class _LearningTracksScreenState extends ConsumerState<LearningTracksScreen> {
  int? _creatingForTrackId;

  Future<void> _createGoal(int trackId) async {
    setState(() => _creatingForTrackId = trackId);
    final goal = await ref.read(learningControllerProvider.notifier).createGoal(trackId: trackId);
    if (!mounted) return;
    setState(() => _creatingForTrackId = null);
    if (goal != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Goal created for track #$trackId'), backgroundColor: AppColors.correctGreen));
      // Navigate to goal detail
      unawaited(context.push('/learning/goals/${goal.id}'));
    } else {
      final err = ref.read(learningControllerProvider).createGoalError ?? 'Failed to create goal';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.wrongRed));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tracksAsync = ref.watch(learningTracksProvider);
    final ctrlState = ref.watch(learningControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Tracks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today_rounded),
            tooltip: 'Today plan',
            onPressed: () => context.push('/learning/today'),
          ),
          IconButton(
            icon: const Icon(Icons.repeat_rounded),
            tooltip: 'Reviews due',
            onPressed: () => context.push('/learning/reviews'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(learningTracksProvider);
          try {
            await ref.read(learningTracksProvider.future);
          } catch (_) {}
        },
        child: tracksAsync.when(
          data: (tracks) {
            if (tracks.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  EmptyState(title: 'No tracks yet', subtitle: 'Tracks will appear here once published via GET /learning/tracks', icon: Icons.school_rounded),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: tracks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final t = tracks[i];
                final creating = _creatingForTrackId == t.id;
                return Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.track_changes_rounded, size: 18, color: AppColors.brand),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                  if (t.trackType != null) Text(t.trackType!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                            if (t.status != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: (t.status == 'published' ? AppColors.correctGreen : Colors.grey).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                child: Text(t.status!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.status == 'published' ? AppColors.correctGreen : Colors.grey)),
                              ),
                          ],
                        ),
                        if (t.description != null && t.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(t.description!, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.7), height: 1.4)),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (t.syllabusNodesCount != null) ...[
                              const Icon(Icons.account_tree_rounded, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('${t.syllabusNodesCount} nodes', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              const SizedBox(width: 12),
                            ],
                            if (t.goalsCount != null) ...[
                              const Icon(Icons.flag_rounded, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('${t.goalsCount} goals', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                            const Spacer(),
                            FilledButton.tonalIcon(
                              onPressed: creating || ctrlState.isCreatingGoal ? null : () => _createGoal(t.id),
                              icon: creating ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add_rounded, size: 16),
                              label: Text(creating ? 'Creating…' : 'Create goal', style: const TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [ErrorView(message: e.toString(), onRetry: () => ref.invalidate(learningTracksProvider))],
          ),
        ),
      ),
    );
  }
}
