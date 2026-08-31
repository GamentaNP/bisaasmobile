import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/storage/database/daos/quiz_dao.dart';

/// Offline content manager. Surfaces what the app has cached locally for
/// offline practice (question count, distinct subjects, rough size), lets the
/// user trigger a manual prefetch, and clear the cache. All figures come from
/// the Drift `Questions` table — the same cache `DailyQuizPrefetcher` warms —
/// so this screen never invents numbers or talks to the network directly.
class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  bool _busy = false;
  String? _message;

  Future<_OfflineStats?> _loadStats() async {
    final db = ref.read(appDatabaseProvider);
    final dao = QuizDao(db);
    final rows = await dao.all();
    if (rows.isEmpty) return _OfflineStats.empty;
    final subjects = rows.map((r) => r.subjectSlug).where((s) => s.isNotEmpty).toSet();
    final bytes = rows.fold<int>(0, (sum, r) => sum + r.body.length + r.optionsJson.length);
    final newest = rows
        .map((r) => r.cachedAt)
        .whereType<DateTime>()
        .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
    return _OfflineStats(
      questions: rows.length,
      subjects: subjects.length,
      approxKb: (bytes / 1024).ceil(),
      lastCached: newest,
    );
  }

  Future<void> _prefetch() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final ok = await ref.read(dailyQuizPrefetcherProvider).prefetchOnce();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = ok ? 'Daily pack cached' : 'Nothing new to cache (offline or already cached)';
    });
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear offline content?'),
        content: const Text('This removes all cached questions. You can re-download anytime while online.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    await QuizDao(ref.read(appDatabaseProvider)).clear();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = 'Offline content cleared';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline content')),
      body: FutureBuilder<_OfflineStats?>(
        future: _loadStats(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final stats = snap.data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatCard(
                icon: Icons.quiz_rounded,
                title: '${stats?.questions ?? 0} questions cached',
                subtitle: '${stats?.subjects ?? 0} subjects · ~${stats?.approxKb ?? 0} KB',
              ),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.schedule_rounded,
                label: 'Last cached',
                value: stats?.lastCached == null
                    ? 'Never'
                    : _fmt(stats!.lastCached!),
              ),
              _InfoRow(
                icon: Icons.nights_stay_rounded,
                label: 'Auto-download',
                value: 'Daily at midnight (while app open)',
              ),
              if (_message != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_message!, style: const TextStyle(fontSize: 13)),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _busy ? null : _prefetch,
                icon: _busy
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download_rounded),
                label: const Text('Prefetch daily pack now'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : _clear,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Clear offline content'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _fmt(DateTime d) {
    final local = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }
}

class _OfflineStats {
  const _OfflineStats({
    required this.questions,
    required this.subjects,
    required this.approxKb,
    this.lastCached,
  });
  static const empty = _OfflineStats(questions: 0, subjects: 0, approxKb: 0);
  final int questions;
  final int subjects;
  final int approxKb;
  final DateTime? lastCached;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.brand),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 12),
          Text(label, style: theme.textTheme.bodyMedium),
          const Spacer(),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
