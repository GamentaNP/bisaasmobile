import 'package:bisaasmobile/features/ai_settings/data/models/ai_settings_dto.dart';
import 'package:flutter_test/flutter_test.dart';

/// The server can add a BYOK provider before this build knows its name. A new
/// wire value must not throw away every stored key — that used to be a
/// `FormatException` from `AiProvider.fromWire` that broke the whole list.
void main() {
  test('a known provider still parses', () {
    final key = AiKeyDto.fromJson(const {
      'id': 7,
      'provider': 'openrouter',
      'provider_label': 'OpenRouter',
      'masked_preview': '••••9f2a',
    });

    expect(key.provider, 'openrouter');
    expect(key.toDomain().providerDisplayName, 'OpenRouter');
  });

  test('an unknown provider keeps its raw wire value and server label', () {
    final key = AiKeyDto.fromJson(const {
      'id': 8,
      'provider': 'brand-new-provider',
      'provider_label': 'Brand New Provider',
      'label': 'personal',
      'masked_preview': '••••1234',
    });

    expect(key.provider, 'brand-new-provider');
    final domain = key.toDomain();
    expect(domain.provider, 'brand-new-provider');
    expect(domain.providerLabel, 'Brand New Provider');
    expect(domain.providerDisplayName, 'Brand New Provider');
    expect(domain.displayName, 'personal');
  });

  test('an unknown provider with no server label is still shown, not dropped', () {
    final key = AiKeyDto.fromJson(const {'id': 9, 'provider': 'future-provider'});

    expect(key.provider, 'future-provider');
    expect(key.toDomain().providerDisplayName, 'future-provider');
  });

  test('the base URL preview is non-secret and tolerates either wire name', () {
    final fromBaseUrl = AiKeyDto.fromJson(const {
      'id': 10,
      'provider': 'openai-compatible',
      'base_url': 'https://api.example.com/v1',
    });
    final fromPreview = AiKeyDto.fromJson(const {
      'id': 11,
      'provider': 'openai-compatible',
      'base_url_preview': 'https://preview.example.com/v1',
    });

    expect(fromBaseUrl.baseUrlPreview, 'https://api.example.com/v1');
    expect(fromPreview.baseUrlPreview, 'https://preview.example.com/v1');
    expect(fromBaseUrl.toDomain().baseUrlPreview, 'https://api.example.com/v1');
  });
}
