import '../../../../core/network/api_failure.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/security/token_manager.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/social_sign_in_gateway.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required TokenManager tokenManager,
    required SocialSignInGateway socialSignInGateway,
  })  : _remoteDataSource = remoteDataSource,
        _tokenManager = tokenManager,
        _socialSignInGateway = socialSignInGateway;

  final AuthRemoteDataSource _remoteDataSource;
  final TokenManager _tokenManager;
  final SocialSignInGateway _socialSignInGateway;

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

    // A token without a user is contract drift, not a user to fabricate:
    // a synthetic `User(id: 0, …)` leaks into every feature keyed by user id.
    final userDto = await _remoteDataSource.getCurrentUser();
    if (userDto == null) {
      throw const ContractViolation(
        'Login response carried no user',
        endpoint: '/auth/login',
      );
    }
    return userDto.toDomain();
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

    // The register contract returns the created user; when it does not, ask
    // `/me` (the token is already persisted) before declaring drift.
    final userDto = await _remoteDataSource.getCurrentUser();
    if (userDto == null) {
      throw const ContractViolation(
        'Register response carried no user',
        endpoint: '/auth/register',
      );
    }
    return userDto.toDomain();
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } finally {
      await _tokenManager.clear();
      // Best-effort: clear the platform SDK session so the Google account
      // picker does not keep offering the account after logout. Apple has no
      // SDK-side session to clear. The server token is revoked by
      // `POST /auth/logout` regardless.
      try {
        await _socialSignInGateway.signOut(SocialProvider.google);
      } on Object {
        // The SDK session is a convenience, not the source of truth.
      }
      // Drop the public-response cache too. Only non-personal catalog data is
      // in it, but on a shared device the next account would otherwise start
      // from the previous one's cached world, and the allowlist that keeps it
      // personal-data-free is one careless entry away from mattering.
      if (DioClient.isInitialized) {
        await DioClient.instance.clearResponseCache();
      }
    }
  }

  @override
  Future<void> deleteAccount() async {
    await _remoteDataSource.deleteAccount();
    // The server erased the account and revoked its PATs. Clear the local
    // session so the router's refreshListenable drops the user on the login
    // screen; the same token-loss listener unregisters the FCM device token.
    await _tokenManager.clear();
  }

  @override
  Future<User?> getCurrentUser() async {
    final token = await _tokenManager.readToken();
    if (token == null || token.isEmpty) return null;

    if (await _tokenManager.shouldRefresh()) {
      final deviceName = await TokenManager.resolveDeviceName(_tokenManager);
      final rotated = await _remoteDataSource.refresh(deviceName: deviceName);
      await _tokenManager.persist(
        token: rotated.token,
        expiresAt: rotated.expiresAt,
        deviceName: deviceName,
      );
    }

    final userDto = await _remoteDataSource.getCurrentUser();
    return userDto?.toDomain();
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await _remoteDataSource.forgotPassword(email: email);
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _remoteDataSource.resetPassword(
      token: token,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
    // The server revoked every session for the account. If this device held
    // one, it is dead now — clear it so the guard does not keep a ghost
    // session alive until the next 401 says so.
    await _tokenManager.clear();
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _remoteDataSource.changePassword(
      currentPassword: currentPassword,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
  }

  @override
  Future<User> loginWithSocial({
    required SocialProvider provider,
    required String idToken,
    String? name,
    required String deviceName,
  }) async {
    final response = switch (provider) {
      SocialProvider.google => await _remoteDataSource.loginWithGoogle(
          idToken: idToken,
        ),
      SocialProvider.apple => await _remoteDataSource.loginWithApple(
          idToken: idToken,
          name: name,
        ),
    };

    // The social flow mints the same bearer PAT the password flow does, so it
    // is persisted the same way — only in flutter_secure_storage.
    await _tokenManager.persist(
      token: response.token,
      expiresAt: response.expiresAt,
      deviceName: deviceName,
    );

    if (response.user != null) {
      return response.user!.toDomain();
    }

    final userDto = await _remoteDataSource.getCurrentUser();
    if (userDto == null) {
      throw const ContractViolation(
        'Social sign-in response carried no user',
        endpoint: '/auth/social',
      );
    }
    return userDto.toDomain();
  }

  @override
  Future<void> resendVerificationEmail() =>
      _remoteDataSource.resendVerificationEmail();
}
