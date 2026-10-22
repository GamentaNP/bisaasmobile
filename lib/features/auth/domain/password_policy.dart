import 'package:bisaasmobile/app/localization/l10n.dart';

/// Password policy, mirrored from the server so the client never sends a
/// request it knows will be rejected.
///
/// Source of truth: `App\Concerns\PasswordValidationRules::passwordRules()` =
/// `['required', 'string', Password::default(), 'confirmed']`.
///
/// Verified against the running backend rather than read off a docblock — the
/// live endpoint returns exactly:
///
///   password "abc"  -> "The password field must be at least 8 characters."
///   password "Password1!" with a mismatched confirmation
///                   -> "The password field confirmation does not match."
///
/// `Password::default()` on this deployment is **min:8 only** — there is no
/// mixed-case, numeric or symbol requirement, and a password like "abcd1234" is
/// accepted. Do not invent stricter client-side rules: they would reject
/// passwords the server accepts, which is a worse failure than the reverse
/// because the user cannot tell why.
class PasswordPolicy {
  const PasswordPolicy._();

  /// Matches `Password::default()` as configured on the server.
  static const int minLength = 8;

  /// Returns a user-facing message, or null when [password] is acceptable.
  static String? validate(String password) {
    if (password.isEmpty) return appL10n().authPasswordRequired;
    if (password.length < minLength) {
      return appL10n().authPasswordTooShort(minLength);
    }
    return null;
  }

  /// Confirms the two fields match, mirroring the server's `confirmed` rule.
  static String? validateConfirmation(String password, String confirmation) {
    if (confirmation.isEmpty) return appL10n().authPasswordConfirmRequired;
    if (password != confirmation) return appL10n().authPasswordMismatch;
    return null;
  }
}
