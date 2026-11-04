/// Maps `error.code` registry at
/// `C:\laragon\www\bisaas\app\Http\Support\ApiErrorCode` + `MOBILE_API_INTEGRATION_GUIDE.md:91`.
library;

import '../../app/localization/l10n.dart';

/// Machine-readable codes are frozen per contract version — treat unknown as generic.
enum ApiErrorCode {
  authUnauthenticated('AUTH_UNAUTHENTICATED'),
  authInvalidCredentials('AUTH_INVALID_CREDENTIALS'),
  authTokenExpired('AUTH_TOKEN_EXPIRED'),
  authTokenRevoked('AUTH_TOKEN_REVOKED'),
  authAccountDisabled('AUTH_ACCOUNT_DISABLED'),
  authEmailUnverified('AUTH_EMAIL_UNVERIFIED'),
  authMfaRequired('AUTH_MFA_REQUIRED'),
  authSocialFailed('AUTH_SOCIAL_FAILED'),
  authSocialDisabled('AUTH_SOCIAL_DISABLED'),
  authRegistrationDisabled('AUTH_REGISTRATION_DISABLED'),
  unauthorized('UNAUTHORIZED'),
  forbidden('FORBIDDEN'),
  /// `TENANT_MISMATCH` — the `X-Tenant` assertion disagrees with the
  /// credential, or names an organization the user is not an active member of.
  /// Mirrors `App\Http\Support\ApiErrorCode::TenantMismatch` and
  /// `EnforceTenantScope`. The remedy is a fresh login, not a retry, so it is
  /// kept distinct from a bare `FORBIDDEN`.
  tenantMismatch('TENANT_MISMATCH'),
  /// `TENANT_INACTIVE` — the organization exists but is no longer active.
  tenantInactive('TENANT_INACTIVE'),
  validationError('VALIDATION_ERROR'),
  idempotencyConflict('IDEMPOTENCY_CONFLICT'),
  idempotencyKeyRequired('IDEMPOTENCY_KEY_REQUIRED'),
  notFound('NOT_FOUND'),
  rateLimitExceeded('RATE_LIMIT_EXCEEDED'),
  insufficientCoins('INSUFFICIENT_COINS'),
  planUpgradeRequired('PLAN_UPGRADE_REQUIRED'),
  featureDisabled('FEATURE_DISABLED'),
  maintenanceMode('MAINTENANCE_MODE'),
  webhookSecretNotConfigured('WEBHOOK_SECRET_NOT_CONFIGURED'),
  webhookUnauthorized('WEBHOOK_UNAUTHORIZED'),
  internalError('INTERNAL_ERROR'),
  serviceUnavailable('SERVICE_UNAVAILABLE'),
  upgradeRequired('UPGRADE_REQUIRED'),
  /// `ERASURE_REQUIRES_ACCOUNT` — an anonymous GDPR erasure was refused because
  /// the visitor profile is stitched to a real account, so the erasure belongs
  /// to the account-level flow. Mirrors `App\Http\Support\ApiErrorCode`.
  erasureRequiresAccount('ERASURE_REQUIRES_ACCOUNT'),
  unknown('UNKNOWN');

  const ApiErrorCode(this.raw);
  final String raw;

  static ApiErrorCode fromRaw(String? raw) => values.firstWhere(
        (c) => c.raw == raw,
        orElse: () => ApiErrorCode.unknown,
      );
}

/// Localized copy for a status the server did not explain in the body.
/// The server's own localized `message` always wins when it is present —
/// this is what a Nepali reader gets when it is not.
String localizedStatusMessage(int status) {
  if (status == 401) return appL10n().errSessionExpired;
  if (status == 403) return appL10n().errForbidden;
  if (status == 404) return appL10n().errNotFound;
  if (status == 422) return appL10n().errValidationRejected;
  if (status == 426) return appL10n().errUpgradeRequired;
  if (status == 429) return appL10n().errRateLimited;
  if (status == 503) return appL10n().errMaintenance;
  if (status >= 500) return appL10n().errServerTrouble;
  return appL10n().errRequestFailedStatus(status);
}

