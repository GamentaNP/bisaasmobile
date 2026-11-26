import 'package:bisaasmobile/app/config/app_config.dart';
import 'package:bisaasmobile/app/providers.dart';
import 'package:bisaasmobile/core/network/pagination.dart' as paging;
import 'package:bisaasmobile/features/ai_settings/domain/entities/ai_settings.dart';
import 'package:bisaasmobile/features/ai_settings/domain/repositories/ai_settings_repository.dart';
import 'package:bisaasmobile/features/ai_settings/presentation/controllers/ai_settings_controller.dart';
import 'package:bisaasmobile/features/ai_settings/presentation/screens/ai_keys_screen.dart';
import 'package:bisaasmobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/localized_app.dart';

class MockAiSettingsRepository extends Mock implements AiSettingsRepository {}

void main() {
  late MockAiSettingsRepository repo;
  final l10n = lookupAppLocalizations(const Locale('en'));

  const openai = AiProviderDescriptor(value: 'openai', label: 'OpenAI');
  const gemini = AiProviderDescriptor(value: 'gemini', label: 'Google Gemini');
  const compatible = AiProviderDescriptor(
    value: 'openai-compatible',
    label: 'OpenAI-compatible',
    allowCustomEndpoint: true,
  );

  setUp(() {
    repo = MockAiSettingsRepository();
    registerFallbackValue(openai);
    when(() => repo.getKeys(
          cursor: any(named: 'cursor'),
          perPage: any(named: 'perPage'),
        )).thenAnswer((_) async => const paging.Page<AiKey>(items: []));
    when(() => repo.storeKey(
          provider: any(named: 'provider'),
          secret: any(named: 'secret'),
          label: any(named: 'label'),
          dailyTokenLimit: any(named: 'dailyTokenLimit'),
          baseUrl: any(named: 'baseUrl'),
        )).thenAnswer((_) async => const AiKey(id: 1, provider: 'openai'));
  });

  Widget host({List<AiProviderDescriptor>? providers}) => ProviderScope(
        overrides: [
          aiSettingsRepositoryProvider.overrideWithValue(repo),
          appConfigValueProvider.overrideWithValue(
            providers == null
                ? null
                : AppConfig(
                    aiProviders: providers,
                  ),
          ),
        ],
        child: localizedApp(child: const AiKeysScreen()),
      );

  Future<void> openForm(WidgetTester tester) async {
    await tester.tap(find.text(l10n.aiKeysAddTitle));
    await tester.pumpAndSettle();
  }

  Future<void> openPicker(WidgetTester tester) async {
    await tester.tap(find.byType(DropdownButtonFormField<AiProviderDescriptor>));
    await tester.pumpAndSettle();
  }

  testWidgets('the picker follows the server catalogue, defaulting to its '
      'first provider', (tester) async {
    await tester.pumpWidget(host(providers: [gemini, compatible]));
    await openForm(tester);

    // The default is the server's first entry, not a hardcoded OpenAI.
    expect(find.text('Google Gemini'), findsOneWidget);
    expect(find.text('OpenAI'), findsNothing);

    await openPicker(tester);
    // A server-published custom provider is offered, with the server's label.
    expect(find.text('OpenAI-compatible'), findsWidgets);
    expect(find.text('Google Gemini'), findsWidgets);
  });

  testWidgets('an older server falls back to the seven known providers and '
      'never invents openai-compatible', (tester) async {
    await tester.pumpWidget(host());
    await openForm(tester);

    expect(find.text('OpenAI'), findsOneWidget);
    await openPicker(tester);

    for (final label in [
      'OpenAI',
      'Google Gemini',
      'Anthropic',
      'DeepSeek',
      'Groq',
      'Mistral',
      'OpenRouter',
    ]) {
      expect(find.text(label), findsWidgets, reason: '$label must be offered');
    }
    expect(find.text('OpenAI-compatible'), findsNothing);
    expect(find.byKey(const Key('ai-keys-base-url')), findsNothing);
  });

  testWidgets('Base URL appears only for a custom provider and is sent in '
      'the POST body', (tester) async {
    await tester.pumpWidget(host(providers: [openai, compatible]));
    await openForm(tester);

    expect(find.byKey(const Key('ai-keys-base-url')), findsNothing);

    await openPicker(tester);
    await tester.tap(find.text('OpenAI-compatible').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ai-keys-base-url')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('ai-keys-secret')),
      'sk-a-long-enough-secret',
    );
    await tester.enterText(
      find.byKey(const Key('ai-keys-base-url')),
      'https://api.example.com/v1',
    );
    await tester.tap(find.widgetWithText(FilledButton, l10n.aiKeysSaveKey));
    await tester.pumpAndSettle();

    final call = verify(() => repo.storeKey(
          provider: captureAny(named: 'provider'),
          secret: any(named: 'secret'),
          label: any(named: 'label'),
          dailyTokenLimit: any(named: 'dailyTokenLimit'),
          baseUrl: captureAny(named: 'baseUrl'),
        ));
    expect(call.callCount, 1);
    expect(call.captured[0], compatible);
    expect(call.captured[1], 'https://api.example.com/v1');
  });

  testWidgets('a non-https base URL is refused locally', (tester) async {
    await tester.pumpWidget(host(providers: [compatible]));
    await openForm(tester);

    await tester.enterText(
      find.byKey(const Key('ai-keys-secret')),
      'sk-a-long-enough-secret',
    );
    await tester.enterText(
      find.byKey(const Key('ai-keys-base-url')),
      'http://api.example.com/v1',
    );
    await tester.tap(find.widgetWithText(FilledButton, l10n.aiKeysSaveKey));
    await tester.pumpAndSettle();

    expect(find.text(l10n.aiKeysBaseUrlInvalid), findsOneWidget);
    verifyNever(() => repo.storeKey(
          provider: any(named: 'provider'),
          secret: any(named: 'secret'),
          label: any(named: 'label'),
          dailyTokenLimit: any(named: 'dailyTokenLimit'),
          baseUrl: any(named: 'baseUrl'),
        ));
  });
}
