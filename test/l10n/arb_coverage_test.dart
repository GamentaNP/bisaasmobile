import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/arb_coverage.dart';

/// A locale that is only partly translated produces a mixed-language UI, which
/// is the failure this spec calls out. Generated l10n classes compile fine with
/// a missing key and silently fall back to English at runtime, so nothing in the
/// build catches it. This gate does.
void main() {
  late ArbCoverage arb;

  setUpAll(() {
    arb = ArbCoverage.load(Directory('lib/l10n'));
  });

  test('the template is not empty', () {
    expect(arb.templateKeys, isNotEmpty);
  });

  test('Nepali and Hindi are both present as real locales', () {
    expect(arb.locales.keys, containsAll(<String>['ne', 'hi']));
  });

  test('every locale covers every template key', () {
    final incomplete = <String, Set<String>>{};
    for (final locale in arb.locales.keys) {
      final missing = arb.missingKeys(locale);
      if (missing.isNotEmpty) incomplete[locale] = missing;
    }
    expect(
      incomplete,
      isEmpty,
      reason: 'a partially translated locale must not ship — add the missing '
          'keys or drop the locale',
    );
  });

  test('no locale carries keys the template does not define', () {
    for (final locale in arb.locales.keys) {
      expect(
        arb.unknownKeys(locale),
        isEmpty,
        reason: '$locale has dead keys that can never be displayed',
      );
    }
  });

  test('placeholders are preserved so runtime formatting cannot fail', () {
    for (final key in arb.templateKeys) {
      final template = arb.template[key];
      if (template is! String) continue;
      final placeholders = RegExp(r'\{(\w+)\}').allMatches(template).map((m) => m.group(1)).toSet();
      for (final locale in arb.locales.keys) {
        final value = arb.locales[locale]![key];
        expect(value, isA<String>(), reason: '$locale.$key must be a string');
        final actual = RegExp(r'\{(\w+)\}')
            .allMatches(value! as String)
            .map((m) => m.group(1))
            .toSet();
        expect(
          actual,
          placeholders,
          reason: '$locale.$key must keep the placeholders of the template',
        );
      }
    }
  });

  test('the report names every locale', () {
    final report = arb.report();
    for (final locale in arb.locales.keys) {
      expect(report, contains(locale));
    }
  });
}
