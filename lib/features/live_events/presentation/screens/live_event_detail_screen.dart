import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../domain/entities/live_event.dart';
import '../controllers/live_events_controller.dart';

class LiveEventDetailScreen extends ConsumerStatefulWidget {
  const LiveEventDetailScreen({super.key, required this.eventId});
  final String eventId;

  @override
  ConsumerState<LiveEventDetailScreen> createState() => _LiveEventDetailScreenState();
}

class _LiveEventDetailScreenState extends ConsumerState<LiveEventDetailScreen> {
  int get _id => int.tryParse(widget.eventId) ?? 0;
  final _answerCtrl = TextEditingController();
  int _questionIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final c = ref.read(liveEventDetailControllerProvider.notifier);
      c.fetchDetail(_id);
      c.fetchSnapshot(_id);
    });
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveEventDetailControllerProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(state.detail?.event.title ?? 'Live Event #$_id')),
      body: _buildBody(context, theme, state),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, LiveEventDetailState state) {
    if (state.isLoading && state.detail == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.detail == null) {
      return Center(child: ErrorView(message: state.error!, onRetry: () => ref.read(liveEventDetailControllerProvider.notifier).fetchDetail(_id)));
    }
    final detail = state.detail;
    if (detail == null) {
      return Center(child: ErrorView(message: 'Live event not found', onRetry: () => ref.read(liveEventDetailControllerProvider.notifier).fetchDetail(_id)));
    }
    final event = detail.event;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([ref.read(liveEventDetailControllerProvider.notifier).fetchDetail(_id), ref.read(liveEventDetailControllerProvider.notifier).fetchSnapshot(_id)]);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Header(event: event, theme: theme),
          const SizedBox(height: 12),
          _ActionBar(state: state, event: event, onRegister: _register, onUnregister: _unregister, onCheckIn: _checkIn, onRefreshSnapshot: _refreshSnapshot),
          if (state.registerError != null) ...[
            const SizedBox(height: 8),
            Text(state.registerError!, style: const TextStyle(fontSize: 12, color: AppColors.wrongRed)),
          ],
          if (state.checkInError != null) ...[
            const SizedBox(height: 8),
            Text(state.checkInError!, style: const TextStyle(fontSize: 12, color: AppColors.wrongRed)),
          ],
          if (state.lastParticipant != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.correctGreen.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.correctGreen.withValues(alpha: 0.2))),
              child: Text('Participant #${state.lastParticipant!.id} • ${state.lastParticipant!.status} • Score ${state.lastParticipant!.score}', style: const TextStyle(fontSize: 12, color: AppColors.correctGreen)),
            ),
          ],
          const SizedBox(height: 20),
          Text('Snapshot', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (state.isSnapshotLoading) const LinearProgressIndicator(),
          if (state.snapshotError != null) ErrorView(message: state.snapshotError!, onRetry: _refreshSnapshot),
          if (!state.isSnapshotLoading && state.snapshot != null)
            _SnapshotCard(snapshot: state.snapshot!, theme: theme)
          else if (!state.isSnapshotLoading && state.snapshot == null && state.snapshotError == null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(12)),
              child: const Text('No snapshot yet — register and check in to load current question.', style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
            ),
          const SizedBox(height: 16),
          // Answer form
          Text('Answer', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 90,
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Q index', isDense: true, border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: '$_questionIndex'),
                  onChanged: (v) => _questionIndex = int.tryParse(v) ?? 0,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _answerCtrl,
                  decoration: const InputDecoration(hintText: 'Your answer', isDense: true, border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: state.isAnswering ? null : _submitAnswer,
              icon: state.isAnswering ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded, size: 18),
              label: const Text('Submit Answer'),
            ),
          ),
          if (state.answerError != null) ...[
            const SizedBox(height: 8),
            Text(state.answerError!, style: const TextStyle(fontSize: 12, color: AppColors.wrongRed)),
          ],
          const SizedBox(height: 20),
          Text('Leaderboard', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (detail.leaderboard.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(12)),
              child: const Text('No leaderboard yet.', style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
            )
          else
            ...detail.leaderboard.take(10).map((row) {
              final rank = (row['rank'] ?? row['position'] ?? '').toString();
              final name = (row['display_name'] ?? row['name'] ?? row['user_name'] ?? 'User').toString();
              final score = (row['score'] ?? '').toString();
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2))),
                child: Row(children: [Text('#$rank', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), const SizedBox(width: 10), Expanded(child: Text(name, style: const TextStyle(fontSize: 13))), Text(score, style: const TextStyle(fontWeight: FontWeight.bold))]),
              );
            }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _register() async {
    final ok = await ref.read(liveEventDetailControllerProvider.notifier).register(_id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Registered!' : 'Register failed'), backgroundColor: ok ? AppColors.correctGreen : AppColors.wrongRed));
  }

  Future<void> _unregister() async {
    final ok = await ref.read(liveEventDetailControllerProvider.notifier).unregister(_id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Unregistered' : 'Unregister failed'), backgroundColor: ok ? AppColors.brand : AppColors.wrongRed));
  }

  Future<void> _checkIn() async {
    final ok = await ref.read(liveEventDetailControllerProvider.notifier).checkIn(_id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Checked in!' : 'Check-in failed'), backgroundColor: ok ? AppColors.correctGreen : AppColors.wrongRed));
  }

  Future<void> _refreshSnapshot() async {
    await ref.read(liveEventDetailControllerProvider.notifier).fetchSnapshot(_id);
  }

  Future<void> _submitAnswer() async {
    final ans = _answerCtrl.text.trim();
    if (ans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter an answer')));
      return;
    }
    final p = await ref.read(liveEventDetailControllerProvider.notifier).submitAnswer(_id, questionIndex: _questionIndex, answer: ans);
    if (!mounted) return;
    if (p != null) {
      _answerCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Answer recorded — score ${p.score}'), backgroundColor: AppColors.correctGreen));
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.event, required this.theme});
  final LiveEvent event;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final color = switch (event.status) { 'live' => AppColors.wrongRed, 'countdown' => AppColors.streakOrange, 'scheduled' => AppColors.brand, 'finished' => Colors.grey, _ => AppColors.brandDark };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Text(event.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color))),
              const Spacer(),
              Text('${event.questionCount} Qs • ${event.questionDurationSeconds}s each', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            ],
          ),
          const SizedBox(height: 10),
          Text(event.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          if (event.description != null && event.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(event.description!, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.65))),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _MetaChip(icon: Icons.group_rounded, label: '${event.activeParticipantCount}${event.maxParticipants != null ? '/${event.maxParticipants}' : ''} active'),
              if (event.waitlistedParticipantCount > 0) _MetaChip(icon: Icons.hourglass_empty_rounded, label: '${event.waitlistedParticipantCount} waitlisted'),
              _MetaChip(icon: Icons.schedule_rounded, label: 'Starts ${event.startsAt.toLocal().toString().split(' ').first} ${event.startsAt.toLocal().hour}:${event.startsAt.toLocal().minute.toString().padLeft(2, '0')}'),
              if (event.endsAt != null) _MetaChip(icon: Icons.flag_rounded, label: 'Ends ${event.endsAt!.toLocal().toString().split(' ').first}'),
              if (event.entryFeeCoins > 0) _MetaChip(icon: Icons.monetization_on_rounded, label: '${event.entryFeeCoins} entry'),
              _MetaChip(icon: Icons.card_giftcard_rounded, label: '${event.prizePoolCoins} prize'),
            ],
          ),
          if (event.commentatorMessage != null && event.commentatorMessage!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [const Icon(Icons.campaign_rounded, size: 14, color: AppColors.brand), const SizedBox(width: 6), Expanded(child: Text(event.commentatorMessage!, style: const TextStyle(fontSize: 12)))]),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 12, color: Colors.grey[600]), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))]),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.state, required this.event, required this.onRegister, required this.onUnregister, required this.onCheckIn, required this.onRefreshSnapshot});
  final LiveEventDetailState state;
  final LiveEvent event;
  final Future<void> Function() onRegister;
  final Future<void> Function() onUnregister;
  final Future<void> Function() onCheckIn;
  final Future<void> Function() onRefreshSnapshot;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (event.isJoinable)
          FilledButton.icon(
            onPressed: state.isRegistering ? null : onRegister,
            icon: state.isRegistering ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.how_to_reg_rounded, size: 18),
            label: const Text('Register'),
          ),
        OutlinedButton.icon(onPressed: onUnregister, icon: const Icon(Icons.person_remove_rounded, size: 18), label: const Text('Leave')),
        FilledButton.tonalIcon(onPressed: state.isCheckingIn ? null : onCheckIn, icon: const Icon(Icons.check_circle_rounded, size: 18), label: const Text('Check-in')),
        OutlinedButton.icon(onPressed: onRefreshSnapshot, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Snapshot')),
      ],
    );
  }
}

