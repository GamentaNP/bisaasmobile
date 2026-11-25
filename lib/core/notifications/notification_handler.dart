import 'notification_types.dart';

abstract final class NotificationHandler {
  /// FCM `data` is untrusted input: any party able to send a data message to
  /// this app could otherwise open `/reset-password?token=…&email=…` inside a
  /// trusted first-party UI. Only a fixed set of surfaces is reachable, and a
  /// payload carrying credentials is refused outright.
  static const _allowedRoots = <String>{
    '/home',
    '/quiz',
    '/practice',
    '/learning',
    '/calculator',
    '/calculators',
    '/courses',
    '/library',
    '/battle',
    '/arcade',
    '/contests',
    '/leaderboard',
    '/live-events',
    '/social',
    '/notifications',
    '/downloads',
    '/profile',
    '/settings',
    '/organization',
    '/ai-usage',
    '/ai-keys',
    '/achievements',
    '/tutor',
    '/coaching',
    '/economy',
    '/store',
    '/wardrobe',
    '/streak',
    '/rewards',
    '/privacy',
    '/books',
    '/numericals',
    '/syllabus',
    '/search',
    '/game',
  };

  static const _blockedQueryKeys = <String>{
    'token',
    'email',
    'password',
    'secret',
    'code',
    'otp',
    'id_token',
    'access_token',
    'reset_token',
  };

  static const _allowedHosts = <String>{'lovemcq.com', 'www.lovemcq.com'};

  /// Returns a validated router target, or null when [raw] must be ignored.
  static String? safeRoute(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;

    final scheme = uri.scheme.toLowerCase();
    final String path;
    if (scheme.isEmpty) {
      if (!raw.startsWith('/')) return null;
      path = uri.path;
    } else if (scheme == 'civilcal') {
      final host = uri.host.toLowerCase();
      if (host.isEmpty) return null;
      path = '/$host${uri.path}';
    } else if (scheme == 'https' &&
        _allowedHosts.contains(uri.host.toLowerCase())) {
      path = uri.path.isEmpty ? '/home' : uri.path;
    } else {
      // `http`, unknown schemes and foreign hosts are never navigated to.
      return null;
    }

    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;
    final root = '/${segments.first}';
    if (!_allowedRoots.contains(root)) return null;
    if (uri.queryParameters.keys
        .any((k) => _blockedQueryKeys.contains(k.toLowerCase()))) {
      return null;
    }
    if (uri.fragment.isNotEmpty) return null;

    // Scheme links are returned verbatim so the deep-link handler can map
    // them; plain locations are rebuilt from the validated path and query.
    if (scheme.isNotEmpty) return raw;
    return uri.hasQuery ? '$path?${uri.query}' : path;
  }

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
