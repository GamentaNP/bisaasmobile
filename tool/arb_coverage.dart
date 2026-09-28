import 'dart:convert';
import 'dart:io';

/// Reports ARB translation coverage and fails when a locale is incomplete.
///
/// Interface translation is a per-locale all-or-nothing promise: a user who
/// selects a language expects to read that language, and a locale that is
/// quietly 90% translated produces exactly the mixed-language UI this spec
/// calls out. Nothing else in the build catches that, because generated
/// l10n classes compile fine with a missing key and fall back to English at
/// runtime.
///
/// Run directly for a report:
/// ```sh
/// dart run tool/arb_coverage.dart
/// ```
/// Or as a test gate via `test/l10n/arb_coverage_test.dart`.
class ArbCoverage {
  ArbCoverage._(this.dir, this.template, this.locales);

  final Directory dir;
  final Map<String, Object?> template;
  final Map<String, Map<String, Object?>> locales;

  /// Keys of the template that are not metadata (`@@locale`, `@placeholder`).
  Set<String> get templateKeys =>
      template.keys.where((k) => !k.startsWith('@')).toSet();

  /// Keys present in [locale] but missing from the template. These are dead
  /// entries — they can never be shown.
  Set<String> unknownKeys(String locale) =>
      locales[locale]?.keys.where((k) => !k.startsWith('@') && !templateKeys.contains(k)).toSet() ??
          <String>{};

  /// Template keys with no entry in [locale].
  Set<String> missingKeys(String locale) =>
      templateKeys.difference(locales[locale]?.keys.where((k) => !k.startsWith('@')).toSet() ??
          <String>{});

  /// Keys whose value is still byte-identical to English, which for a language
  /// other than `en` usually means "untranslated" rather than "genuinely the
  /// same word" (brand names aside).
  Set<String> untranslatedKeys(String locale) {
    final target = locales[locale];
    if (target == null) return <String>{};
    final same = <String>{};
    for (final key in templateKeys) {
      final a = template[key];
      final b = target[key];
      if (a is String && b is String && a == b && a.trim().isNotEmpty) same.add(key);
    }
    return same;
  }

  double coverage(String locale) {
    if (templateKeys.isEmpty) return 1;
    return 1 - (missingKeys(locale).length / templateKeys.length);
  }

  bool get isComplete => locales.keys.every((l) => missingKeys(l).isEmpty);

  /// Loads the template plus every sibling ARB file.
  factory ArbCoverage.load([Directory? dir]) {
    final d = dir ?? Directory('lib/l10n');
    if (!d.existsSync()) {
      throw StateError('ARB directory not found: ${d.path}');
    }
    Map<String, Object?> read(File f) =>
        jsonDecode(f.readAsStringSync(encoding: utf8)) as Map<String, Object?>;

    final templateFile = File('${d.path}/app_en.arb');
    if (!templateFile.existsSync()) {
      throw StateError('Template ARB not found: ${templateFile.path}');
    }

    final locales = <String, Map<String, Object?>>{};
    for (final f in d.listSync().whereType<File>()) {
      final name = f.uri.pathSegments.last;
      if (!name.startsWith('app_') || !name.endsWith('.arb')) continue;
      final code = name.substring(4, name.length - 4);
      if (code == 'en') continue;
      locales[code] = read(f);
    }
    return ArbCoverage._(d, read(templateFile), locales);
  }
  String report() {
    final b = StringBuffer()
      ..writeln('ARB coverage — template has ${templateKeys.length} keys')
      ..writeln('locales: ${(locales.keys.toList()..sort()).join(", ")}')
      ..writeln();
    for (final locale in (locales.keys.toList()..sort())) {
      final pct = (coverage(locale) * 100).toStringAsFixed(1);
      final missing = missingKeys(locale).length;
      final untranslated = untranslatedKeys(locale).length;
      b.writeln('  $locale  $pct%   missing: $missing   '
          'identical-to-english: $untranslated');
      final m = missingKeys(locale);
      if (m.isNotEmpty) b.writeln('    missing: ${(m.toList()..sort()).join(", ")}');
      final u = untranslatedKeys(locale);
      if (u.isNotEmpty) b.writeln('    untranslated: ${(u.toList()..sort()).join(", ")}');
      final k = unknownKeys(locale);
      if (k.isNotEmpty) b.writeln('    unknown (dead) keys: ${(k.toList()..sort()).join(", ")}');
    }
    return b.toString();
  }
}

/// Entry point: prints the report and exits non-zero when a locale is missing a
/// template key, so CI can gate on it.
void main(List<String> args) {
  final arb = ArbCoverage.load();
  stdout.write(arb.report());

  final incomplete = arb.locales.keys.where((l) => arb.missingKeys(l).isNotEmpty).toList();
  if (incomplete.isNotEmpty) {
    stderr.writeln('\nFAIL: incomplete locales: ${incomplete.join(", ")}');
    stderr.writeln('A locale that is not 100% must not ship: users get a mixed-language UI.');
    exit(1);
  }
  stdout.writeln('\nOK: every locale covers every template key.');
}
