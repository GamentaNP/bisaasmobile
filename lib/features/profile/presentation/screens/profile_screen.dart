import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(radius: 36, backgroundColor: AppColors.brand.withValues(alpha: 0.15), child: Text(user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'C', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.brand))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.name ?? 'Engineer', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text(user?.email ?? 'offline@bisaas.test', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                  const SizedBox(height: 4),
                  Text('Level ${user?.level ?? 1} • ${user?.coins ?? 0} coins', style: const TextStyle(fontSize: 12, color: AppColors.xpGold, fontWeight: FontWeight.w600)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          _Tile(icon: Icons.school_rounded, title: 'Learning — tracks & AI tutor', subtitle: 'GET /learning/*', onTapRoute: '/learning'),
          _Tile(icon: Icons.psychology_rounded, title: 'Exam Intelligence (EICE)', subtitle: 'coach • triage • sprint', onTapRoute: '/eice'),
          _Tile(icon: Icons.account_balance_rounded, title: 'PSC / Loksewa', subtitle: 'GET /psc/blueprints', onTapRoute: '/psc'),
          _Tile(icon: Icons.search_rounded, title: 'Search', subtitle: 'GET /quiz/questions?search=', onTapRoute: '/search'),
          _Tile(icon: Icons.notifications_rounded, title: 'Notifications', subtitle: 'GET /notifications', onTapRoute: '/notifications'),
          _Tile(icon: Icons.share_rounded, title: 'Social & Referral', subtitle: 'share + leaderboard', onTapRoute: '/social'),
          _Tile(icon: Icons.account_balance_wallet_rounded, title: 'Wallet', subtitle: 'coins via GET /me', onTapRoute: '/economy'),
          _Tile(icon: Icons.emoji_events_rounded, title: 'Achievements', subtitle: 'streak + badges', onTapRoute: '/achievements'),
          _Tile(icon: Icons.settings_rounded, title: 'Settings', subtitle: 'language • biometrics • logout', onTapRoute: '/settings'),
          const SizedBox(height: 12),
          const Text('Library is skipped — backend not completed per user. Offline packs (42MB) via Drift + path_provider planned.', style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.subtitle, required this.onTapRoute});
  final IconData icon;
  final String title;
  final String subtitle;
  final String onTapRoute;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: AppColors.brand)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right_rounded, size: 18),
        onTap: () => context.push(onTapRoute),
      ),
    );
  }
}
