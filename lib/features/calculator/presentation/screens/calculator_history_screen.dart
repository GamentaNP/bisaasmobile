import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/calculator_controller.dart';

/// Calculator history, served by `GET /api/v1/calculators/{domain}/{slug}/history`.
///
/// The docblock here used to claim this read the Drift `calculations` table and
/// that the server route "will be wired in when ready". Both were wrong: the
/// controller has always called the server, and the `calculations` table has
/// never been written by any code path. The table is one of five that exist in
/// the schema with no producer — see
/// `test/core/storage/unwired_tables_test.dart`, which records why each one is
/// empty and, for the attempt tables, why filling it would be wrong.
class CalculatorHistoryScreen extends ConsumerStatefulWidget {
  const CalculatorHistoryScreen({required this.domain, required this.slug, super.key});
  final String domain;
  final String slug;

  @override
  ConsumerState<CalculatorHistoryScreen> createState() => _CalculatorHistoryScreenState();
}

class _CalculatorHistoryScreenState extends ConsumerState<CalculatorHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(calculatorControllerProvider.notifier).loadHistory(widget.domain, widget.slug));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calculatorControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.slug.replaceAll('-', ' ')} · history'),
      ),
      body: state.historyLoading
          ? const Center(child: CircularProgressIndicator())
          : state.history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.history_rounded, size: 56, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No saved calculations yet', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final entry = state.history[i];
                    return Card(
                      child: ListTile(
                        title: Text(entry.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          const JsonEncoder.withIndent('  ').convert(entry.data),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                        ),
                        trailing: Text(_fmt(entry.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textTertiaryDark)),
                      ),
                    );
                  },
                ),
    );
  }

  static String _fmt(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }
}
