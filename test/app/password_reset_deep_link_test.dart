import 'package:bisaasmobile/app/router/deep_link_handler.dart';
import 'package:bisaasmobile/features/auth/domain/password_policy.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression cover for a user-blocking defect: the password-reset email
/// carried a one-time token that the app threw away.
///
/// `civilcal://reset-password?token=…&email=…` was routed to
/// `/forgot-password`, whose constructor accepts only `initialEmail`. The token
/// never reached a screen, so the user was asked to request another email —
/// forever. `POST /auth/reset-password` has always existed and accepts it.
void main() {
  group('custom scheme reset links', () {
    test('carries the token through to the reset screen', () {
      final location = DeepLinkHandler.parse(
        Uri.parse('civilcal://reset-password?token=abc123&email=a%40b.com'),
      );
      expect(location, isNotNull);
      expect(location, startsWith('/reset-password?'));
      expect(location, contains('token=abc123'));
      expect(location, contains(Uri.encodeComponent('a@b.com')));
    });

    test('no longer routes to forgot-password, which cannot use a token', () {
      final location = DeepLinkHandler.parse(
        Uri.parse('civilcal://reset-password?token=abc123&email=a%40b.com'),
      );
      expect(location, isNot('/forgot-password'));
      expect(location, isNot(startsWith('/forgot-password')));
    });

    test('an email-only link still reaches the reset screen', () {
      final location =
          DeepLinkHandler.parse(Uri.parse('civilcal://reset-password?email=a%40b.com'));
      expect(location, startsWith('/reset-password'));
    });

    test('a bare reset link reaches the screen so it can explain itself', () {
      expect(DeepLinkHandler.parse(Uri.parse('civilcal://reset-password')), '/reset-password');
    });
  });

  group('web app-link reset links', () {
    // The emailed link is Fortify's web route: /reset-password/{token}?email=…
    // so the token is a PATH SEGMENT, not a query parameter. This is the shape
    // users actually tap on a phone.
    test('reads the token from the path segment', () {
      final location = DeepLinkHandler.parse(
        Uri.parse('https://bisaas.com/reset-password/abc123?email=a%40b.com'),
      );
      expect(location, isNotNull);
      expect(location, contains('token=abc123'));
      expect(location, contains(Uri.encodeComponent('a@b.com')));
    });

    test('works on the www host too', () {
      final location = DeepLinkHandler.parse(
        Uri.parse('https://www.bisaas.com/reset-password/abc123?email=a%40b.com'),
      );
      expect(location, contains('token=abc123'));
    });

    test('accepts a query-form token as a fallback', () {
      final location = DeepLinkHandler.parse(
        Uri.parse('https://bisaas.com/reset-password?token=abc123&email=a%40b.com'),
      );
      expect(location, contains('token=abc123'));
    });

    test('a token with URL-unsafe characters is encoded, not dropped', () {
      final location = DeepLinkHandler.parse(
        Uri.parse('https://bisaas.com/reset-password/tok%3Den%2Bwith%2Fchars'),
      );
      expect(location, isNotNull);
      expect(location, isNot(contains(' ')));
      // Round-trips back to the original token.
      final query = Uri.parse(location!).queryParameters;
      expect(query['token'], 'tok=en+with/chars');
    });
  });

  group('other links still route as before', () {
    test('civilcal quiz link', () {
      expect(DeepLinkHandler.parse(Uri.parse('civilcal://quiz/abc')), '/quiz/abc');
    });

    test('civilcal battle link', () {
      expect(DeepLinkHandler.parse(Uri.parse('civilcal://battle')), '/battle');
    });

    test('https quiz app link', () {
      expect(DeepLinkHandler.parse(Uri.parse('https://bisaas.com/quiz/abc')), '/quiz/abc');
    });

    test('an unknown https path is unhandled rather than misrouted', () {
      expect(DeepLinkHandler.parse(Uri.parse('https://bisaas.com/pricing')), isNull);
    });
  });

  group('PasswordPolicy mirrors the server', () {
    // Verified live: password "abc" -> "must be at least 8 characters";
    // mismatched confirmation -> "confirmation does not match". The server's
    // Password::default() is min:8 ONLY - no mixed-case/number/symbol rule.
    test('rejects shorter than the server minimum', () {
      expect(PasswordPolicy.validate('abc1234'), isNotNull);
      expect(PasswordPolicy.validate('abcd1234'), isNull);
    });

    test('rejects empty', () {
      expect(PasswordPolicy.validate(''), isNotNull);
    });

    test('accepts a password the server accepts, without inventing rules', () {
      // No uppercase, no symbol. The server takes it, so the client must too -
      // stricter client rules would reject a valid password with no explanation.
      expect(PasswordPolicy.validate('abcd1234'), isNull);
    });

    test('requires the confirmation to match', () {
      expect(PasswordPolicy.validateConfirmation('abcd1234', 'zzzz9999'), isNotNull);
      expect(PasswordPolicy.validateConfirmation('abcd1234', 'abcd1234'), isNull);
    });

    test('requires a confirmation at all', () {
      expect(PasswordPolicy.validateConfirmation('abcd1234', ''), isNotNull);
    });
  });
}
