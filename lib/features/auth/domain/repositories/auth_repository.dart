import '../../data/datasources/social_sign_in_gateway.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login({
    required String email,
    required String password,
    required String deviceName,
  });

  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String deviceName,
  });

  Future<void> logout();

  Future<User?> getCurrentUser();

  Future<void> forgotPassword({required String email});

  /// Completes a reset with the one-time token from the email link. Revokes all
  /// sessions server-side on success, so the caller must send the user to
  /// sign-in afterwards.
  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  });

  /// Authenticated change; keeps the current device signed in and revokes others.
  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  });

  /// Signs in with a social provider's id_token.
  ///
  /// The server verifies the token and mints the same bearer PAT the password
  /// flow returns, so the client persists it identically.
  Future<User> loginWithSocial({
    required SocialProvider provider,
    required String idToken,
    String? name,
    required String deviceName,
  });

  /// Resends the account-verification email.
  ///
  /// The server answers 200 whether or not the address still needs
  /// verifying, so this never leaks account state.
  Future<void> resendVerificationEmail();
}
