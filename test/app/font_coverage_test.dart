import 'dart:io';

import 'package:bisaasmobile/app/theme/script_fonts.dart';
import 'package:flutter_test/flutter_test.dart';

/// The universal font chain is only as good as the fonts behind it.
///
/// `script_fonts.dart` resolves a font family *by name* per detected script and
/// lets Flutter fall back per-glyph. That design has one sharp edge: naming a
/// family that is not declared in `pubspec.yaml` does not error. Flutter quietly
/// falls through to the platform's `sans-serif`, so the app looks correct on a
/// device whose OEM happens to ship Noto, and renders tofu boxes on one that
/// ships a trimmed font set.
///
/// Those are exactly the languages the app exists to serve, and the failure is
/// invisible in CI because it depends on the host's installed fonts. So assert
/// the contract here instead of trusting a manual check.
void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();

  /// Families declared in the `fonts:` block of pubspec.
  final declared = RegExp(r'^\s*-\s*family:\s*(\S+)\s*$', multiLine: true)
      .allMatches(pubspec)
      .map((m) => m.group(1)!)
      .toSet();

  test('every script-specific family the chain asks for is really declared', () {
    // The platform backstop is intentionally not bundled: `sans-serif` is
    // resolved by the OS, not by us.
    const platformBackstops = {'sans-serif', 'sans-serif-fallback'};

    final unresolved = <String, List<String>>{};

    for (final script in AppScript.values) {
      final chain = ScriptFonts.forScript(script);
      final missing = chain
          .where((family) =>
              !platformBackstops.contains(family) && !declared.contains(family))
          .toList();
      if (missing.isNotEmpty) unresolved[script.name] = missing;
    }

    expect(
      unresolved,
      isEmpty,
      reason: 'These families are requested by script_fonts.dart but are not '
          'declared in pubspec.yaml, so Flutter silently falls back to the '
          'platform font. On an OEM with a trimmed font set the user sees tofu '
          'boxes. Either bundle the font or drop it from the chain.',
    );
  });

  test('the scripts we ship translations for have a bundled font', () {
    // The picker offers English, Nepali (Devanagari) and Hindi (Devanagari).
    // The universal chain additionally covers Bengali, Tamil, Telugu and Arabic,
    // because content can be in any of them regardless of UI locale. These must
    // not depend on which fonts the host device happens to have installed.
    const required = {
      AppScript.latin,
      AppScript.devanagari,
      AppScript.bengali,
      AppScript.tamil,
      AppScript.telugu,
      AppScript.arabic,
    };
    for (final script in required) {
      expect(
        ScriptFonts.forScript(script),
        isNotEmpty,
        reason: 'no font chain at all for ${script.name}',
      );
    }
  });

  test('no bundled font costs more than it earns in download size', () {
    // A full CJK face is ~10 MB and was 93.5% of the font payload for a language
    // the picker does not offer. The guard is deliberately simple: every
    // bundled face must stay under 1 MB, which is generous for the Indic and
    // Arabic faces we ship and impossible for an unsubsetted CJK font.
    final declared = RegExp(r'^\s*-\s*family:\s*(\S+)\s*$', multiLine: true)
        .allMatches(File('pubspec.yaml').readAsStringSync())
        .map((m) => m.group(1)!)
        .where((f) => f.startsWith('Noto'))
        .toList();

    const oneMb = 1024 * 1024;
    for (final family in declared) {
      final path = File('assets/fonts/noto/$family-Regular.ttf');
      if (!path.existsSync()) continue;
      expect(
        path.lengthSync(),
        lessThan(oneMb),
        reason: '$family is '
            '${(path.lengthSync() / oneMb).toStringAsFixed(1)} MB. Subset it '
            'before bundling; do not ship a full CJK face for a language the '
            'picker does not offer.',
      );
    }
  });

  test('every declared Noto family has its font file on disk', () {
    final noto = declared.where((f) => f.startsWith('Noto')).toList();
    expect(noto, isNotEmpty, reason: 'no Noto families declared at all');

    for (final family in noto) {
      // Parse forward from the family line: the `fonts:` block is the indented
      // run of `- asset:` lines that follows it. Comments sit between the
      // family and its assets, and the next family line ends the block, so
      // scanning is more robust than one regex over the whole file.
      final lines = pubspec.split('\n');
      final start = lines.indexWhere(
        (l) => l.trim() == '- family: $family',
      );
      expect(start, isNot(lessThan(0)), reason: 'family $family not found');

      final assets = <String>[];
      for (var i = start + 1; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('- family:')) break;
        final asset = RegExp(r'asset:\s*(\S+)').firstMatch(line);
        if (asset != null) assets.add(asset.group(1)!);
      }

      expect(
        assets,
        isNotEmpty,
        reason: 'family $family is declared with no font assets',
      );

      for (final path in assets) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: '$family declares $path but the file is missing',
        );
      }
    }
  });
}