class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({required this.snapshot, required this.theme});
  final LiveEventSnapshot snapshot;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final cq = snapshot.currentQuestion;
    final p = snapshot.participant;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p != null) ...[
            Row(
              children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Text(p.status.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.brand))),
                const Spacer(),
                Text('Score ${p.score} • ${p.correctCount}/${p.answeredCount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (cq != null) ...[
            Text('Q${cq['index'] ?? cq['question_index'] ?? ''} • ${cq['points'] ?? ''} pts', style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text((cq['question_text'] ?? cq['questionText'] ?? cq['text'] ?? 'Question').toString(), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            if (cq['options'] is List) ...[
              const SizedBox(height: 8),
              ...((cq['options'] as List).map((o) {
                String label;
                if (o is Map && o['text'] != null) label = o['text'].toString();
                else label = o.toString();
                return Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10)), child: Text(label, style: const TextStyle(fontSize: 13))));
              })),
            ],
            if (cq['remaining_seconds'] != null) ...[
              const SizedBox(height: 8),
              Text('Remaining: ${cq['remaining_seconds']}s • Locks at ${cq['locks_at'] ?? ''}', style: const TextStyle(fontSize: 11, color: AppColors.wrongRed)),
            ],
          ] else ...[
            const Text('No current question — waiting for host.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Text('Raw keys: ${snapshot.raw.keys.take(8).join(', ')}', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
          ],
        ],
      ),
    );
  }
}
