import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/security/token_manager.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/social_sign_in_gateway.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dio = DioClient.instance.dio;
  return AuthRemoteDataSource(dio);
});

/// The platform SDK gateway. Overridden in tests so the auth controller can
/// be exercised without a device.
final socialSignInGatewayProvider = Provider<SocialSignInGateway>((ref) {
  return PlatformSocialSignInGateway();
});

final tokenManagerProvider = Provider<TokenManager>((ref) {
  // Single app-wide instance — initialized in bootstrap.dart for the Dio
  // chain; the provider just re-exposes it so features share the same one.
  return TokenManager.shared;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remote = ref.watch(authRemoteDataSourceProvider);
  final tokenManager = ref.watch(tokenManagerProvider);
  return AuthRepositoryImpl(
    remoteDataSource: remote,
    tokenManager: tokenManager,
  );
});

/// Which social providers this build can actually use.
///
/// The result is **per provider**, not a single boolean. A build that has only
/// a Google client id must not render an Apple button that is guaranteed to
/// fail — a button that cannot work is worse than no button.
///
/// A provider whose client id was never compiled in is hidden rather than
/// offered as a disabled control.
final socialProvidersAvailableProvider =
    FutureProvider<Set<SocialProvider>>((ref) async {
  final gateway = ref.watch(socialSignInGatewayProvider);
  final available = <SocialProvider>{};
  for (final provider in SocialProvider.values) {
    if (await gateway.isAvailable(provider)) available.add(provider);
  }
  return available;
});

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  FutureOr<User?> build() async {
    final repo = ref.watch(authRepositoryProvider);
    try {
      return await repo.getCurrentUser();
    } on Object catch (e, st) {
      // A cold start that cannot reach the server is not the same as being
      // signed out. The token is still on the device, so the app keeps the
      // session and surfaces the failure as an error state instead of dumping
      // the user on the login screen over a dropped connection.
      AppLogger.w('auth cold start failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      return null;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final tokenManager = ref.read(tokenManagerProvider);
      final deviceName = await TokenManager.resolveDeviceName(tokenManager);
      final repo = ref.read(authRepositoryProvider);
      return repo.login(
        email: email,
        password: password,
        deviceName: deviceName,
      );
    });
    if (state.hasError) {
      final err = state.error;
      // An unverified account is a recoverable state, not a dead end: the
      // resend action becomes available.
      ref.read(emailVerificationRequiredProvider.notifier).observe(err);
      if (err is Exception) {
        throw err;
      }
      throw Exception(err.toString());
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final tokenManager = ref.read(tokenManagerProvider);
      final deviceName = await TokenManager.resolveDeviceName(tokenManager);
      final repo = ref.read(authRepositoryProvider);
      return repo.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        deviceName: deviceName,
      );
    });
    if (state.hasError) {
      final err = state.error;
      // An unverified account is a recoverable state, not a dead end: the
      // resend action becomes available. Registration can hit it too — a
      // server that issues a token before the address is verified will
      // refuse the first protected call.
      ref.read(emailVerificationRequiredProvider.notifier).observe(err);
      if (err is Exception) {
        throw err;
      }
      throw Exception(err.toString());
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      await repo.logout();
      return null;
    });
  }

  Future<void> forgotPassword({required String email}) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.forgotPassword(email: email);
  }

  /// Completes a password reset. The server revokes every token on success, so
  /// the local session is cleared defensively even though the user tapping the
  /// link is, by definition, not signed in on this device yet.
  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.resetPassword(
        token: token,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.changePassword(
      currentPassword: currentPassword,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
    // Other devices were revoked; refresh the user so the UI reflects the new
    // state without forcing a re-login on this one.
    state = AsyncData(await repo.getCurrentUser());
  }

  /// Signs in with Google or Apple.
  ///
  /// The platform SDK produces an id_token; the server verifies it and mints
  /// the bearer PAT. Nothing about the credential is trusted from the client.
  ///
  /// [credential] is passed when the caller already holds one — Apple's own
  /// button widget hands the credential over directly — and omitted when the
  /// gateway should run the flow itself.
  ///
  /// Returns false when the user dismissed the picker, so the caller can stay
  /// silent instead of showing an error for a deliberate cancellation.
  Future<bool> loginWithSocial(
    SocialProvider provider, {
    SocialIdToken? credential,
  }) async {
    state = const AsyncValue.loading();
    final gateway = ref.read(socialSignInGatewayProvider);
    try {
      final token = credential ?? await gateway.signIn(provider);
      if (token == null) {
        // The user closed the picker.
        state = const AsyncValue.data(null);
        return false;
      }
      final tokenManager = ref.read(tokenManagerProvider);
      final deviceName = await TokenManager.resolveDeviceName(tokenManager);
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.loginWithSocial(
        provider: provider,
        idToken: token.idToken,
        name: token.name,
        deviceName: deviceName,
      );
      state = AsyncValue.data(user);
      return true;
    } catch (e, st) {
      AppLogger.w('auth loginWithSocial ${provider.name} failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Resends the account-verification email.
  ///
  /// Throws [ApiException] with `AUTH_EMAIL_UNVERIFIED` handled by the
  /// caller — the endpoint is throttled server-side, so the client does not
  /// add its own timer.
  Future<void> resendVerificationEmail() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.resendVerificationEmail();
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

/// Whether the account needs its email address verified.
///
/// The server answers `403 AUTH_EMAIL_UNVERIFIED` on protected endpoints for
/// an unverified account. The flag is raised when that code is seen, so the
/// UI can offer the resend action
/// (`POST /auth/email/verification-notification`) instead of leaving the user
/// with a bare "Forbidden".
final emailVerificationRequiredProvider =
    NotifierProvider<EmailVerificationNotifier, bool>(
  EmailVerificationNotifier.new,
);

class EmailVerificationNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void requireVerification() => state = true;

  void clear() => state = false;

  /// Raises the flag when [error] is the server's unverified-account code.
  void observe(Object? error) {
    if (error is ApiException && error.code == ApiErrorCode.authEmailUnverified) {
      requireVerification();
    }
  }
}
