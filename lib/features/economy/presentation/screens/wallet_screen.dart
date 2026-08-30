import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/economy_controller.dart';
import '../../domain/entities/economy.dart';

/// Wallet — balance headline + ledger grouped by day.
/// Balance is server-authoritative (GET /economy/wallet when WO-1 ships, else GET /me).
/// Ledger is GET /economy/wallet/ledger (cursor) — currently WO-1 missing → tolerant empty/beta placeholder.
/// Flutter never mints, never decrements locally. Ledger renders credits.description as source label
/// (not metadata->source) per bisaas/AGENTS.md:155.
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(economyControllerProvider.notifier).fetchWallet();
      ref.read(economyControllerProvider.notifier).fetchLedger();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(economyControllerProvider);
    final user = ref.watch(authControllerProvider).value;
    final theme = Theme.of(context);
    // Balance: prefer wallet DTO when available, else coalesce from GET /me.
    final walletCoins = state.wallet?.coins;
    final fallbackCoins = user?.coins ?? 0;
    final balance = walletCoins ?? fallbackCoins;
    final isDegraded = state.isLedgerDegraded;
    final ledger = state.ledger;

    final grouped = _groupByDay(ledger);

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: RefreshIndicator(
        onRefresh: () => Future.wait([
          ref.read(economyControllerProvider.notifier).fetchWallet(),
          ref.read(economyControllerProvider.notifier).fetchLedger(),
        ]),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Balance headline ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.coinYellow.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.coinYellow.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.coinYellow.withValues(alpha: 0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.monetization_on_rounded, color: AppColors.coinYellow, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$balance coins', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.coinYellow)),
                        const SizedBox(height: 2),
                        Text(
                          state.isWalletLoading ? 'Syncing…' : (state.wallet?.updatedAt != null ? 'Updated ${DateFormat.yMMMd().add_jm().format(state.wallet!.updatedAt!.toLocal())}' : '${user?.xp ?? 0} XP total'),
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ),
                  if (state.isWalletLoading)
                    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
            ),
            if (isDegraded) ...[
              const SizedBox(height: 10),
              _BetaBanner(message: 'Ledger is in beta — history will appear when WO-1 ships. Coins are still credited server-authoritatively via quiz attempts.'),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Text('Ledger', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (state.isLedgerLoading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isDegraded
                  ? 'History unavailable yet — quiz rewards still credit correctly (server ledger).'
                  : 'Grouped by day. Source labels come from credits.description (not metadata.source).',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            if (state.ledgerError != null)
              Card(
                color: AppColors.wrongRed.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.wrongRed),
                      const SizedBox(width: 8),
                      Expanded(child: Text(state.ledgerError!, style: const TextStyle(fontSize: 12, color: AppColors.wrongRed))),
                      TextButton(onPressed: () => ref.read(economyControllerProvider.notifier).fetchLedger(), child: const Text('Retry')),
                    ],
                  ),
                ),
              ),

            if (ledger.isEmpty && !state.isLedgerLoading) ...[
              const SizedBox(height: 8),
              _EmptyLedger(isDegraded: isDegraded),
            ] else ...[
              for (final entry in grouped.entries) ...[
                const SizedBox(height: 14),
                Text(_formatDay(entry.key), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textSecondaryDark)),
                const SizedBox(height: 6),
                ...entry.value.map((e) => _LedgerTile(entry: e)),
              ],
              const SizedBox(height: 8),
              if (isDegraded)
                const Text('Showing local preview — real ledger is append-only on the server and will appear automatically once the endpoint ships.', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            const Text('How you earn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 6),
            const Text('Coins are credited server-authoritatively via EconomyService::debit() and quiz attempt rewards. Flutter never mints locally — do not decrement balance optimistically; invalidate wallet after POST /quiz/attempts/*/finish.', style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Map<String, List<LedgerEntry>> _groupByDay(List<LedgerEntry> entries) {
    final m = <String, List<LedgerEntry>>{};
    for (final e in entries) {
      final k = '${e.createdAt.year.toString().padLeft(4, '0')}-${e.createdAt.month.toString().padLeft(2, '0')}-${e.createdAt.day.toString().padLeft(2, '0')}';
      m.putIfAbsent(k, () => []).add(e);
    }
    return m;
  }

  String _formatDay(String isoDay) {
    try {
      final d = DateTime.parse(isoDay);
      return DateFormat.yMMMMd().format(d);
    } catch (_) {
      return isoDay;
    }
  }
}

class _LedgerTile extends StatelessWidget {
  const _LedgerTile({required this.entry});
  final LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final isCredit = entry.isCredit;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: (isCredit ? AppColors.correctGreen : AppColors.wrongRed).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(isCredit ? Icons.add_rounded : Icons.remove_rounded, size: 16, color: isCredit ? AppColors.correctGreen : AppColors.wrongRed),
        ),
        title: Text(entry.sourceLabel.isEmpty ? entry.description : entry.sourceLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(DateFormat.jm().format(entry.createdAt.toLocal()), style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: Text('${isCredit ? '+' : '-'}${entry.amount}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isCredit ? AppColors.correctGreen : AppColors.wrongRed)),
      ),
    );
  }
}

class _EmptyLedger extends StatelessWidget {
  const _EmptyLedger({required this.isDegraded});
  final bool isDegraded;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4)), borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Icon(Icons.receipt_long_rounded, size: 28, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35)),
          const SizedBox(height: 8),
          Text(isDegraded ? 'Ledger in beta' : 'No transactions yet', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            isDegraded
                ? 'Your coins are safe — they credit on the server after each graded quiz. History appears when GET /economy/wallet/ledger ships (WO-1).'
                : 'Complete a quiz to earn coins. Every credit is server-authoritative.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _BetaBanner extends StatelessWidget {
  const _BetaBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.brand.withValues(alpha: 0.2))),
      child: Row(
        children: [
          const Icon(Icons.science_rounded, size: 16, color: AppColors.brand),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 11, color: AppColors.brandDark, height: 1.3))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(6)), child: const Text('BETA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white))),
        ],
      ),
    );
  }
}
