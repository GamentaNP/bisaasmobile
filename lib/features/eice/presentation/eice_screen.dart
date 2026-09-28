import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/eice_remote_data_source.dart';
import 'widgets/payload_view.dart';

final eiceRemoteProvider =
    Provider<EiceRemoteDataSource>((ref) => EiceRemoteDataSource(DioClient.instance.dio));

class EiceScreen extends ConsumerWidget {
  const EiceScreen({super.key, required this.exam});
  final String exam;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final src = ref.read(eiceRemoteProvider);
    return Scaffold(
      appBar: AppBar(title: Text('Exam Intelligence — $exam')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Everything here is worked out on our servers from your real answer '
            'history, so nothing is shown unless it is true.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          _Card(
            title: 'Coach — your plan',
            fetcher: () => src.getCoach(exam),
          ),
          _Card(
            title: 'Triage — cover or skip',
            fetcher: () => src.getTriage(exam),
          ),
          _CardList(
            title: 'Sprint — 7-day recall queue',
            fetcher: src.getSprint,
          ),
          _Card(
            title: 'Weekly report',
            fetcher: src.getWeekly,
          ),
        ],
      ),
    );
  }
}

class _Card extends StatefulWidget {
  const _Card({required this.title, required this.fetcher});
  final String title;
  final Future<Map<String, dynamic>?> Function() fetcher;

  @override
  State<_Card> createState() => _CardState();
}

class _CardState extends State<_Card> {
  Map<String, dynamic>? data;
  bool loading = false;
  String? err;

  Future<void> _load() async {
    setState(() {
      loading = true;
      err = null;
    });
    try {
      final res = await widget.fetcher();
      if (!mounted) return;
      setState(() {
        data = res;
        loading = false;
        // The data source now propagates failures rather than returning null,
        // so a null here means the server genuinely sent no payload.
        if (res == null) err = 'Nothing to show for this section yet.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        data = null;
        loading = false;
        err = 'Could not load this section. $e';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (loading) const LinearProgressIndicator(),
            if (err != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    err!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            if (!loading && err == null && data != null)
              PayloadView(data: data),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: loading ? null : _load,
                child: const Text('Refresh'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardList extends StatefulWidget {
  const _CardList({required this.title, required this.fetcher});
  final String title;
  final Future<List<Map<String, dynamic>>> Function() fetcher;

  @override
  State<_CardList> createState() => _CardListState();
}

class _CardListState extends State<_CardList> {
  List<Map<String, dynamic>> items = [];
  bool loading = false;
  String? err;

  Future<void> _load() async {
    setState(() {
      loading = true;
      err = null;
    });
    try {
      final res = await widget.fetcher();
      if (!mounted) return;
      setState(() {
        items = res;
        loading = false;
        if (res.isEmpty) err = 'No items in your recall queue yet.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        items = [];
        loading = false;
        err = 'Could not load your recall queue. $e';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (loading) const LinearProgressIndicator(),
            if (err != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    err!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            if (err == null && !loading && items.isNotEmpty)
              PayloadView(data: items),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: loading ? null : _load,
                child: const Text('Refresh'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
