import 'package:flutter/foundation.dart';

/// Parses `civilcal://` and `https://bisaas.com/*` deep links.
/// Returns router location or null if not handled.
abstract final class DeepLinkHandler {
  static const appHosts = {'bisaas.com', 'www.bisaas.com'};

  static String? parse(Uri uri) {
    // civilcal://reset-password?token=...&email=...
    if (uri.scheme == 'civilcal') {
      if (uri.host == 'reset-password') {
        final email = uri.queryParameters['email'];
        if (email != null) {
          // Password reset completes via the forgot-password flow — carry
          // the email so the user doesn't retype it.
          return '/forgot-password?email=${Uri.encodeComponent(email)}';
        }
        return '/forgot-password';
      }
      if (uri.host == 'quiz' && uri.pathSegments.isNotEmpty) {
        return '/quiz/${uri.pathSegments.first}';
      }
      if (uri.host == 'battle') return '/battle';
    }

    // https://bisaas.com/quiz/<slug> → /quiz/<slug>
    if (appHosts.contains(uri.host) && uri.pathSegments.isNotEmpty) {
      if (uri.pathSegments.first == 'quiz' && uri.pathSegments.length > 1) {
        return '/quiz/${uri.pathSegments[1]}';
      }
    }

    if (kDebugMode) debugPrint('DeepLink unhandled: $uri');
    return null;
  }
}
