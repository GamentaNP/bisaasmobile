import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../storage/database/app_database.dart';
import '../storage/database/daos/sync_queue_dao.dart';

class SyncQueueService {
  SyncQueueService(this._dao, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();
  final SyncQueueDao _dao;
  final Uuid _uuid;

  /// Enqueues one offline operation.
  ///
  /// [idempotencyKey] is optional: when the *same logical operation* is
  /// retried (e.g. a user re-taps "save"), pass the same key so the unique
  /// constraint on `sync_queue.idempotency_key` dedupes and the server can
  /// dedupe across retries. When omitted, a fresh key is minted per enqueue
  /// (best-effort for fire-once callers).
  ///
  /// ## Why [endpoint] is validated here rather than at drain time
  ///
  /// `SyncManager` replays rows through the *authenticated* Dio, and Dio honours
  /// an absolute URL in place of `baseUrl`. A row whose `endpoint` read
  /// `https://attacker.example/collect` would therefore make this app send the
  /// signed-in user's bearer token to a third party — `AuthInterceptor` attaches
  /// it to every request, and the queue is a table, not a trust boundary.
  ///
  /// Nothing enqueues today (see `unwired_tables_test.dart`), so this is not
  /// reachable right now. It is one line away from being, and the whole point of
  /// an offline queue is that whoever wires it will not read this far down.
  /// Refuse to store a row that could never be replayed safely.
  Future<int> enqueue({
    required String endpoint,
    String method = 'POST',
    String? payload,
    String? idempotencyKey,
  }) {
    final violation = validateEndpoint(endpoint);
    if (violation != null) {
      throw ArgumentError.value(
        endpoint,
        'endpoint',
        'sync queue refuses $violation. Must be a relative path under the API '
            'base, e.g. /calculation-snapshots',
      );
    }

    return _dao.enqueue(
      SyncQueueCompanion(
        endpoint: Value(endpoint),
        method: Value(method.toUpperCase()),
        payload: Value(payload),
        idempotencyKey: Value(idempotencyKey ?? _uuid.v4()),
      ),
    );
  }

  /// Why [endpoint] is not replayable, or null when it is.
  ///
  /// Static so `SyncManager` can re-check a row on the way out: a row written
  /// before this rule existed is still on disk, and validating only at enqueue
  /// would not have caught it.
  static String? validateEndpoint(String endpoint) {
    if (endpoint.isEmpty) return 'an empty endpoint';
    if (endpoint.trim() != endpoint) return 'a path with surrounding whitespace';

    // A scheme, or anything Uri would read as one, means an absolute URL, and
    // Dio replaces `baseUrl` with it.
    if (endpoint.contains('://')) return 'an absolute URL';
    if (Uri.tryParse(endpoint)?.hasScheme ?? false) return 'a URL with a scheme';
    // Protocol-relative: `//evil.example/x` is host-relative to a browser and is
    // read as a host by several URL resolvers.
    if (endpoint.startsWith('//')) return 'a protocol-relative URL';
    // Must be rooted at the API base.
    if (!endpoint.startsWith('/')) return 'a path that is not rooted';
    // Nor able to climb out of it.
    if (endpoint.contains('..')) return 'a path containing traversal';

    return null;
  }

  /// Queues one calculation snapshot for `PUT /api/v1/calculation-snapshots`.
  ///
  /// ## The payload shape is not ours to choose
  ///
  /// `CalculationSnapshotController::sync` validates a **collection**:
  ///
  /// ```json
  /// { "snapshots": [ { "domain": "...", "calculator_slug": "...",
  ///      "input_payload": { ... }, "result_payload": { ... } } ] }
  /// ```
  ///
  /// `snapshots` is required, bounded to 100, `input_payload` and
  /// `result_payload` must both be arrays, and `client_uuid` must be a real UUID
  /// when present. An earlier version of this docblock described a flat
  /// `{domain, slug, inputs, outputs, calculated_at}` object, which the server
  /// has never accepted: it would have 422'd, `bump` would retry and give up,
  /// and the failure would be indistinguishable from the network being down.
  ///
  /// One row carries one snapshot rather than batching to the 100 limit, so a
  /// burst of calculations costs a burst of idempotent PUTs instead of one
  /// body that has to be re-serialised every time another entry arrives.
Future<int> enqueueSnapshot({
    required String domain,
    required Map<String, dynamic> inputs,
    required Map<String, dynamic> result,
    String? calculatorSlug,
    String? clientUuid,
  }) {
    // Built imperatively rather than with collection-if: three of these fields
    // are conditionally *omitted*, and the server rejects the whole batch over
    // one malformed or null value. Being explicit about "absent" is the point.
    final snapshot = <String, dynamic>{
      'domain': domain,
      'input_payload': inputs,
      'result_payload': result,
      // `last_opened_at` is deliberately NOT sent. It is nullable, used only for
      // display ordering, and validated `before_or_equal:now` — so a phone whose
      // clock is even slightly ahead loses the *entire* batch, including the
      // user's inputs and results. Paying a whole-row rejection risk for a
      // display hint is a bad trade, and the server stamps its own clock anyway.
      //
      // Verified: a body carrying it was rejected with "must be a date before or
      // equal to now" while the same body without it validates.
    };
    if (calculatorSlug != null) {
      snapshot['calculator_slug'] = calculatorSlug;
    }
    // Only sent when it really is a UUID, because the server validates it as one
    // and would reject the entire batch over a malformed value.
    if (clientUuid != null && _isUuid(clientUuid)) {
      snapshot['client_uuid'] = clientUuid;
    }

    return enqueue(
      endpoint: '/calculation-snapshots',
      method: 'PUT',
      payload: jsonEncode({
        'snapshots': [snapshot],
      }),
    );
  }

  static final _uuidPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static bool _isUuid(String value) => _uuidPattern.hasMatch(value);

  Future<List<SyncQueueData>> pending() => _dao.pending();
  Future<void> remove(int id) => _dao.remove(id);

  /// Backoff after a failed attempt — linear-ish, capped under the retry limit.
  Future<void> bump(int id, int attempts) =>
      _dao.bump(id, DateTime.now().add(Duration(seconds: 30 * (attempts + 1))));
}
