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
}
