// ignore_for_file: avoid_dynamic_calls

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/eice_remote_data_source.dart';

final eiceRemoteProvider = Provider<EiceRemoteDataSource>((ref) => EiceRemoteDataSource(DioClient.instance.dio));

class EiceScreen extends ConsumerWidget {
  const EiceScreen({super.key, this.exam = 'psc-civil'});
  final String exam;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Exam Intelligence — $exam')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Server-authoritative EICE: coach, triage, sprint (SM-2), weekly, calibration. Offline is read-only.',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          _Card(
            title: 'Coach (mode-aware plan)',
            endpoint: 'GET /quiz/study-planner/$exam/coach',
            fetcher: () => ref.read(eiceRemoteProvider).getCoach(exam),
          ),
          _Card(title: 'Triage (cover vs skip)', endpoint: 'GET /quiz/study-planner/$exam/triage', fetcher: () => ref.read(eiceRemoteProvider).getTriage(exam)),
          _CardList(title: 'Sprint — 7-day recall queue', endpoint: 'GET /quiz/sprint', fetcher: () => ref.read(eiceRemoteProvider).getSprint()),
          _Card(title: 'Weekly Report', endpoint: 'GET /quiz/reports/weekly', fetcher: () => ref.read(eiceRemoteProvider).getWeekly()),
        ],
      ),
    );
  }
}

class _Card extends StatefulWidget {
  const _Card({required this.title, required this.endpoint, required this.fetcher});
  final String title;
  final String endpoint;
  final Future<Map<String, dynamic>?> Function() fetcher;
  @override
  State<_Card> createState() => _CardState();
}

class _CardState extends State<_Card> {
  Map<String, dynamic>? data;
  bool loading = false;
  String? err;
  Future<void> _load() async {
    setState(() { loading = true; err = null; });
    final res = await widget.fetcher();
    if (!mounted) return;
    setState(() { data = res; loading = false; if (res == null) err = 'No data (backend 404 or offline)'; });
  }
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => _load()); }
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(widget.endpoint, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 8),
          if (loading) const LinearProgressIndicator(),
          if (err != null) Text(err!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          if (data != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
              child: Text(data.toString(), style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
            ),
          ],
          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _load, child: const Text('Refresh'))),
        ]),
      ),
    );
  }
}

class _CardList extends StatefulWidget {
  const _CardList({required this.title, required this.endpoint, required this.fetcher});
  final String title;
  final String endpoint;
  final Future<List<Map<String, dynamic>>> Function() fetcher;
  @override
  State<_CardList> createState() => _CardListState();
}

class _CardListState extends State<_CardList> {
  List<Map<String, dynamic>> items = [];
  bool loading = false;
  Future<void> _load() async { setState(() => loading = true); final res = await widget.fetcher(); if (!mounted) return; setState(() { items = res; loading = false; }); }
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => _load()); }
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(widget.endpoint, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 8),
          if (loading) const LinearProgressIndicator(),
          if (items.isEmpty && !loading) const Text('No items', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ...items.take(3).map((m) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [const Icon(Icons.quiz_rounded, size: 14), const SizedBox(width: 6), Expanded(child: Text((m['question_id'] ?? m['id']?.toString() ?? m.toString()).toString(), style: const TextStyle(fontSize: 12)))]))),
          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _load, child: const Text('Refresh'))),
        ]),
      ),
    );
  }
}
