import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

/// Economy — resource inventory (coins, wallet) via GET /me (server-authoritative).
/// Flutter never mints locally; EconomyService::debit is server truth.
class EconomyScreen extends ConsumerWidget {
  const EconomyScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final coins = user?.coins ?? 0;
    final xp = user?.xp ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.coinYellow.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.coinYellow.withValues(alpha: 0.2))),
              child: Row(children: [const Icon(Icons.monetization_on_rounded, color: AppColors.coinYellow, size: 32), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$coins coins', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.coinYellow)), Text('$xp XP total', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)))])]),
            ),
            const SizedBox(height: 12),
            const Text('GET /economy/resources/inventory when available; otherwise coalesced from GET /me. Never computed on-device.', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
