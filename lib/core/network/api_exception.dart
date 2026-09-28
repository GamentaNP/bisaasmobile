/// Maps `error.code` registry at
/// `C:\laragon\www\bisaas\app\Http\Support\ApiErrorCode` + `MOBILE_API_INTEGRATION_GUIDE.md:91`.
library;

/// Machine-readable codes are frozen per contract version — treat unknown as generic.
enum ApiErrorCode {
  authUnauthenticated('AUTH_UNAUTHENTICATED'),
  authInvalidCredentials('AUTH_INVALID_CREDENTIALS'),
  authTokenExpired('AUTH_TOKEN_EXPIRED'),
  authAccountDisabled('AUTH_ACCOUNT_DISABLED'),
  authEmailUnverified('AUTH_EMAIL_UNVERIFIED'),
  authSocialFailed('AUTH_SOCIAL_FAILED'),
  authSocialDisabled('AUTH_SOCIAL_DISABLED'),
  authRegistrationDisabled('AUTH_REGISTRATION_DISABLED'),
  unauthorized('UNAUTHORIZED'),
  forbidden('FORBIDDEN'),
  validationError('VALIDATION_ERROR'),
  idempotencyConflict('IDEMPOTENCY_CONFLICT'),
  notFound('NOT_FOUND'),
  rateLimitExceeded('RATE_LIMIT_EXCEEDED'),
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

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.details,
    this.errors,
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
    final errors = body['errors'];
    return ApiException(
      statusCode: statusCode,
      code: ApiErrorCode.fromRaw(rawCode),
      message: (err?['message'] as String?) ??
          (body['message'] as String?) ??
          'Request failed',
      details: details,
      errors: errors is Map ? errors.cast<String, dynamic>() : null,
      requestId: requestId ??
          (body['request_id'] as String?) ??
          (err?['request_id'] as String?),
    );
  }

  final int statusCode;
  final ApiErrorCode code;
  final String message;
  final Object? details;
  final Map<String, dynamic>? errors;
  final String? requestId;

  bool get isAuthError =>
      code == ApiErrorCode.authUnauthenticated ||
      code == ApiErrorCode.authTokenExpired ||
      statusCode == 401;

  bool get isValidation => code == ApiErrorCode.validationError || statusCode == 422;

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
      'ApiException($statusCode $code: $message${requestId != null ? " req=$requestId" : ""})';
}
