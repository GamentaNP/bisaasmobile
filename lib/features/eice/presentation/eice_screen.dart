import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../data/eice_remote_data_source.dart';
import 'widgets/payload_view.dart';

final eiceRemoteProvider =
    Provider<EiceRemoteDataSource>((ref) => EiceRemoteDataSource(DioClient.instance.dio));

/// Prefer the server's own message — it is written for users ("No active
/// target exam found."), whereas `ApiException.toString()` is not.
///
/// Unwraps the `ApiException` out of a `DioException` too, so this is correct
/// whether or not the call went through `AuthInterceptor`.
String friendlyError(Object e) {
  if (e is ApiException) return e.message;
  if (e is DioException) {
    final inner = e.error;
    if (inner is ApiException) return inner.message;
  }
  return 'Could not load this section. $e';
}

class EiceScreen extends ConsumerWidget {
  const EiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final src = ref.read(eiceRemoteProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Exam Intelligence')),
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
            fetcher: src.getCoach,
          ),
          // Triage has no exam-less route — it needs the numeric exam id that
          // only the coach response carries, so it waits on that.
          _TriageCard(coach: src.getCoach, triage: src.getTriage),
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
        err = friendlyError(e);
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
        err = friendlyError(e);
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
/// Triage needs a numeric exam id, which only the coach response provides, so
/// this card resolves the id first. The coach call is cheap and idempotent, and
/// it keeps the id derivation in one place instead of guessing one.
class _TriageCard extends StatefulWidget {
  const _TriageCard({required this.coach, required this.triage});
  final Future<Map<String, dynamic>?> Function() coach;
  final Future<Map<String, dynamic>?> Function(int examId) triage;

  @override
  State<_TriageCard> createState() => _TriageCardState();
}

class _TriageCardState extends State<_TriageCard> {
  Map<String, dynamic>? data;
  bool loading = false;
  String? err;

  Future<void> _load() async {
    setState(() {
      loading = true;
      err = null;
    });
    try {
      final coach = await widget.coach();
      final examId = _examIdOf(coach);
      if (examId == null) {
        if (!mounted) return;
        setState(() {
          data = null;
          loading = false;
          err = coach == null
              ? 'Nothing to show for this section yet.'
              : 'No target exam set up yet, so there is nothing to triage.';
        });
        return;
      }
      final res = await widget.triage(examId);
      if (!mounted) return;
      setState(() {
        data = res;
        loading = false;
        if (res == null) err = 'Nothing to show for this section yet.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        data = null;
        loading = false;
        err = friendlyError(e);
      });
    }
  }

  /// `exam_id` is the server's own field on the coach payload.
  static int? _examIdOf(Map<String, dynamic>? coach) {
    if (coach == null) return null;
    final raw = coach['exam_id'] ?? coach['examId'];
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw);
    return null;
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
              'Triage — cover or skip',
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
