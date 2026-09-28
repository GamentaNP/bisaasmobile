import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/notification_item.dart';

/// Remote calls for the notification inbox.
///
/// Surfaces, all live on the server but previously uncalled by the app:
///   GET  /notifications
///   PUT  /notifications/{id}/read
///   PUT  /notifications/read-all
class NotificationsRemoteDataSource {
  const NotificationsRemoteDataSource(this._dio);
  final DioClient _dio;

  Future<List<NotificationItem>> fetch() async {
    final res = await _dio.dio.get<Map<String, dynamic>>('/notifications');
    final body = res.data;
    if (body == null) return const [];

    final data = body['data'];
    // The endpoint returns a cursor envelope `{items: [...], pagination}` by
    // default, but honours `?pagination=offset` which returns a bare list.
    if (data is Map<String, dynamic>) {
      final items = data['items'];
      if (items is List) {
        return items
            .whereType<Map<String, dynamic>>()
            .map(NotificationItem.fromJson)
            .toList();
      }
      return const [];
    }
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(NotificationItem.fromJson)
          .toList();
    }
    final env = ApiResponse.fromJson(
      body,
      (j) => (j as List?)?.whereType<Map<String, dynamic>>().toList() ?? <NotificationItem>[],
    );
    return (env.data ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(NotificationItem.fromJson)
        .toList();
  }

  /// Returns true only when the server accepted the transition.
  Future<void> markRead(String id) async {
    await _dio.dio.put<void>('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _dio.dio.put<void>('/notifications/read-all');
  }
}

final notificationsRemoteProvider = Provider<NotificationsRemoteDataSource>(
  (ref) => NotificationsRemoteDataSource(DioClient.instance),
);

/// Owns the inbox so a read/unread change can be applied optimistically and
/// rolled back if the server refuses it.
class NotificationsController extends AsyncNotifier<List<NotificationItem>> {
  @override
  Future<List<NotificationItem>> build() =>
      ref.watch(notificationsRemoteProvider).fetch();

  /// Marks one notification read. The row updates immediately because the user
  /// has already acted, then reverts if the call fails — a silent no-op would
  /// leave the badge on `GET /me` stuck while the inbox claims otherwise.
  Future<void> markRead(String id) async {
    final before = state.value;
    if (before == null) return;
    if (!before.any((n) => n.id == id && n.isUnread)) return;

    state = AsyncData([
      for (final n in before)
        if (n.id == id) n.copyWith(markRead: true) else n,
    ]);

    try {
      await ref.read(notificationsRemoteProvider).markRead(id);
    } on Object catch (e, st) {
      state = AsyncData(before);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> markAllRead() async {
    final before = state.value;
    if (before == null) return;
    if (!before.any((n) => n.isUnread)) return;

    state = AsyncData([for (final n in before) n.copyWith(markRead: true)]);

    try {
      await ref.read(notificationsRemoteProvider).markAllRead();
    } on Object catch (e, st) {
      state = AsyncData(before);
      Error.throwWithStackTrace(e, st);
    }
  }
}

final notificationsControllerProvider =
    AsyncNotifierProvider<NotificationsController, List<NotificationItem>>(
  NotificationsController.new,
);
