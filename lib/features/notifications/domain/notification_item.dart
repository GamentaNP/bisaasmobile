import 'package:flutter/foundation.dart';

/// One row of `GET /api/v1/notifications`.
///
/// Server shape (`NotificationController::$mapNotification`):
/// `{id, type, data: {title, body, ...}, read_at, created_at}`.
///
/// `readAt` is the server's own signal, not a locally-guessed one: the unread
/// badge in `GET /me` is computed from the same column, so deriving the
/// indicator from it keeps the inbox and the badge from disagreeing.
@immutable
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final DateTime? createdAt;
  final DateTime? readAt;

  bool get isUnread => readAt == null;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final payload = data is Map<String, dynamic> ? data : const <String, dynamic>{};

    DateTime? parse(Object? v) =>
        v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;

    return NotificationItem(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      // Title/body live inside `data` on this endpoint. The top-level fallbacks
      // keep an older/alternate shape readable rather than rendering blanks.
      title: (payload['title'] ?? json['title'] ?? 'Notification').toString(),
      body: (payload['body'] ?? json['body'] ?? '').toString(),
      createdAt: parse(json['created_at']),
      readAt: parse(json['read_at']),
    );
  }

  NotificationItem copyWith({DateTime? readAt, bool markRead = false}) {
    return NotificationItem(
      id: id,
      type: type,
      title: title,
      body: body,
      createdAt: createdAt,
      readAt: markRead ? DateTime.now() : readAt,
    );
  }
}
