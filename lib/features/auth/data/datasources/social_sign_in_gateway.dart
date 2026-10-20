/// Social sign-in gateway.
///
/// The server owns the social flow end to end: the client obtains an
/// **id_token** from the platform SDK and hands it to
/// `POST /api/v1/auth/social/google` or `POST /api/v1/auth/social/apple`,
/// where Socialite verifies it in stateless mode. The client never sees an
/// access token, a refresh token or a client secret, and it never talks to
/// Google or Apple with its own credentials.
///
/// This file isolates the two platform SDKs behind one interface so the rest
/// of the auth feature (and its tests) never depend on `google_sign_in` or
/// `sign_in_with_apple` directly.
library;

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// The social providers the server accepts.
enum SocialProvider {
  google,
  apple;

  String get label => switch (this) {
        SocialProvider.google => 'Google',
        SocialProvider.apple => 'Apple',
      };

  /// The route the id_token is posted to.
  String get endpoint => switch (this) {
        SocialProvider.google => '/auth/social/google',
        SocialProvider.apple => '/auth/social/apple',
      };
}

/// What the platform SDK handed back.
class SocialIdToken {
  const SocialIdToken({
    required this.idToken,
    this.email,
    this.name,
  });

  /// The OIDC id_token. The server verifies the signature; the client must
  /// not parse it for claims it can read from [email] / [name].
  final String idToken;
  final String? email;
  final String? name;
}

/// Raised when the platform SDK refuses or fails.
///
/// [code] maps onto the server's frozen error codes where one applies:
///  * `cancelled` — the user closed the picker. Not an error to shout about.
///  * `unavailable` — the platform SDK is not usable on this device
///    (no Play Services, no Apple account, no network).
///  * `failed` — anything else.
class SocialSignInException implements Exception {
  const SocialSignInException(this.code, this.message);

  final String code;
  final String message;

  bool get isCancelled => code == 'cancelled';
  bool get isUnavailable => code == 'unavailable';

  @override
  String toString() => 'SocialSignInException($code): $message';
}

/// Obtains an id_token from a platform.
abstract class SocialSignInGateway {
  /// Returns the credential, or null when the user dismissed the picker.
  ///
  /// Throws [SocialSignInException] when the platform is unavailable or the
  /// flow failed.
  Future<SocialIdToken?> signIn(SocialProvider provider);

  /// Signs the user out of the platform SDK.
  Future<void> signOut(SocialProvider provider);

  /// Whether [provider] can be used on this device right now.
  ///
  /// The UI hides a button that returns false rather than offering an
  /// action that is guaranteed to fail.
  Future<bool> isAvailable(SocialProvider provider);
}

/// The real implementation, backed by the platform SDKs.
class PlatformSocialSignInGateway implements SocialSignInGateway {
  PlatformSocialSignInGateway({GoogleSignIn? googleSignIn})
      : _googleOverride = googleSignIn;

  /// The Google *web* client id.
  ///
  /// Android and iOS need the **server** client id for `idToken` to be
  /// issued at all; without it the SDK returns an authentication object whose
  /// `idToken` is null, which the server rejects with `AUTH_SOCIAL_FAILED`.
  static const googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
  static const googleServerClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  /// The Apple service id (the `com.apple.developer.applesignin` client id).
  static const appleClientId = String.fromEnvironment('APPLE_CLIENT_ID');

  /// The Apple redirect URI. Required on Android and web.
  static const appleRedirectUri = String.fromEnvironment('APPLE_REDIRECT_URI');

  final GoogleSignIn? _googleOverride;
  GoogleSignIn? _google;
  bool _googleInitialised = false;

  @override
  Future<bool> isAvailable(SocialProvider provider) async {
    switch (provider) {
      case SocialProvider.google:
        return googleClientId.isNotEmpty || googleServerClientId.isNotEmpty;
      case SocialProvider.apple:
        if (appleClientId.isEmpty) return false;
        if (kIsWeb) return appleRedirectUri.isNotEmpty;
        return SignInWithApple.isAvailable();
    }
  }

  @override
  Future<SocialIdToken?> signIn(SocialProvider provider) {
    switch (provider) {
      case SocialProvider.google:
        return _signInWithGoogle();
      case SocialProvider.apple:
        return _signInWithApple();
    }
  }

  @override
  Future<void> signOut(SocialProvider provider) async {
    switch (provider) {
      case SocialProvider.google:
        try {
          await _googleInstance().signOut();
        } on Object {
          // Signing out locally is best-effort; the server token is revoked
          // by `POST /auth/logout` regardless.
        }
      case SocialProvider.apple:
        // Apple has no SDK-side session to clear.
        break;
    }
  }

  GoogleSignIn _googleInstance() {
    final existing = _google;
    if (existing != null) return existing;
    final created = _googleOverride ?? GoogleSignIn.instance;
    _google = created;
    return created;
  }

  Future<SocialIdToken?> _signInWithGoogle() async {
    final google = _googleInstance();
    if (!_googleInitialised) {
      try {
        await google.initialize(
          clientId: googleClientId.isEmpty ? null : googleClientId,
          serverClientId:
              googleServerClientId.isEmpty ? null : googleServerClientId,
        );
        _googleInitialised = true;
      } on Object catch (e) {
        throw SocialSignInException(
          'unavailable',
          'Google Sign-In could not start: $e',
        );
      }
    }

    try {
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw SocialSignInException(
          'failed',
          'Google did not return an id token. The server client id is '
          'probably not configured for this build.',
        );
      }
      return SocialIdToken(
        idToken: idToken,
        email: account.email.isEmpty ? null : account.email,
        name: account.displayName,
      );
    } on SocialSignInException {
      rethrow;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      throw SocialSignInException(
        'failed',
        'Google sign-in failed: ${e.description ?? e.code.name}',
      );
    } on Object catch (e) {
      throw SocialSignInException('failed', 'Google sign-in failed: $e');
    }
  }

  Future<SocialIdToken?> _signInWithApple() async {
    if (appleClientId.isEmpty) {
      throw const SocialSignInException(
        'unavailable',
        'Apple sign-in is not configured for this build.',
      );
    }

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const <AppleIDAuthorizationScopes>[
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: kIsWeb || defaultTargetPlatform == TargetPlatform.android
            ? WebAuthenticationOptions(
                clientId: appleClientId,
                redirectUri: Uri.parse(
                  appleRedirectUri.isEmpty
                      ? 'https://bisaas.com/auth/apple/callback'
                      : appleRedirectUri,
                ),
              )
            : null,
      );
      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw const SocialSignInException(
          'failed',
          'Apple did not return an id token.',
        );
      }
      final name = [credential.givenName, credential.familyName]
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .join(' ')
          .trim();
      return SocialIdToken(
        idToken: idToken,
        email: credential.email,
        // Apple only returns the name on the very first authorisation.
        name: name.isEmpty ? null : name,
      );
    } on SocialSignInException {
      rethrow;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      throw SocialSignInException(
        'failed',
        'Apple sign-in failed: ${e.code.name}',
      );
    } on SignInWithAppleNotSupportedException catch (e) {
      throw SocialSignInException(
        'unavailable',
        'Apple sign-in is not supported on this device: ${e.message}',
      );
    } on Object catch (e) {
      throw SocialSignInException('failed', 'Apple sign-in failed: $e');
    }
  }
}
