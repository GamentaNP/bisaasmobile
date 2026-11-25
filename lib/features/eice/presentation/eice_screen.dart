import '../../../l10n/app_localizations.dart';
import '../../../app/localization/l10n.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/providers/eice_providers.dart';
import '../domain/entities/eice_data.dart';
import 'widgets/payload_view.dart';

// Kept at its old location: widget tests override the data source through
// this name, and the repository provider watches the same instance.
export '../data/providers/eice_providers.dart' show eiceRemoteProvider;

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
  return appL10n().eiceSectionFailed(e);
}

class EiceScreen extends ConsumerWidget {
  const EiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.watch(eiceRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.eiceTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.eiceExplain,
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          _Card(
            title: l10n.eiceCoach,
            fetcher: repo.getCoach,
          ),
          // Triage has no exam-less route - it needs the numeric exam id that
          // only the coach response carries, so it waits on that.
          _TriageCard(coach: repo.getCoach, triage: repo.getTriage),
          _CardList(
            title: l10n.eiceSprint,
            fetcher: repo.getSprint,
          ),
          _Card(
            title: l10n.eiceWeeklyReport,
            fetcher: repo.getWeekly,
          ),
        ],
      ),
    );
  }
}

class _Card extends StatefulWidget {
  const _Card({required this.title, required this.fetcher});
  final String title;
  final Future<EicePayload?> Function() fetcher;

  @override
  State<_Card> createState() => _CardState();
}

class _CardState extends State<_Card> {
  EicePayload? data;
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
    final l10n = AppLocalizations.of(context)!;
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
                    label: Text(l10n.retry),
                  ),
                ],
              ),
            if (!loading && err == null && data != null)
              PayloadView(data: data?.raw),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: loading ? null : _load,
                child: Text(l10n.streakRefresh),
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
  final Future<List<EicePayload>> Function() fetcher;

  @override
  State<_CardList> createState() => _CardListState();
}

class _CardListState extends State<_CardList> {
  List<EicePayload> items = [];
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
    final l10n = AppLocalizations.of(context)!;
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
                    label: Text(l10n.retry),
                  ),
                ],
              ),
            if (err == null && !loading && items.isNotEmpty)
              PayloadView(data: items.map((e) => e.raw).toList()),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: loading ? null : _load,
                child: Text(l10n.streakRefresh),
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
  final Future<EicePayload?> Function() coach;
  final Future<EicePayload?> Function(int examId) triage;

  @override
  State<_TriageCard> createState() => _TriageCardState();
}

class _TriageCardState extends State<_TriageCard> {
  EicePayload? data;
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

  /// `exam_id` is the server's own field on the coach payload; reading it is
  /// now the entity's job rather than an ad-hoc map lookup in the widget.
  static int? _examIdOf(EicePayload? coach) => coach?.examId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.eiceTriage,
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
                    label: Text(l10n.retry),
                  ),
                ],
              ),
            if (!loading && err == null && data != null)
              PayloadView(data: data?.raw),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: loading ? null : _load,
                child: Text(l10n.streakRefresh),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
