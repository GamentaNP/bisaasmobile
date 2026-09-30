import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_config.dart';
import '../../../app/providers.dart';
import '../../../core/network/api_exception.dart';

/// Whether a corpus is worth offering as an entry point.
///
/// ## Why this exists
///
/// The client faithfully renders whatever the server exposes, which is correct
/// right up until the server has nothing to expose. The Book Engine has eight
/// rollout flags, all off, and zero ingested books, so the Books tile led to a
/// reader that could only ever say "No books have been published yet." A tab
/// that looks live and is empty reads as a broken app, not a minimal one, and
/// it is worse than not offering it at all.
///
/// So a corpus is offered only when the operator's config says it is on **and**
/// the server actually has content for it. Both halves matter:
///
///   * Config-only would ship the tile during a rollout window with no content.
///   * Content-only would keep showing the tile after the operator deliberately
///     turned the feature off.
///
/// ## Why this defaults to showing the feature
///
/// If the config fetch fails, or the corpus probe errors, the corpus stays
/// visible. Refusing to render a working feature because a *probe* failed would
/// turn a transient outage into a missing feature, which is the failure mode
/// this whole class is trying to avoid.
enum CorpusAvailability { available, empty, unknown }

/// Result of probing one corpus, so tiles can explain themselves.
class CorpusStatus {
  const CorpusStatus({
    required this.code,
    required this.availability,
    this.count,
  });

  /// Stable identifier used by callers and tests, e.g. `library`, `books`.
  final String code;
  final CorpusAvailability availability;

  /// Number of items, when the server reported one.
  final int? count;

  bool get isOffered => availability != CorpusAvailability.empty;

  @override
  String toString() =>
      'CorpusStatus($code, ${availability.name}, count: $count)';
}

/// Which corpora the operator has switched on, per `GET /api/v1/app/config`.
///
/// The server does not publish `book_engine` here today, so a corpus that is
/// absent from the payload is treated as **not enabled**. Defaulting the other
/// way would re-introduce the exact bug this file exists to prevent: a flag the
/// client has never heard of silently enabling a surface.
final corpusFeatureEnabledProvider = Provider.family<bool, String>((ref, code) {
  final config = ref.watch(appConfigValueProvider);
  return _enabled(config, code);
});

bool _enabled(AppConfig? config, String code) {
  // `config == null` means the fetch has not resolved or failed. We cannot
  // prove the feature is off, and we must not hide a working feature because a
  // probe failed, so an unknown config leaves the corpus visible.
  if (config == null) return true;
  return switch (code) {
    'library' => config.flag('library_enabled', defaultValue: true),
    'books' => config.flag('book_engine', defaultValue: false),
    'syllabus' => config.flag('syllabus_enabled', defaultValue: true),
    _ => true,
  };
}

/// Probes whether a corpus has content, so we never ship an empty reader.
final corpusStatusProvider = FutureProvider.family<CorpusStatus, String>((
  ref,
  code,
) async {
  if (!_enabled(ref.watch(appConfigValueProvider), code)) {
    return CorpusStatus(code: code, availability: CorpusAvailability.empty);
  }
  try {
    final count = await ref.watch(_corpusCountProvider(code).future);
    return CorpusStatus(
      code: code,
      availability: count == 0
          ? CorpusAvailability.empty
          : CorpusAvailability.available,
      count: count,
    );
  } on ApiException catch (e) {
    // A 401 means the user is signed out, not that the corpus is empty. Hiding
    // Library because the user has not logged in yet would be wrong.
    if (e.statusCode == 401) {
      return const CorpusStatus(
        code: '',
        availability: CorpusAvailability.unknown,
      );
    }
    return CorpusStatus(code: code, availability: CorpusAvailability.unknown);
  } on Object {
    return CorpusStatus(code: code, availability: CorpusAvailability.unknown);
  }
});

final _corpusCountProvider = FutureProvider.family<int, String>((ref, code) {
  final dio = ref.watch(dioProvider);
  return switch (code) {
    'library' => _count(
      dio.get<Map<String, dynamic>>('/library/files?per_page=1'),
    ),
    'books' => _count(dio.get<Map<String, dynamic>>('/books?per_page=1')),
    'syllabus' => _count(dio.get<Map<String, dynamic>>('/syllabi?per_page=1')),
    _ => throw ArgumentError('Unknown corpus: $code'),
  };
});

/// Reads a count from either a top-level `total`, a `meta.total`, or the length
/// of `data`, because the three corpora serialise pagination differently.
Future<int> _count(Future<Response<Map<String, dynamic>>> request) async {
  final response = await request;
  final body = response.data;
  if (body == null) return 0;
  final data = body['data'];
  final meta = body['meta'];
  if (meta is Map && meta['total'] is num)
    return (meta['total'] as num).toInt();
  if (body['total'] is num) return (body['total'] as num).toInt();
  if (data is List) return data.length;
  if (data is Map) {
    if (data['total'] is num) return (data['total'] as num).toInt();
    for (final key in const ['files', 'books', 'syllabi', 'items', 'results']) {
      if (data[key] is List) return (data[key] as List).length;
    }
  }
  return 0;
}
