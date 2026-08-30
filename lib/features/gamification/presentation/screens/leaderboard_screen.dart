// ignore_for_file: unused_import, avoid_dynamic_calls

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/dio_client.dart';

/// Tabbed leaderboard: Global / Friends / Guild.
/// Calls `GET /api/v1/leaderboard?scope=...`.
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;
  static const _scopes = ['global', 'friends', 'guild'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _scopes.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Friends'),
            Tab(text: 'Guild'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: _scopes.map((s) => _LeaderboardList(scope: s)).toList(),
      ),
    );
  }
}

class _LeaderboardList extends ConsumerWidget {
  const _LeaderboardList({required this.scope});
  final String scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dio = DioClient.instance.dio;
    return FutureBuilder<Map<String, dynamic>>(
      future: dio
          .get<Map<String, dynamic>>('/quiz/leaderboards/global',
              queryParameters: {'scope': scope})
          .then((r) => r.data ?? <String, dynamic>{}),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Failed to load: ${snap.error}', textAlign: TextAlign.center),
            ),
          );
        }
        final list = (snap.data?['data']?['entries'] as List?) ?? const [];
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.leaderboard_rounded, size: 56, color: Colors.grey),
                const SizedBox(height: 8),
                const Text('No entries yet', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('Be the first to climb the ranks', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, i) {
            final entry = (list[i] as Map).cast<String, dynamic>();
            return _LeaderboardRow(rank: i + 1, entry: entry);
          },
        );
      },
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.rank, required this.entry});
  final int rank;
  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final name = (entry['name'] ?? entry['display_name'] ?? 'User').toString();
    final xp = (entry['xp'] as int?) ?? (entry['total_xp'] as int?) ?? 0;
    final isMe = entry['is_me'] == true;
    final medalColor = switch (rank) {
      1 => AppColors.xpGold,
      2 => const Color(0xFFCBD5E1),
      3 => const Color(0xFFB45309),
      _ => null,
    };
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isMe ? AppColors.brand.withValues(alpha: 0.1) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe ? AppColors.brand : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: medalColor != null
                ? CircleAvatar(radius: 14, backgroundColor: medalColor, child: Text('$rank', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))
                : Text('#$rank', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.brand.withValues(alpha: 0.2),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name, style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.w500)),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt_rounded, color: AppColors.xpGold, size: 14),
              Text('$xp', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