/// Localized copy for a frozen error code whose body carried no message.
/// Codes a user can act on get their own line; everything else falls through
/// to the status copy.
String localizedCodeFallback(int statusCode, ApiErrorCode code) {
  final l10n = appL10n();
  return switch (code) {
    ApiErrorCode.authInvalidCredentials => l10n.errAuthInvalidCredentials,
    ApiErrorCode.authEmailUnverified => l10n.errAuthEmailUnverified,
    ApiErrorCode.authAccountDisabled => l10n.errAuthAccountDisabled,
    ApiErrorCode.authSocialFailed => l10n.errAuthSocialFailed,
    ApiErrorCode.insufficientCoins => l10n.errInsufficientCoins,
    ApiErrorCode.planUpgradeRequired => l10n.errPlanUpgradeRequired,
    ApiErrorCode.featureDisabled => l10n.errFeatureDisabled,
    ApiErrorCode.idempotencyConflict => l10n.errIdempotencyConflict,
    ApiErrorCode.maintenanceMode => l10n.errMaintenance,
    ApiErrorCode.tenantMismatch => l10n.errTenantMismatch,
    ApiErrorCode.tenantInactive => l10n.errTenantInactive,
    _ => localizedStatusMessage(statusCode),
  };
}

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.details,
    this.requestId,
  });

  factory ApiException.fromJson(
    int statusCode,
    Map<String, dynamic> body, {
    String? requestId,
  }) {
    final err = body['error'] as Map<String, dynamic>?;
    final rawCode = err?['code'] as String? ?? body['code'] as String?;
    final details = err?['details'];
    return ApiException(
      statusCode: statusCode,
      code: ApiErrorCode.fromRaw(rawCode),
      message: (err?['message'] as String?) ??
          (body['message'] as String?) ??
          localizedCodeFallback(statusCode, ApiErrorCode.fromRaw(rawCode)),
      details: details,
      requestId: requestId ??
          (body['request_id'] as String?) ??
          (err?['request_id'] as String?),
    );
  }

  final int statusCode;
  final ApiErrorCode code;
  final String message;
  final Object? details;
  final String? requestId;

  bool get isAuthError =>
      code == ApiErrorCode.authUnauthenticated ||
      code == ApiErrorCode.authTokenExpired ||
      statusCode == 401;

  /// The server refused this request because the organizational scope did not
  /// match the credential.
  ///
  /// Keyed on the code, not on 403: most 403s are a permission refusal that
  /// retrying cannot fix either, but they do not mean "your session belongs to
  /// a different organization". Branching on the status would offer a
  /// re-login to someone who simply lacks a role.
  bool get isTenantMismatch => code == ApiErrorCode.tenantMismatch;

  /// The organization the credential resolves to is closed. A new login does
  /// not reopen it, so the UI must not offer one ([isTenantMismatch] does).
  bool get isTenantInactive => code == ApiErrorCode.tenantInactive;

  bool get isValidation => code == ApiErrorCode.validationError || statusCode == 422;

  /// The server answered `MAINTENANCE_MODE` — the mobile kill switch
  /// (`EnforceMobileKillSwitches`), not a transient outage. The UI can route
  /// to its maintenance surface instead of a retry toast.
  ///
  /// Keys on the code alone: the registry also maps `SERVICE_UNAVAILABLE` and
  /// the whole AI/gateway family to 503 (`ApiErrorCode.php`), and those
  /// feature-scoped refusals must stay ordinary retryable errors, not route
  /// the user to a kill-switch screen while the app is healthy.
  bool get isMaintenance => code == ApiErrorCode.maintenanceMode;

  /// Per-field validation errors.
  ///
  /// The frozen envelope carries them at `error.details` — an object of
  /// field → error list. A validation error with no details serialises `[]`
  /// (the contract requires clients to tolerate that), which yields null
  /// here. The top-level `errors` mirror the integration guide once promised
  /// was never shipped by the server, so it is not parsed at all.
  Map<String, dynamic>? get fieldErrors {
    final d = details;
    if (d is Map && d.isNotEmpty) {
      return d.cast<String, dynamic>();
    }
    return null;
  }

  /// The server refused this build outright (`EnforceAppVersion` → 426,
  /// `AppUpdateRequiredException`). Not a retryable failure: the only fix is a
  /// new install, so the UI must offer a store link rather than a Retry button.
  bool get isAppUpdateRequired =>
      code == ApiErrorCode.upgradeRequired || statusCode == 426;

  /// Minimum version the server demands, from `details.min_version`.
  String? get minRequiredVersion {
    final d = details;
    if (d is Map && d['min_version'] is String) {
      final v = d['min_version'] as String;
      return v.isEmpty ? null : v;
    }
    return null;
  }

  @override
  String toString() =>
      // The **raw** code, not the Dart enum name: the wire value is what the
      // server sent and what a support ticket correlates on.
      'ApiException($statusCode ${code.raw}: $message${requestId != null ? " req=$requestId" : ""})';
}
