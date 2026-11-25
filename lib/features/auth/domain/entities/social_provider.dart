/// The social providers the server accepts.
///
/// Domain-level so the repository contract does not depend on a data-source
/// that imports the platform SDKs.
library;

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
