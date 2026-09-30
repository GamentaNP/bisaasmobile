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
  })  : _queue = queue,
        _dio = dio,
        _conn = connectivity;

  final SyncQueueService _queue;
  final Dio _dio;
  final ConnectivityService _conn;
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
    final online = await _conn.isOnline();
    if (!online) return;
    _syncing = true;
    try {
      final items = await _queue.pending();
      for (final item in items) {
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
