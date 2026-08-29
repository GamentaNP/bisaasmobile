import 'package:flutter/foundation.dart';

/// Parses `civilcal://` and `https://bisaas.com/*` deep links.
/// Returns router location or null if not handled.
abstract final class DeepLinkHandler {
  static String? parse(Uri uri) {
    // civilcal://reset-password?token=...&email=...
    if (uri.scheme == 'civilcal') {
      if (uri.host == 'reset-password') {
        final token = uri.queryParameters['token'];
        final email = uri.queryParameters['email'];
        if (token != null && email != null) {
          return '/login?reset_token=$token&email=$email';
        }
      }
      if (uri.host == 'quiz' && uri.pathSegments.isNotEmpty) {
        return '/quiz/${uri.pathSegments.first}';
      }
      if (uri.host == 'battle') return '/battle';
    }

    // https://bisaas.com/quiz/<slug> → /quiz/<slug>
    if ((uri.host == 'bisaas.com' || uri.host == 'www.bisaas.com') &&
        uri.pathSegments.isNotEmpty) {
      if (uri.pathSegments.first == 'quiz' && uri.pathSegments.length > 1) {
        return '/quiz/${uri.pathSegments[1]}';
      }
    }

    if (kDebugMode) debugPrint('DeepLink unhandled: $uri');
    return null;
  }
}
