import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../connectivity/connectivity_service.dart';
import '../logging/app_logger.dart';
import 'sync_queue.dart';

/// Drains offline queue when connectivity returns.
class SyncManager {
  SyncManager({
    required SyncQueueService queue,
    required Dio dio,
    required ConnectivityService connectivity,
    Future<int?> Function()? currentTenant,
  })  : _queue = queue,
        _dio = dio,
        _conn = connectivity,
        _currentTenant = currentTenant ?? (() async => null);

  final SyncQueueService _queue;
  final Dio _dio;
  final ConnectivityService _conn;

  /// The tenant assertion the replayed credential will carry. Defaults to
  /// "unknown" for hermetic tests; the app provider injects the real
  /// [TenantStore.read] so production never replays a row under another org.
  final Future<int?> Function() _currentTenant;
  StreamSubscription<bool>? _sub;
  bool _syncing = false;

  void start() {
    _sub ??= _conn.onOnlineChanged.listen((online) {
      if (online) unawaited(syncNow());
    });
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> syncNow() async {
    if (_syncing) return;
    // Set the guard BEFORE the first await: both real triggers (the 30s timer
    // and the connectivity listener) can call this in the same tick. Checking
    // after `isOnline()` let two drains of the same row race.
    _syncing = true;
    try {
      final online = await _conn.isOnline();
      if (!online) return;
      final items = await _queue.pending();
      final currentTenant = await _currentTenant();
      for (final item in items) {
        // A row minted under another workspace must never be replayed with the
        // current credential: the tenant assertion comes from the credential,
        // so the write would land in the wrong organization. Drop it — it is a
        // durable, not transient, mismatch and retrying cannot fix it.
        if (item.tenantId != null && item.tenantId != currentTenant) {
          AppLogger.w(
            'Dropping sync_queue id=${item.id}: enqueued under tenant '
            '${item.tenantId}, current tenant is $currentTenant',
          );
          await _queue.remove(item.id);
          continue;
        }

        // Re-checked on the way out, not trusted from the row. `enqueue`
        // validates too, but a row written before that rule existed is still on
        // disk, and this path carries the user's bearer token.
        final violation = SyncQueueService.validateEndpoint(item.endpoint);
        if (violation != null) {
          // Dropped rather than retried: a row that must never be replayed is
          // not a transient failure, and retrying it five times would only delay
          // the discovery.
          AppLogger.w(
            'Dropping sync_queue id=${item.id}: endpoint is $violation',
          );
          await _queue.remove(item.id);
          continue;
        }

        try {
          await _dio.request<dynamic>(
            item.endpoint,
            // The body is stored as JSON text, so it has to say so. Dio would
            // otherwise send a String as text/plain and the API would reject an
            // otherwise valid payload.
            data: item.payload == null ? null : jsonDecode(item.payload!),
            options: Options(
              method: item.method,
              headers: <String, dynamic>{
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                if (item.idempotencyKey case final String key)
                  'Idempotency-Key': key,
              },
            ),
          );
          await _queue.remove(item.id);
          AppLogger.i('Synced ${item.endpoint} id=${item.id}');
        } catch (e) {
          AppLogger.w('Sync failed ${item.endpoint}: $e');
          // Backoff so a dead endpoint cannot spin the queue forever.
          await _queue.bump(item.id, item.attempts);
        }
      }
    } finally {
      _syncing = false;
    }
  }
}
