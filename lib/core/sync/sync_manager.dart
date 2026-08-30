import 'dart:async';

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
        try {
          await _dio.request<dynamic>(
            item.endpoint,
            data: item.payload,
            options: Options(
              method: item.method,
              headers: {
                if (item.idempotencyKey case final String key) 'Idempotency-Key': key,
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
