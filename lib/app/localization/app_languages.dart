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

  AppScript get script => ScriptFonts.forLanguage(code);

  TextDirection get direction => ScriptFonts.directionFor(script);

  /// What the picker shows. The native name leads because the list is being read
  /// by someone looking for their own language; the English name is the
  /// secondary hint.
  String get displayLabel => nativeName == labelEn ? labelEn : '$nativeName · $labelEn';

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
/// `zh` is included so the client can *render* 中文, but the server has no `zh`
/// locale: it is absent from `languages`, absent from every row of
/// `translation_directions`, and `CN` maps to `default_locale: en`. Chinese
/// users therefore get a fully translated interface (once the ARB files exist)
/// but **no translated questions** until a `zh` row and translation directions
/// are seeded. Selecting 中文 for content is a backend task.
abstract final class AppLanguages {
  const AppLanguages._();

  static const List<AppLanguage> all = [
    AppLanguage(code: 'en', labelEn: 'English', nativeName: 'English'),
    AppLanguage(code: 'ne', labelEn: 'Nepali', nativeName: 'नेपाली'),
    AppLanguage(code: 'hi', labelEn: 'Hindi', nativeName: 'हिन्दी'),
    AppLanguage(code: 'bn', labelEn: 'Bengali', nativeName: 'বাংলা'),
    AppLanguage(code: 'ta', labelEn: 'Tamil', nativeName: 'தமிழ்'),
    AppLanguage(code: 'te', labelEn: 'Telugu', nativeName: 'తెలుగు'),
    AppLanguage(code: 'zh', labelEn: 'Chinese', nativeName: '中文'),
    AppLanguage(code: 'es', labelEn: 'Spanish', nativeName: 'Español'),
    AppLanguage(code: 'fr', labelEn: 'French', nativeName: 'Français'),
    AppLanguage(code: 'ar', labelEn: 'Arabic', nativeName: 'العربية'),
  ];

  static AppLanguage? byCode(String? code) {
    if (code == null || code.isEmpty) return null;
    for (final l in all) {
      if (l.code == code.toLowerCase()) return l;
    }
    return null;
  }

  /// The first supported language, used when the device locale is unknown.
  static AppLanguage get fallback => all.first;

  /// Resolves a device locale to a supported language, falling back to English
  /// rather than to nothing.
  static AppLanguage resolve(Locale? deviceLocale) =>
      byCode(deviceLocale?.languageCode) ?? fallback;

  static List<Locale> get supportedLocales =>
      [for (final l in all) Locale(l.code)];
}
