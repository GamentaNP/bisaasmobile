import 'notification_types.dart';

abstract final class NotificationHandler {
  static String routeFor(Map<String, dynamic> data) {
    final type = NotificationType.fromRaw(data['type'] as String?);
    return switch (type) {
      NotificationType.quizReminder => '/quiz',
      NotificationType.battleInvite => '/battle',
      NotificationType.achievementUnlocked => '/profile',
      _ => '/home',
    };
  }
}
