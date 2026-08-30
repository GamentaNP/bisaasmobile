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
}
