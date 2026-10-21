import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/economy_controller.dart';
import '../../domain/entities/economy.dart';
import '../../../../l10n/app_localizations.dart';

/// Wallet — balance headline + ledger grouped by day.
///
/// Balance is server-authoritative: `GET /economy/wallet` first, falling back
/// to the balance `GET /me` carries. The ledger is `GET /economy/wallet/ledger`,
/// which is cursor-paginated — the screen walks it with the server's
/// `next_cursor`.
///
/// Flutter never mints, never decrements locally. Ledger renders
/// credits.description as source label (not metadata->source) per
/// bisaas/AGENTS.md:155.
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
      ref.read(economyControllerProvider.notifier).fetchWalletCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(economyControllerProvider);
    final user = ref.watch(authControllerProvider).value;
    final theme = Theme.of(context);
    // Balance: prefer wallet DTO when available, else coalesce from GET /me.
    final walletCoins = state.wallet?.coins;
    final fallbackCoins = user?.coins ?? 0;
    final balance = walletCoins ?? fallbackCoins;
    final ledger = state.ledger;

    final grouped = _groupByDay(ledger);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.commonWallet)),
      body: RefreshIndicator(
        onRefresh: () => Future.wait([
          ref.read(economyControllerProvider.notifier).fetchWallet(),
          ref.read(economyControllerProvider.notifier).fetchLedger(),
          ref.read(economyControllerProvider.notifier).fetchWalletCategories(),
        ]),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // A failed wallet read must say so. The balance below falls back
            // to the `GET /me` figure, which may be stale — without this the
            // user sees a number with no idea it could be out of date.
            if (state.walletError != null) ...[
              _ErrorCard(
                message: state.walletError!,
                onRetry: () =>
                    ref.read(economyControllerProvider.notifier).fetchWallet(),
              ),
              const SizedBox(height: 10),
            ],
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
                        Text(l10n.coinsBalance(balance), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.coinYellow)),
                        const SizedBox(height: 2),
                        Text(
                          state.isWalletLoading ? l10n.economySyncing : (state.wallet?.updatedAt != null ? 'Updated ${DateFormat.yMMMd().add_jm().format(state.wallet!.updatedAt!.toLocal())}' : '${user?.xp ?? 0} XP total'),
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
            const SizedBox(height: 18),
            Row(
              children: [
                Text(l10n.economyLedger, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (state.isLedgerLoading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.economyLedgerExplain,
              style: TextStyle(fontSize: 11, color: Colors.grey),
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
                      TextButton(onPressed: () => ref.read(economyControllerProvider.notifier).fetchLedger(), child: Text(l10n.retry)),
                    ],
                  ),
                ),
              ),

            if (ledger.isEmpty && !state.isLedgerLoading && state.ledgerError == null) ...[
              const SizedBox(height: 8),
              const _EmptyLedger(),
            ] else ...[
              for (final entry in grouped.entries) ...[
                const SizedBox(height: 14),
                Text(_formatDay(entry.key), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textSecondaryDark)),
                const SizedBox(height: 6),
                ...entry.value.map((e) => _LedgerTile(entry: e)),
              ],
              // The ledger is cursor-paginated, so "next" is the server's
              // `next_cursor` rather than a page number.
              if (state.ledgerHasMore)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: OutlinedButton.icon(
                    onPressed: state.isLedgerLoading
                        ? null
                        : () => ref.read(economyControllerProvider.notifier).fetchLedger(cursor: state.ledgerCursor, append: true),
                    icon: const Icon(Icons.expand_more_rounded),
                    label: Text(l10n.commonLoadMore),
                  ),
                ),
            ],

            // ── Own spending by category ─────────────────────────────────────
            // A failed categories read must not make the whole section
            // disappear: the user would conclude they spent nothing.
            if (state.categoriesError != null) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Text(l10n.economyWhereCoinsWent,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _ErrorCard(
                message: state.categoriesError!,
                onRetry: () => ref
                    .read(economyControllerProvider.notifier)
                    .fetchWalletCategories(),
              ),
            ] else if (state.walletCategories != null) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Text(l10n.economyWhereCoinsWent, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                l10n.economyPeriodSummary(state.walletCategories!.periodDays, state.walletCategories!.earned, state.walletCategories!.spentAbsolute),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              if (state.walletCategories!.categories.isEmpty)
                Text(l10n.economyNoActivity, style: TextStyle(fontSize: 11, color: Colors.grey))
              else
                ...state.walletCategories!.categories.map((c) => _CategoryTile(category: c)),
            ],

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            Text(l10n.economyHowYouEarn, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 6),
            Text(l10n.economyMintingExplain, style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4)),
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

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.wrongRedBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.wrongRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 16, color: AppColors.wrongRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: AppColors.wrongRed),
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(l10n.retry)),
        ],
      ),
    );
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
  const _EmptyLedger();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4)), borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Icon(Icons.receipt_long_rounded, size: 28, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35)),
          const SizedBox(height: 8),
          Text(l10n.economyNoTransactions, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            l10n.economyNoTransactionsBody,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// One row of the "where your coins went" breakdown.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});
  final WalletCategory category;

  @override
  Widget build(BuildContext context) {
    final spending = category.isSpending;
    final color = spending ? AppColors.wrongRed : AppColors.correctGreen;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              category.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Text('${category.entries}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(width: 10),
          Text(
            '${spending ? '-' : '+'}${category.coins.abs()}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
