import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/security/token_manager.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dio = DioClient.instance.dio;
  return AuthRemoteDataSource(dio);
});

final tokenManagerProvider = Provider<TokenManager>((ref) {
  return TokenManager();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remote = ref.watch(authRemoteDataSourceProvider);
  final tokenManager = ref.watch(tokenManagerProvider);
  return AuthRepositoryImpl(
    remoteDataSource: remote,
    tokenManager: tokenManager,
  );
});

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  FutureOr<User?> build() async {
    final repo = ref.watch(authRepositoryProvider);
    return repo.getCurrentUser();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final tokenManager = ref.read(tokenManagerProvider);
      final deviceName = await tokenManager.readDeviceName() ??
          'android-${DateTime.now().millisecondsSinceEpoch}';
      await tokenManager.setDeviceName(deviceName);
      final repo = ref.read(authRepositoryProvider);
      return repo.login(
        email: email,
        password: password,
        deviceName: deviceName,
      );
    });
    if (state.hasError) {
      final err = state.error;
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
      final deviceName = await tokenManager.readDeviceName() ??
          'android-${DateTime.now().millisecondsSinceEpoch}';
      await tokenManager.setDeviceName(deviceName);
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
}

final authControllerProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);
