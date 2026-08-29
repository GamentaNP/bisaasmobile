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
  internalError('INTERNAL_ERROR'),
  serviceUnavailable('SERVICE_UNAVAILABLE'),
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

  @override
  String toString() =>
      'ApiException($statusCode $code: $message${requestId != null ? " req=$requestId" : ""})';
}
