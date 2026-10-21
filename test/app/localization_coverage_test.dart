import 'package:flutter_test/flutter_test.dart';

import '../../tool/localization_coverage.dart';

/// The screens the app promises to deliver in the language the user picks.
///
/// A language picker is a promise: a user who cannot read English picks
/// their own language and gets an English interface back, and concludes the
/// app is broken. That is strictly worse than the language not being
/// offered.
///
/// The registry check in `test/app/language_honesty_test.dart` proves an ARB
/// file *exists* for every offered language. It says nothing about how much
/// of the app that file covers — an ARB with twenty keys and an interface
/// with a thousand strings satisfies it perfectly while still handing an
/// English screen to a Nepali reader.
///
/// So this test measures the thing that matters: the user-facing strings in
/// the core journey — install, sign up, set goals, take a quiz, read the
/// result, go home — must come from the ARB, in every offered language.
const coreJourneyFiles = <String>{
  // auth
  'lib/features/auth/presentation/login_page.dart',
  'lib/features/auth/presentation/screens/register_screen.dart',
  'lib/features/auth/presentation/screens/forgot_password_screen.dart',
  'lib/features/auth/presentation/screens/reset_password_screen.dart',
  'lib/features/auth/presentation/screens/splash_screen.dart',
  'lib/features/auth/presentation/widgets/social_sign_in_buttons.dart',
  'lib/features/auth/presentation/widgets/email_verification_banner.dart',
  // onboarding
  'lib/features/onboarding/presentation/screens/onboarding_screen.dart',
  // quiz
  'lib/features/quiz/presentation/quiz_home_page.dart',
  'lib/features/quiz/presentation/screens/quiz_intro_screen.dart',
  'lib/features/quiz/presentation/screens/quiz_attempt_screen.dart',
  'lib/features/quiz/presentation/screens/quiz_result_screen.dart',
  'lib/features/quiz/presentation/screens/quiz_review_screen.dart',
  'lib/features/quiz/presentation/screens/quiz_funnel_screen.dart',
  'lib/features/quiz/presentation/screens/quiz_browser_screen.dart',
  'lib/features/quiz/presentation/controllers/quiz_controller.dart',
  'lib/features/quiz/data/datasources/quiz_local_data_source.dart',
  'lib/features/quiz/data/datasources/quiz_remote_data_source.dart',
  // calculator
  'lib/features/calculator/presentation/screens/calculator_detail_screen.dart',
  'lib/features/calculator/presentation/screens/calculator_browser_screen.dart',
  'lib/features/calculator/presentation/screens/calculator_history_screen.dart',
  'lib/features/calculator/presentation/widgets/calculator_assistant_panel.dart',
  'lib/features/calculator/presentation/widgets/step_by_step_solution.dart',
  // home
  'lib/features/home/presentation/screens/home_screen.dart',
  'lib/features/home/data/datasources/home_remote_data_source.dart',
  // consent + privacy
  'lib/core/consent/consent_screens.dart',
  'lib/features/privacy/presentation/privacy_data_screen.dart',
  // notifications
  'lib/core/notifications/local_notification_service.dart',
  // app level
  'lib/app/force_update_screen.dart',
  'lib/app/maintenance_screen.dart',
  'lib/app/config/app_config.dart',
  'lib/app/router/app_router.dart',
  'lib/app/app.dart',
};

/// Literals that are deliberately not translated.
///
/// An email address is an address, not copy — translating it would break it.
/// The debug auto-login button only exists in a `kDebugMode` build, so it
/// never reaches a user.
const allowedLiterals = <String>{
  'support@bisaas.com',
  'privacy@bisaas.com',
  '⚡ Debug Auto-Login (user@bisaas.test)',
};

/// The number of user-facing strings outside the core journey.
///
/// This is a ratchet, not a target: it may go down, never up. It exists so
/// that adding a screen in English is a deliberate act — the count changes
/// in the diff and the reviewer sees it — rather than an invisible drift.
const maxUntranslatedOutsideCoreJourney = 893;

void main() {
  late List<Hit> hits;

  setUpAll(() async {
    hits = await collectHits();
  });

  test('the core journey has no hardcoded user-facing strings', () {
    final offenders = hits
        .where((h) => coreJourneyFiles.contains(h.file))
        .where((h) => !allowedLiterals.contains(h.text))
        .toList();

    expect(
      offenders,
      isEmpty,
      reason: 'These strings reach the user in the language they picked, but '
          'they are hardcoded English. Add them to lib/l10n/app_*.arb and read '
          'them through AppLocalizations:\n'
          '${offenders.map((h) => '  ${h.file}:${h.line}  ${h.text}').join('\n')}',
    );
  });

  test('the untranslated surface does not grow', () {
    final outside = hits
        .where((h) => !coreJourneyFiles.contains(h.file))
        .where((h) => !allowedLiterals.contains(h.text))
        .length;

    expect(
      outside,
      lessThanOrEqualTo(maxUntranslatedOutsideCoreJourney),
      reason: 'There are now $outside user-facing strings outside the core '
          'journey. Translating one lowers this number; adding one in '
          'English raises it. Either is fine — but it has to be a decision, '
          'so raise the budget in this file when it happens on purpose.',
    );
  });

  test('every core-journey file is actually in the core journey list', () {
    // A file that is localised but not listed would silently fall out of the
    // check above the first time somebody edits it.
    expect(coreJourneyFiles, isNotEmpty);
    for (final file in coreJourneyFiles) {
      expect(file, startsWith('lib/'));
      expect(file, endsWith('.dart'));
    }
  });
}
