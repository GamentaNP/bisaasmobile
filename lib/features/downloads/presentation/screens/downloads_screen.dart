import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/utils/display_date.dart';
import '../../data/providers/downloads_providers.dart';
import '../../domain/entities/offline_stats.dart';
import '../../../../l10n/app_localizations.dart';

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

  /// Re-reads the offline stats. Held as a field because `FutureBuilder` needs
  /// a stable future across rebuilds.
  late Future<OfflineStats?> _statsFuture = _loadStats();

  void _reload() => setState(() => _statsFuture = _loadStats());

  Future<OfflineStats?> _loadStats() =>
      ref.read(downloadsRepositoryProvider).getStats();

  Future<void> _prefetch() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final ok = await ref.read(downloadsRepositoryProvider).prefetchOnce();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = ok ? 'Daily pack cached' : 'Nothing new to cache (offline or already cached)';
    });
  }

  Future<void> _clear() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.downloadsClearTitle),
        content: Text(l10n.downloadsClearBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.downloadsClear)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    await ref.read(downloadsRepositoryProvider).clear();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = 'Offline content cleared';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileOffline)),
      body: FutureBuilder<OfflineStats?>(
        future: _statsFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final stats = snap.data;
          // A Drift failure must not read as "0 questions cached" — that is
          // indistinguishable from a fresh install and hides a real problem.
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.storage_rounded, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text(
                      l10n.downloadsStorageUnreadable,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.downloadsNothingReported,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatCard(
                icon: Icons.quiz_rounded,
                title: l10n.downloadsCachedQuestions(stats?.questions ?? 0),
                subtitle: l10n.downloadsCacheSize(stats?.subjects ?? 0, stats?.approxKb ?? 0),
              ),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.schedule_rounded,
                label: l10n.downloadsLastCached,
                value: stats?.lastCached == null
                    ? 'Never'
                    : formatIsoDateTime(stats!.lastCached!.toLocal()),
              ),
              _InfoRow(
                icon: Icons.nights_stay_rounded,
                label: l10n.downloadsAutoDownload,
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
                label: Text(l10n.downloadsPrefetchNow),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : _clear,
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(l10n.downloadsClearAction),
              ),
            ],
          );
        },
      ),
    );
  }

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
