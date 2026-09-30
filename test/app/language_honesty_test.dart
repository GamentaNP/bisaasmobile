import 'dart:io';

import 'package:bisaasmobile/app/localization/app_languages.dart';
import 'package:flutter_test/flutter_test.dart';

/// The language picker is a promise.
///
/// Advertising a language the app cannot actually render turns a missing
/// translation into a broken app: a user who cannot read English picks their
/// own language, gets English back, and concludes the product is faulty. That
/// is a worse outcome than the language simply not being offered.
///
/// So the seeded registry and the ARB directory must agree exactly, in both
/// directions. This test is what makes "add a language worldwide" a deliberate
/// two-step change (write the ARB, then register it) rather than something that
/// silently half-happens.
void main() {
  final arbDir = Directory('lib/l10n');
  final arbCodes = arbDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.arb'))
      .map((f) => f.uri.pathSegments.last.replaceFirst('.arb', '').split('_').last)
      .toSet();

  test('every language the picker offers has a real ARB translation', () {
    final missing = <String>[];
    for (final language in AppLanguages.supportedLocales) {
      if (!arbCodes.contains(language.languageCode)) missing.add(language.languageCode);
    }
    expect(
      missing,
      isEmpty,
      reason: 'These languages are selectable but have no lib/l10n ARB file, so '
          'selecting them returns an English interface. Either write the ARB '
          'file or drop the registry entry.',
    );
  });

  test('every ARB translation is reachable from the picker', () {
    final offered = AppLanguages.supportedLocales.map((l) => l.languageCode).toSet();
    final unreachable = arbCodes.difference(offered);
    expect(
      unreachable,
      isEmpty,
      reason: 'These ARB files exist but no registry entry offers them, so the '
          'translation ships without a way for a user to select it.',
    );
  });

  test('English is always offered, so the user can never be stranded', () {
    expect(AppLanguages.byCode('en'), isNotNull);
    expect(AppLanguages.fallback.code, 'en');
  });

  test('the languages we claim are actually the ones the server has questions for', () {
    // Guard against re-adding a locale with no server content. `quiz_question_translations`
    // is empty and there is no `zh` row in `languages`, so offering zh here would
    // promise translated questions that do not exist.
    expect(
      AppLanguages.byCode('zh'),
      isNull,
      reason: 'zh has no server locale and no translation rows; re-add it only '
          'together with a seeded zh locale and reviewed question translations.',
    );
  });
}
