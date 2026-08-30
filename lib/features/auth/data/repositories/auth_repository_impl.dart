import '../../../../core/security/token_manager.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required TokenManager tokenManager,
  })  : _remoteDataSource = remoteDataSource,
        _tokenManager = tokenManager;

  final AuthRemoteDataSource _remoteDataSource;
  final TokenManager _tokenManager;

  @override
  Future<User> login({
    required String email,
    required String password,
    required String deviceName,
  }) async {
    final response = await _remoteDataSource.login(
      email: email,
      password: password,
      deviceName: deviceName,
    );

    await _tokenManager.persist(
      token: response.token,
      expiresAt: response.expiresAt,
      deviceName: deviceName,
    );

    if (response.user != null) {
      return response.user!.toDomain();
    }

    final userDto = await _remoteDataSource.getCurrentUser();
    return userDto?.toDomain() ??
        User(id: 0, name: email.split('@').first, email: email);
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String deviceName,
  }) async {
    final response = await _remoteDataSource.register(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      deviceName: deviceName,
    );

    await _tokenManager.persist(
      token: response.token,
      expiresAt: response.expiresAt,
      deviceName: deviceName,
    );

    if (response.user != null) {
      return response.user!.toDomain();
    }

    return User(id: 0, name: name, email: email);
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } finally {
      await _tokenManager.clear();
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    final token = await _tokenManager.readToken();
    if (token == null || token.isEmpty) return null;

    final userDto = await _remoteDataSource.getCurrentUser();
    return userDto?.toDomain();
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await _remoteDataSource.forgotPassword(email: email);
  }
}
