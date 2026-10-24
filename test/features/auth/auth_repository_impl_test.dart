import 'package:bisaasmobile/core/network/api_failure.dart';
import 'package:bisaasmobile/core/security/token_manager.dart';
import 'package:bisaasmobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:bisaasmobile/features/auth/data/datasources/social_sign_in_gateway.dart';
import 'package:bisaasmobile/features/auth/data/models/auth_response_dto.dart';
import 'package:bisaasmobile/features/auth/data/models/user_dto.dart';
import 'package:bisaasmobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockTokenManager extends Mock implements TokenManager {}

/// Records sign-out calls so the repository's best-effort platform cleanup
/// can be asserted without a device.
class RecordingGateway implements SocialSignInGateway {
  final List<SocialProvider> signOutCalls = [];

  @override
  Future<bool> isAvailable(SocialProvider provider) async => false;

  @override
  Future<SocialIdToken?> signIn(SocialProvider provider) async => null;

  @override
  Future<void> signOut(SocialProvider provider) async {
    signOutCalls.add(provider);
  }
}

void main() {
  const responseWithUser = AuthResponseDto(
    token: 'pat-1',
    expiresAt: '2026-11-01T00:00:00+00:00',
    user: UserDto(id: 7, name: 'Bishwo', email: 'a@b.test'),
  );
  const responseWithoutUser = AuthResponseDto(token: 'pat-1');

  late MockAuthRemoteDataSource remote;
  late MockTokenManager tokens;
  late RecordingGateway gateway;
  late AuthRepositoryImpl repo;

  setUp(() {
    remote = MockAuthRemoteDataSource();
    tokens = MockTokenManager();
    gateway = RecordingGateway();
    repo = AuthRepositoryImpl(
      remoteDataSource: remote,
      tokenManager: tokens,
      socialSignInGateway: gateway,
    );

    when(() => tokens.persist(
          token: any(named: 'token'),
          expiresAt: any(named: 'expiresAt'),
          deviceName: any(named: 'deviceName'),
        )).thenAnswer((_) async {});
    when(() => tokens.clear()).thenAnswer((_) async {});
  });

  group('login', () {
    test('returns the user the response carried', () async {
      when(() => remote.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
            deviceName: any(named: 'deviceName'),
          )).thenAnswer((_) async => responseWithUser);

      final user = await repo.login(
        email: 'a@b.test',
        password: 'secret',
        deviceName: 'd',
      );

      expect(user.id, 7);
      verify(() => tokens.persist(
            token: 'pat-1',
            expiresAt: '2026-11-01T00:00:00+00:00',
            deviceName: 'd',
          )).called(1);
    });

    test('falls back to /me when the response omitted the user', () async {
      when(() => remote.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
            deviceName: any(named: 'deviceName'),
          )).thenAnswer((_) async => responseWithoutUser);
      when(() => remote.getCurrentUser())
          .thenAnswer((_) async => const UserDto(id: 9, name: 'Me', email: 'm@b.test'));

      final user = await repo.login(
        email: 'a@b.test',
        password: 'secret',
        deviceName: 'd',
      );

      expect(user.id, 9);
    });

    test('a token with no user anywhere is contract drift, not User(id: 0)',
        () async {
      when(() => remote.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
            deviceName: any(named: 'deviceName'),
          )).thenAnswer((_) async => responseWithoutUser);
      when(() => remote.getCurrentUser()).thenAnswer((_) async => null);

      await expectLater(
        repo.login(email: 'a@b.test', password: 'secret', deviceName: 'd'),
        throwsA(isA<ContractViolation>()),
      );
    });
  });

  group('register', () {
    test('asks /me when the response omitted the user', () async {
      when(() => remote.register(
            name: any(named: 'name'),
            email: any(named: 'email'),
            password: any(named: 'password'),
            passwordConfirmation: any(named: 'passwordConfirmation'),
            deviceName: any(named: 'deviceName'),
          )).thenAnswer((_) async => responseWithoutUser);
      when(() => remote.getCurrentUser())
          .thenAnswer((_) async => const UserDto(id: 9, name: 'Me', email: 'm@b.test'));

      final user = await repo.register(
        name: 'Me',
        email: 'm@b.test',
        password: 'secret',
        passwordConfirmation: 'secret',
        deviceName: 'd',
      );

      expect(user.id, 9);
    });

    test('no user in the register response or /me is contract drift', () async {
      when(() => remote.register(
            name: any(named: 'name'),
            email: any(named: 'email'),
            password: any(named: 'password'),
            passwordConfirmation: any(named: 'passwordConfirmation'),
            deviceName: any(named: 'deviceName'),
          )).thenAnswer((_) async => responseWithoutUser);
      when(() => remote.getCurrentUser()).thenAnswer((_) async => null);

      await expectLater(
        repo.register(
          name: 'Me',
          email: 'm@b.test',
          password: 'secret',
          passwordConfirmation: 'secret',
          deviceName: 'd',
        ),
        throwsA(isA<ContractViolation>()),
      );
    });
  });

  group('logout', () {
    test('clears the token, the cache path and the platform SDK session',
        () async {
      when(() => remote.logout()).thenAnswer((_) async {});

      await repo.logout();

      verify(() => tokens.clear()).called(1);
      expect(gateway.signOutCalls, [SocialProvider.google]);
    });

    test('clears the token even when the server call fails', () async {
      when(() => remote.logout()).thenThrow(Exception('offline'));

      // The server error still reaches the caller — cleanup happens in the
      // finally block, then the failure propagates.
      await expectLater(repo.logout(), throwsA(anything));

      verify(() => tokens.clear()).called(1);
      expect(gateway.signOutCalls, [SocialProvider.google]);
    });

    test('a failing SDK sign-out still clears the local session', () async {
      when(() => remote.logout()).thenAnswer((_) async {});
      final failingGateway = _ThrowingGateway();
      final repo2 = AuthRepositoryImpl(
        remoteDataSource: remote,
        tokenManager: tokens,
        socialSignInGateway: failingGateway,
      );

      await repo2.logout();

      verify(() => tokens.clear()).called(1);
    });
  });

  group('resetPassword', () {
    test('clears the local session — the server revoked every token',
        () async {
      when(() => remote.resetPassword(
            token: any(named: 'token'),
            email: any(named: 'email'),
            password: any(named: 'password'),
            passwordConfirmation: any(named: 'passwordConfirmation'),
          )).thenAnswer((_) async {});

      await repo.resetPassword(
        token: 't',
        email: 'a@b.test',
        password: 'new-secret',
        passwordConfirmation: 'new-secret',
      );

      verify(() => tokens.clear()).called(1);
    });
  });
}

class _ThrowingGateway implements SocialSignInGateway {
  @override
  Future<bool> isAvailable(SocialProvider provider) async => false;

  @override
  Future<SocialIdToken?> signIn(SocialProvider provider) async => null;

  @override
  Future<void> signOut(SocialProvider provider) async {
    throw StateError('sdk broken');
  }
}
