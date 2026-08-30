import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/economy.dart';

/// Ledger grouped by day — reusable widget for WalletScreen.
class WalletLedgerGroup extends StatelessWidget {
  const WalletLedgerGroup({super.key, required this.entries, this.isDegraded = false});
  final List<LedgerEntry> entries;
  final bool isDegraded;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35)), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [Icon(Icons.receipt_long_rounded, size: 24, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35)), const SizedBox(height: 8), Text(isDegraded ? 'Ledger in beta' : 'No transactions', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)), const SizedBox(height: 4), Text(isDegraded ? 'History appears when WO-1 ships.' : 'Complete a quiz to earn coins.', style: const TextStyle(fontSize: 11, color: Colors.grey))]),
      );
    }
    final grouped = _groupByDay(entries);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in grouped.entries) ...[
          const SizedBox(height: 10),
          Text(_fmtDay(e.key), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.textSecondaryDark)),
          const SizedBox(height: 6),
          ...e.value.map((l) => Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  dense: true,
                  leading: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: (l.isCredit ? AppColors.correctGreen : AppColors.wrongRed).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Icon(l.isCredit ? Icons.add_rounded : Icons.remove_rounded, size: 14, color: l.isCredit ? AppColors.correctGreen : AppColors.wrongRed)),
                  title: Text(l.sourceLabel.isEmpty ? l.description : l.sourceLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(DateFormat.jm().format(l.createdAt.toLocal()), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  trailing: Text('${l.isCredit ? '+' : '-'}${l.amount}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: l.isCredit ? AppColors.correctGreen : AppColors.wrongRed)),
                ),
              )),
        ],
      ],
    );
  }

  Map<String, List<LedgerEntry>> _groupByDay(List<LedgerEntry> list) {
    final m = <String, List<LedgerEntry>>{};
    for (final e in list) {
      final k = '${e.createdAt.year.toString().padLeft(4, '0')}-${e.createdAt.month.toString().padLeft(2, '0')}-${e.createdAt.day.toString().padLeft(2, '0')}';
      m.putIfAbsent(k, () => []).add(e);
    }
    return m;
  }

  String _fmtDay(String iso) {
    try {
      return DateFormat.yMMMMd().format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}
