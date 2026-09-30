import 'package:flutter/widgets.dart';

import '../theme/script_fonts.dart';

/// One selectable app language.
///
/// Mirrors the server's `languages` registry (`code`, `label_en`, `native_name`,
/// `direction`, `is_ui_locale`) so the picker shows each language in its own
/// script, which is the only way a user who cannot read English can find their
/// language in the list.
@immutable
class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.labelEn,
    required this.nativeName,
    this.isUiLocale = true,
  });

  /// BCP-47 language code, e.g. `ne`.
  final String code;

  /// English name, for anyone who can read it.
  final String labelEn;

  /// Name written in the language itself, e.g. नेपाली.
  final String nativeName;

  final bool isUiLocale;

  AppScript get script => scriptForLanguage(code);

  TextDirection get direction => directionForLanguage(code);

  /// What the picker shows. The native name leads because the list is being read
  /// by someone looking for their own language; the English name is the
  /// secondary hint.
  String get displayLabel => nativeName == labelEn ? labelEn : '$nativeName · $labelEn';

  /// Returns a copy with the given fields replaced, so a server payload can be
  /// normalised (trimmed, lower-cased) without the caller rebuilding the object.
  AppLanguage copyWith({String? code, String? labelEn, String? nativeName, bool? isUiLocale}) {
    return AppLanguage(
      code: code ?? this.code,
      labelEn: labelEn ?? this.labelEn,
      nativeName: nativeName ?? this.nativeName,
      isUiLocale: isUiLocale ?? this.isUiLocale,
    );
  }

  /// Builds a language from a `GET /api/v1/languages` row.
  ///
  /// Returns null for a row that cannot produce a usable picker entry, so a
  /// malformed server row is skipped instead of crashing boot. `direction` is
  /// accepted and intentionally ignored: direction is derived from the script
  /// in [AppLanguage.direction] so that a client bug or a stale server value
  /// cannot make Arabic lay out left-to-right.
  static AppLanguage? fromServer(Map<String, Object?> json) {
    final code = json['code']?.toString().trim().toLowerCase() ?? '';
    if (code.isEmpty) return null;
    final label = (json['label_en'] ?? json['labelEn'])?.toString().trim() ?? '';
    final native = (json['native_name'] ?? json['nativeName'])?.toString().trim() ?? '';
    if (label.isEmpty && native.isEmpty) return null;
    return AppLanguage(
      code: code,
      labelEn: label.isEmpty ? code : label,
      nativeName: native.isEmpty ? (label.isEmpty ? code : label) : native,
      isUiLocale: json['is_ui_locale'] as bool? ?? json['isUiLocale'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) => other is AppLanguage && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

/// The languages the app can render.
///
/// Seeded from the server's `languages` table (verified against the dev
/// database: en, ne, hi, es, fr, ar, bn, ta, te — with `ar` flagged
/// `direction: rtl`), plus `zh`.
///
/// ## Why this is still a client-side list
///
/// The `languages` table is the right source of truth, but **no route exposes
/// it** — `GET /country-languages` returns per-country `default_locale` and
/// `accepted_locales` (Nepal correctly reports `ne` / `[ne, en]`) but not the
/// language registry itself. So the codes below cannot be discovered at
/// runtime. When a `GET /languages` route ships, replace
/// [AppLanguages.fallback] with a fetch and delete the duplicated data; the rest
/// of this file needs no change because it is already keyed on `code`.
///
/// ## Chinese
///
/// `zh` is intentionally NOT seeded. It renders correctly as a script, but the
/// server has no `zh` locale: absent from `languages`, absent from every row of
/// `translation_directions`, and `CN` maps to `default_locale: en`.
///
/// ## Why the seed is only the three languages that are actually translated
///
/// A language picker is a promise. Listing 中文 / বাংলা / தமிழ் when
/// `lib/l10n` has no ARB file for them means a user who cannot read English
/// picks their language, gets an English interface back, and concludes the app
/// is broken. That is strictly worse than the language not being offered.
///
/// So the seed is exactly the set with an ARB file, and it is asserted by
/// `test/app/language_honesty_test.dart`: the registry and the ARB directory
/// must agree, which means adding a language is a two-step change (write the
/// ARB, then add the registry entry) and cannot silently half-happen.
///
/// Translation coverage is a content task, not a client task. When
/// `app_bn.arb` etc. are written, add the registry entry in the same commit and
/// this test starts covering the new language automatically.
abstract final class AppLanguages {
  const AppLanguages._();

  /// Seeded copy of the server registry, used until [adopt] installs a live one.
  ///
  /// Everything is keyed on `code`, so replacing this list needs no other change
  /// in the app.
  static const List<AppLanguage> _seed = [
    AppLanguage(code: 'en', labelEn: 'English', nativeName: 'English'),
    AppLanguage(code: 'ne', labelEn: 'Nepali', nativeName: 'नेपाली'),
    AppLanguage(code: 'hi', labelEn: 'Hindi', nativeName: 'हिन्दी'),
  ];

  /// Registry in effect. Overwritten by [adopt] once `GET /api/v1/languages`
  /// ships, so adding a language worldwide is a server change rather than a
  /// client release.
  static List<AppLanguage> _active = _seed;

  static List<AppLanguage> get all => List.unmodifiable(_active);

  /// Installs a server-supplied registry, replacing the seeded list.
  ///
  /// English is always present and always first, because it is the canonical
  /// fallback: an empty or server-unavailable registry must not be able to leave
  /// the app without a language. A malformed entry is skipped rather than
  /// thrown, because a bad row from the server should degrade the picker, not
  /// crash boot.
  static void adopt(Iterable<AppLanguage> languages) {
    final usable = <AppLanguage>[];
    final seen = <String>{};
    for (final l in languages) {
      final code = l.code.trim().toLowerCase();
      if (code.isEmpty || !seen.add(code)) continue;
      usable.add(l.copyWith(code: code));
    }
    usable.sort((a, b) {
      if (a.code == 'en') return -1;
      if (b.code == 'en') return 1;
      return a.code.compareTo(b.code);
    });
    _active = usable.any((l) => l.code == 'en') ? usable : [..._seed, ...usable];
  }

  /// Restores the seeded registry. Used by tests.
  @visibleForTesting
  static void reset() => _active = _seed;

  static AppLanguage? byCode(String? code) {
    if (code == null || code.isEmpty) return null;
    final needle = code.trim().toLowerCase();
    for (final l in _active) {
      if (l.code == needle) return l;
    }
    return null;
  }

  /// The first supported language, used when the device locale is unknown.
  static AppLanguage get fallback =>
      byCode('en') ?? (byCode(_active.isEmpty ? null : _active.first.code) ??
          const AppLanguage(code: 'en', labelEn: 'English', nativeName: 'English'));

  /// Resolves a device locale to a supported language, falling back to English
  /// rather than to nothing.
  static AppLanguage resolve(Locale? deviceLocale) =>
      byCode(deviceLocale?.languageCode) ?? fallback;

  static List<Locale> get supportedLocales => [for (final l in _active) Locale(l.code)];
}
