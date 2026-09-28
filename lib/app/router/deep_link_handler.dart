import 'package:flutter/foundation.dart';

/// Parses `civilcal://` and `https://bisaas.com/*` deep links.
/// Returns router location or null if not handled.
abstract final class DeepLinkHandler {
  static const appHosts = {'bisaas.com', 'www.bisaas.com'};

  static String? parse(Uri uri) {
    // civilcal://reset-password?token=...&email=...
    if (uri.scheme == 'civilcal') {
      if (uri.host == 'reset-password') {
        // Query-parameter form: civilcal://reset-password?token=…&email=…
        return _resetPasswordLocation(
          token: uri.queryParameters['token'],
          email: uri.queryParameters['email'],
        );
      }
      if (uri.host == 'quiz' && uri.pathSegments.isNotEmpty) {
        return '/quiz/${uri.pathSegments.first}';
      }
      if (uri.host == 'battle') return '/battle';
    }

    // https://bisaas.com/* app links.
    if (appHosts.contains(uri.host) && uri.pathSegments.isNotEmpty) {
      if (uri.pathSegments.first == 'quiz' && uri.pathSegments.length > 1) {
        return '/quiz/${uri.pathSegments[1]}';
      }

      // The link the password-reset email actually contains is the Fortify web
      // route, `/reset-password/{token}?email=…`, so the token arrives as a PATH
      // SEGMENT here — not a query parameter like the civilcal:// form. Missing
      // this shape means a reset link tapped on a phone opens the browser (or,
      // once App Links verify, lands on an unhandled route) and the in-app
      // completion screen is unreachable from the one place users need it.
      if (uri.pathSegments.first == 'reset-password') {
        final email = uri.queryParameters['email'];
        final token = uri.pathSegments.length > 1
            ? uri.pathSegments[1]
            : uri.queryParameters['token'];
        return _resetPasswordLocation(token: token, email: email);
      }
    }

    if (kDebugMode) debugPrint('DeepLink unhandled: $uri');
    return null;
  }

  /// Builds the in-app reset location, omitting absent or empty parameters.
  ///
  /// Shared by both link shapes so the query encoding cannot drift between
  /// them. A blank token is still routed (rather than swallowed) so the screen
  /// can explain that the link is incomplete and offer a fresh one — silently
  /// returning null would drop the user back to an unrelated screen.
  static String _resetPasswordLocation({String? token, String? email}) {
    final params = <String, String>{
      if (token != null && token.isNotEmpty) 'token': token,
      if (email != null && email.isNotEmpty) 'email': email,
    };
    if (params.isEmpty) return '/reset-password';
    final qs = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return '/reset-password?$qs';
  }
}
