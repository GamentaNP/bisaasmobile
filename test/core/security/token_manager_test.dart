import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bisaasmobile/core/security/token_manager.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late TokenManager tokenManager;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    tokenManager = TokenManager(storage: mockStorage);
  });

  group('TokenManager', () {
    test('readToken returns token from secure storage', () async {
      when(() => mockStorage.read(key: 'auth_token'))
          .thenAnswer((_) async => '1|test_token');

      final token = await tokenManager.readToken();
      expect(token, equals('1|test_token'));
      verify(() => mockStorage.read(key: 'auth_token')).called(1);
    });

    test('persist writes token and expiresAt to secure storage', () async {
      when(() => mockStorage.write(key: 'auth_token', value: 'token123'))
          .thenAnswer((_) async {});
      when(() => mockStorage.write(key: 'auth_expires_at', value: '2026-09-15T00:00:00Z'))
          .thenAnswer((_) async {});

      await tokenManager.persist(
        token: 'token123',
        expiresAt: '2026-09-15T00:00:00Z',
      );

      verify(() => mockStorage.write(key: 'auth_token', value: 'token123')).called(1);
      verify(() => mockStorage.write(key: 'auth_expires_at', value: '2026-09-15T00:00:00Z')).called(1);
    });

    test('clear deletes auth_token and auth_expires_at', () async {
      when(() => mockStorage.delete(key: 'auth_token'))
          .thenAnswer((_) async {});
      when(() => mockStorage.delete(key: 'auth_expires_at'))
          .thenAnswer((_) async {});

      await tokenManager.clear();

      verify(() => mockStorage.delete(key: 'auth_token')).called(1);
      verify(() => mockStorage.delete(key: 'auth_expires_at')).called(1);
    });

    test('shouldRefresh returns true when expires_at is less than 7 days away', () async {
      final in3Days = DateTime.now().add(const Duration(days: 3)).toIso8601String();
      when(() => mockStorage.read(key: 'auth_expires_at'))
          .thenAnswer((_) async => in3Days);

      final result = await tokenManager.shouldRefresh();
      expect(result, isTrue);
    });

    test('shouldRefresh returns false when expires_at is more than 7 days away', () async {
      final in15Days = DateTime.now().add(const Duration(days: 15)).toIso8601String();
      when(() => mockStorage.read(key: 'auth_expires_at'))
          .thenAnswer((_) async => in15Days);

      final result = await tokenManager.shouldRefresh();
      expect(result, isFalse);
    });
  });
}
