import 'package:bisaasmobile/app/config/app_config.dart';
import 'package:bisaasmobile/core/network/api_failure.dart';
import 'package:bisaasmobile/features/ai_settings/domain/entities/ai_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration/support/fake_api.dart';

/// `data.ai_keys.providers` is the only source of truth for the BYOK picker.
/// The client must never publish `openai-compatible` on its own: an older
/// server would reject that provider with a 422.
void main() {
  const published = <String, dynamic>{
    'enabled': true,
    'providers': [
      {'value': 'gemini', 'label': 'Google Gemini'},
      {'value': 'anthropic', 'label': 'Anthropic'},
      {
        'value': 'openai-compatible',
        'label': 'My OpenAI-compatible gateway',
        'allow_custom_endpoint': true,
      },
    ],
  };

  group('AppConfig provider catalogue', () {
    test('an older server with no catalogue yields null, not an empty list', () {
      final config = AppConfig.fromJson(const {'maintenance': false});

      expect(config.aiProviders, isNull);
      expect(config.aiKeysEnabled, isTrue);
    });

    test('a published catalogue becomes typed descriptors in server order', () {
      final config = AppConfig.fromJson(const {'ai_keys': published});

      final providers = config.aiProviders!;
      expect(providers.map((p) => p.value).toList(), [
        'gemini',
        'anthropic',
        'openai-compatible',
      ]);
      expect(providers.map((p) => p.label).toList(), [
        'Google Gemini',
        'Anthropic',
        'My OpenAI-compatible gateway',
      ]);
      expect(providers.map((p) => p.allowCustomEndpoint).toList(), [
        false,
        false,
        true,
      ]);
      expect(config.aiKeysEnabled, isTrue);
    });

    test('a disabled flag is preserved', () {
      final config = AppConfig.fromJson(const {
        'ai_keys': {'enabled': false, 'providers': []},
      });
      expect(config.aiKeysEnabled, isFalse);
      expect(config.aiProviders, isEmpty);
    });

    test('the fallback is closed and never invents openai-compatible', () {
      final values = AiProvider.fallbackDescriptors.map((d) => d.value).toList();

      expect(values, [
        'openai',
        'gemini',
        'anthropic',
        'deepseek',
        'groq',
        'mistral',
        'openrouter',
      ]);
      expect(values, isNot(contains('openai-compatible')));
      expect(
        AiProvider.fallbackDescriptors
            .any((d) => d.allowCustomEndpoint),
        isFalse,
      );
    });

    test('a drifted catalogue is a contract violation, not a silent fallback', () {
      expect(
        () => AppConfig.fromJson(const {'ai_keys': 'nope'}),
        throwsA(isA<ContractViolation>()),
      );
      expect(
        () => AppConfig.fromJson(const {
          'ai_keys': {'providers': 'nope'},
        }),
        throwsA(isA<ContractViolation>()),
      );
      expect(
        () => AppConfig.fromJson(const {
          'ai_keys': {'providers': [{'label': 'no wire value'}]},
        }),
        throwsA(isA<ContractViolation>()),
      );
    });
  });

  group('AppConfigDataSource.fetch', () {
    test('parses the envelope and its provider catalogue', () async {
      final api = FakeApi({
        'GET /app/config': FakeRoute.ok(<String, dynamic>{
          'ai_keys': published,
        }),
      });
      final dio = dioFor(api);
      final config = await AppConfigDataSource(dio).fetch();

      expect(config.aiProviders, hasLength(3));
      expect(config.aiProviders!.last.value, 'openai-compatible');
    });

    test('a 2xx body without a data object throws ContractViolation', () async {
      final api = FakeApi({
        'GET /app/config': FakeRoute.raw(<String, dynamic>{'success': true}),
      });
      final dio = dioFor(api);

      expect(
        () => AppConfigDataSource(dio).fetch(),
        throwsA(isA<ContractViolation>()),
      );
    });
  });
}
