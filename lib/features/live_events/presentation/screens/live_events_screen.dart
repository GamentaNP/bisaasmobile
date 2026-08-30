import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../domain/entities/live_event.dart';
import '../controllers/live_events_controller.dart';

class LiveEventsScreen extends ConsumerStatefulWidget {
  const LiveEventsScreen({super.key});

  @override
  ConsumerState<LiveEventsScreen> createState() => _LiveEventsScreenState();
}

class _LiveEventsScreenState extends ConsumerState<LiveEventsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(liveEventsControllerProvider.notifier).fetchLiveEvents());
  }

  Future<void> _onRefresh() async {
    await ref.read(liveEventsControllerProvider.notifier).fetchLiveEvents();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveEventsControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Events'),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: state.isLoading ? null : _onRefresh)],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _buildBody(context, theme, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, LiveEventsState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return ListView(children: [const SizedBox(height: 80), ErrorView(message: state.error!, onRetry: () => ref.read(liveEventsControllerProvider.notifier).fetchLiveEvents())]);
    }
    if (state.items.isEmpty) {
      return ListView(children: const [SizedBox(height: 80), EmptyState(title: 'No live events', subtitle: 'Scheduled and live events will appear here.', icon: Icons.live_tv_rounded)]);
    }
    // Group by status: live first, then countdown, scheduled, finished
    final ordered = [...state.items]..sort((a, b) {
        final order = {'live': 0, 'countdown': 1, 'scheduled': 2, 'finished': 3};
        final ao = order[a.status] ?? 9;
        final bo = order[b.status] ?? 9;
        if (ao != bo) return ao.compareTo(bo);
        return a.startsAt.compareTo(b.startsAt);
      });

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: ordered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final e = ordered[i];
        return _LiveEventCard(event: e, onTap: () => context.push('/live-events/${e.id}'));
      },
    );
  }
}

class _LiveEventCard extends StatelessWidget {
  const _LiveEventCard({required this.event, required this.onTap});
  final LiveEvent event;
  final VoidCallback onTap;

  Color _color(String status) {
    return switch (status) {
      'live' => AppColors.wrongRed,
      'countdown' => AppColors.streakOrange,
      'scheduled' => AppColors.brand,
      'finished' => Colors.grey,
      _ => AppColors.brandDark,
    };
  }

  IconData _icon(String status) {
    return switch (status) { 'live' => Icons.circle, 'countdown' => Icons.timer_rounded, 'scheduled' => Icons.event_rounded, 'finished' => Icons.flag_rounded, _ => Icons.live_tv_rounded };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _color(event.status);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(_icon(event.status), size: 16, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Text(event.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color))),
              ],
            ),
            if (event.description != null && event.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(event.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.65))),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Chip(icon: Icons.quiz_rounded, label: '${event.questionCount} Qs'),
                _Chip(icon: Icons.timer_outlined, label: '${event.questionDurationSeconds}s / Q'),
                _Chip(icon: Icons.group_rounded, label: '${event.activeParticipantCount}${event.maxParticipants != null ? '/${event.maxParticipants}' : ''} joined'),
                if (event.waitlistedParticipantCount > 0) _Chip(icon: Icons.hourglass_empty_rounded, label: '${event.waitlistedParticipantCount} waitlisted', color: AppColors.streakOrange),
                if (event.entryFeeCoins > 0) _Chip(icon: Icons.monetization_on_rounded, label: '${event.entryFeeCoins} coins', color: AppColors.coinYellow),
                if (event.startsAt.isAfter(DateTime.now())) _Chip(icon: Icons.schedule_rounded, label: _fmt(event.startsAt)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) {
    final l = d.toLocal();
    return '${l.day}/${l.month} ${l.hour}:${l.minute.toString().padLeft(2, '0')}';
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: (color ?? Colors.grey).withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 12, color: c), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c))]),
    );
  }
}
