import 'package:bisaasmobile/features/ai_settings/data/datasources/ai_settings_remote_data_source.dart';
import 'package:bisaasmobile/features/ai_settings/domain/entities/ai_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration/support/fake_api.dart';

/// The request body is the contract: a `base_url` must only reach providers the
/// server marked as accepting a custom endpoint.
void main() {
  const custom = AiProviderDescriptor(
    value: 'openai-compatible',
    label: 'OpenAI-compatible',
    allowCustomEndpoint: true,
  );
  const native = AiProviderDescriptor(value: 'openai', label: 'OpenAI');

  Future<Map<String, dynamic>> store(
    FakeApi api, {
    required AiProviderDescriptor provider,
    String? baseUrl,
  }) async {
    final dio = dioFor(api);
    await AiSettingsRemoteDataSource(dio).storeKey(
      provider: provider,
      secret: 'sk-a-secret-that-is-never-returned',
      label: 'my key',
      baseUrl: baseUrl,
    );
    return api.jsonBodyOf(0);
  }

  FakeApi api() => FakeApi({
        'POST /ai-keys': FakeRoute.ok(<String, dynamic>{
          'key': <String, dynamic>{
            'id': 1,
            'provider': 'openai-compatible',
            'provider_label': 'OpenAI-compatible',
            'masked_preview': '••••1234',
          },
        }),
      });

  test('a custom provider sends the provider value and the base_url', () async {
    final fake = api();
    final body = await store(
      fake,
      provider: custom,
      baseUrl: ' https://api.example.com/v1 ',
    );

    expect(body['provider'], 'openai-compatible');
    expect(body['secret'], 'sk-a-secret-that-is-never-returned');
    expect(body['base_url'], 'https://api.example.com/v1');
    expect(body, isNot(containsPair('base_url_preview', anything)));
  });

  test('a native provider never sends base_url, even when one was passed', () async {
    final fake = api();
    final body = await store(
      fake,
      provider: native,
      baseUrl: 'https://api.example.com/v1',
    );

    expect(body['provider'], 'openai');
    expect(body, isNot(containsPair('base_url', anything)));
  });

  test('a custom provider with no endpoint omits base_url', () async {
    final fake = api();
    final body = await store(fake, provider: custom);

    expect(body, isNot(containsPair('base_url', anything)));
  });
}
