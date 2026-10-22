import 'package:flutter_test/flutter_test.dart';

import '../../tool/localization_coverage.dart';

/// Literals that are deliberately not translated.
///
/// An email address is an address, not copy — translating it would break it.
/// The synthetic HTTP status message is never shown to a user. The debug
/// auto-login button only exists in a `kDebugMode` build, so it is compiled
/// out of a release. The avatar fallback is the first letter of the display
/// name.
const allowedLiterals = <String>{
  'support@bisaas.com',
  'privacy@bisaas.com',
  'OK (cached)',
  '⚡ Debug Auto-Login (user@bisaas.test)',
  'C',
};

/// Literals that are diagnostics for a developer, not copy for a user.
///
/// The sync-queue reasons explain why a queued endpoint was refused; they end
/// up in an `ArgumentError` and in the log. The two battle-kernel labels and
/// the roster-sampling label are **protocol values** — the kernel and the
/// server agree on the strings `correctness` and `duration`, and translating
/// them would break the contract rather than translate it.
const developerDiagnostics = <String>{
  'an empty endpoint',
  'a path with surrounding whitespace',
  'an absolute URL',
  'a URL with a scheme',
  'a protocol-relative URL',
  'a path that is not rooted',
  'a path containing traversal',
  'correctness',
  'duration',
  'shuffle:{…}',
};


/// The whole interface is translated.
///
/// A language picker is a promise: a user who cannot read English picks
/// their own language, gets an English interface back, and concludes the
/// app is broken. That is strictly worse than the language not being
/// offered at all.
///
/// The registry check in `test/app/language_honesty_test.dart` proves an
/// ARB file *exists* for every offered language. It says nothing about
/// how much of the app that file covers — an ARB with twenty keys and an
/// interface with a thousand strings satisfies it perfectly while still
/// handing an English screen to a Nepali reader.
///
/// So this test measures the thing that matters: every string that
/// reaches the user comes from the ARB, in every offered language.
void main() {
  late List<Hit> hits;

  setUpAll(() async {
    hits = await collectHits();
  });

  test('no user-facing string is hardcoded English', () {
    final offenders = hits
        .where((h) => !allowedLiterals.contains(h.text))
        .where((h) => !developerDiagnostics.contains(h.text))
        .toList();

    expect(
      offenders,
      isEmpty,
      reason: 'These strings reach the user in the language they picked, but '
          'they are hardcoded English. Add them to the master table in '
          '`tool/generate_arb.py` (English, Nepali and Hindi on one line '
          'each), run `python tool/generate_arb.py && flutter gen-l10n`, and '
          'read them through `AppLocalizations.of(context)!` — or '
          '`appL10n()` outside a widget.\n'
          '${offenders.map((h) => '  ${h.file}:${h.line}  ${h.text}').join('\n')}',
    );
  });

  test('the only untranslated strings are the ones that cannot be', () {
    // The exceptions are documented above. If this test fails, someone
    // added a string to an allowlist that should not be there.
    final unexpected = hits
        .where((h) => allowedLiterals.contains(h.text))
        .where((h) => !const {
              'support@bisaas.com',
              'privacy@bisaas.com',
              'OK (cached)',
              '⚡ Debug Auto-Login (user@bisaas.test)',
              'C',
            }.contains(h.text))
        .toList();
    expect(unexpected, isEmpty);
  });

  test('the measurement itself still works', () {
    // A measurement that silently stops measuring is worse than no
    // measurement: the test above would pass with nothing in it.
    expect(hits, isNotEmpty);
    expect(
      hits.any((h) => allowedLiterals.contains(h.text)),
      isTrue,
      reason: 'the documented exceptions should still be detected — if they '
          'are not, the analyser is not seeing the files it should',
    );
  });
}
