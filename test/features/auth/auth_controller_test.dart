import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bisaasmobile/core/security/token_manager.dart';
import 'package:bisaasmobile/features/auth/domain/entities/user.dart';
import 'package:bisaasmobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:bisaasmobile/features/auth/presentation/controllers/auth_controller.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockTokenManager extends Mock implements TokenManager {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockTokenManager mockTokenManager;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockTokenManager = MockTokenManager();
  });

  group('AuthNotifier', () {
    test('builds initial state by fetching current user', () async {
      const user = User(
        id: 1,
        name: 'Test Engineer',
        email: 'engineer@bisaas.test',
      );
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => user);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          tokenManagerProvider.overrideWithValue(mockTokenManager),
        ],
      );
      addTearDown(container.dispose);

      final userState = await container.read(authControllerProvider.future);
      expect(userState, equals(user));
    });

    test('login updates user state upon success', () async {
      const user = User(
        id: 1,
        name: 'Test Engineer',
        email: 'engineer@bisaas.test',
      );
      when(() => mockTokenManager.readDeviceName())
          .thenAnswer((_) async => 'test-device');
      when(() => mockTokenManager.setDeviceName(any()))
          .thenAnswer((_) async {});
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => null);
      when(() => mockAuthRepository.login(
            email: 'engineer@bisaas.test',
            password: 'password123',
            deviceName: 'test-device',
          )).thenAnswer((_) async => user);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          tokenManagerProvider.overrideWithValue(mockTokenManager),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authControllerProvider.notifier);
      await notifier.login(
        email: 'engineer@bisaas.test',
        password: 'password123',
      );

      final currentState = container.read(authControllerProvider);
      expect(currentState.value, equals(user));
    });

    test('logout clears user state', () async {
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => null);
      when(() => mockAuthRepository.logout())
          .thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          tokenManagerProvider.overrideWithValue(mockTokenManager),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authControllerProvider.notifier);
      await notifier.logout();

      final currentState = container.read(authControllerProvider);
      expect(currentState.value, isNull);
    });
  });
}
