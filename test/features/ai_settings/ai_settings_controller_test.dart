import 'package:bisaasmobile/core/network/api_exception.dart';
import 'package:bisaasmobile/core/network/pagination.dart';
import 'package:bisaasmobile/features/ai_settings/domain/entities/ai_settings.dart';
import 'package:bisaasmobile/features/ai_settings/domain/repositories/ai_settings_repository.dart';
import 'package:bisaasmobile/features/ai_settings/presentation/controllers/ai_settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAiSettingsRepository extends Mock implements AiSettingsRepository {}

/// Zero-coverage feature no more: the BYOK controller's state transitions —
/// a saved key refreshes the list, a refusal surfaces the server's message
/// instead of pretending nothing happened, and a failed fetch is an error
/// with retry, never an empty key list that reads as "you have no keys".
void main() {
  late MockAiSettingsRepository repo;

  const key = AiKey(
    id: 11,
    provider: AiProvider.openrouter,
    maskedPreview: '••••9f2a',
  );

  setUp(() {
    repo = MockAiSettingsRepository();
    registerFallbackValue(AiProvider.openrouter);
    when(() => repo.getKeys(cursor: any(named: 'cursor'), perPage: any(named: 'perPage')))
        .thenAnswer((_) async => const Page<AiKey>(items: [key]));
  });

  Future<ProviderContainer> container() async {
    final c = ProviderContainer(overrides: [
      aiSettingsRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('AiSettingsController — BYOK', () {
    test('storeKey saves, refreshes the list and reports the masked key', () async {
      when(() => repo.storeKey(
            provider: any(named: 'provider'),
            secret: any(named: 'secret'),
            label: any(named: 'label'),
            dailyTokenLimit: any(named: 'dailyTokenLimit'),
          )).thenAnswer((_) async => key);

      final c = await container();
      final notifier = c.read(aiSettingsControllerProvider.notifier);

      final ok = await notifier.storeKey(
        provider: AiProvider.openrouter,
        secret: 'sk-secret-never-stored-on-device',
      );

      expect(ok, isTrue);
      expect(c.read(aiSettingsControllerProvider).keys, [key]);
      expect(c.read(aiSettingsControllerProvider).saveKeyError, isNull);
      verify(() => repo.getKeys(cursor: any(named: 'cursor'), perPage: any(named: 'perPage')))
          .called(greaterThanOrEqualTo(1));
    });

    test('a refused key surfaces the server message and saves nothing', () async {
      when(() => repo.storeKey(
            provider: any(named: 'provider'),
            secret: any(named: 'secret'),
            label: any(named: 'label'),
            dailyTokenLimit: any(named: 'dailyTokenLimit'),
          )).thenThrow(const ApiException(
        statusCode: 422,
        code: ApiErrorCode.validationError,
        message: 'The key was rejected by the provider.',
      ));

      final c = await container();
      final notifier = c.read(aiSettingsControllerProvider.notifier);

      final ok = await notifier.storeKey(
        provider: AiProvider.openrouter,
        secret: 'sk-bad',
      );

      expect(ok, isFalse);
      expect(
        c.read(aiSettingsControllerProvider).saveKeyError,
        'The key was rejected by the provider.',
      );
    });

    test('revokeKey removes it from the list through the refetch', () async {
      when(() => repo.revokeKey(11)).thenAnswer((_) async {});

      final c = await container();
      final notifier = c.read(aiSettingsControllerProvider.notifier);
      await notifier.fetchKeys();
      expect(c.read(aiSettingsControllerProvider).keys, [key]);

      final ok = await notifier.revokeKey(11);

      expect(ok, isTrue);
      verify(() => repo.revokeKey(11)).called(1);
    });

    test('fetchKeys failure is an error state, not an empty list', () async {
      when(() => repo.getKeys(cursor: any(named: 'cursor'), perPage: any(named: 'perPage')))
          .thenThrow(const ApiException(
        statusCode: 500,
        code: ApiErrorCode.serviceUnavailable,
        message: 'Server trouble.',
      ));

      final c = await container();
      final notifier = c.read(aiSettingsControllerProvider.notifier);

      await notifier.fetchKeys();

      final state = c.read(aiSettingsControllerProvider);
      expect(state.keysError, 'Server trouble.');
      expect(state.keys, isEmpty);
      expect(state.isKeysLoading, isFalse);
    });
  });

  group('AiSettingsController — own usage', () {
    test('fetchUsage requests the period the UI selected', () async {
      const summary = AiUsageSummary(
        requests: 12,
        promptTokens: 100,
        completionTokens: 200,
      );
      when(() => repo.getUsageSummary(period: '7d')).thenAnswer((_) async => summary);

      final c = await container();
      final notifier = c.read(aiSettingsControllerProvider.notifier);

      await notifier.fetchUsage(period: AiUsagePeriod.sevenDays);

      final state = c.read(aiSettingsControllerProvider);
      expect(state.usagePeriod, AiUsagePeriod.sevenDays);
      expect(state.usage, summary);
      expect(state.usageError, isNull);
    });

    test('a usage failure carries the message, not a zeroed summary', () async {
      when(() => repo.getUsageSummary(period: any(named: 'period')))
          .thenThrow(const ApiException(
        statusCode: 429,
        code: ApiErrorCode.rateLimitExceeded,
        message: 'Slow down.',
      ));

      final c = await container();
      final notifier = c.read(aiSettingsControllerProvider.notifier);

      await notifier.fetchUsage();

      final state = c.read(aiSettingsControllerProvider);
      expect(state.usage, isNull);
      expect(state.usageError, 'Slow down.');
    });
  });
}
