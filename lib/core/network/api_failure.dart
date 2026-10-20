/// Typed failure plumbing for data sources.
///
/// Contract (AGENTS.md → "Every network call honors `X-Request-Id` logging,
/// `X-RateLimit-*` backoff, and `Retry-After` on 429"):
///
/// A data source MUST NOT collapse a transport failure, a 5xx or a contract
/// drift into an "empty" list. Doing so turns "the server is down" and "you
/// have no rows" into the same pixels, and the user has no way to tell a real
/// empty state from a broken one.
///
/// The rules this file enforces:
///
///  * A failed request throws [ApiException]. The presentation layer catches it
///    and renders an error + retry affordance.
///  * A *successful* request whose body cannot be parsed is a contract drift,
///    and it throws too — never "0 results".
///  * A successful request that genuinely carries zero rows is the only thing
///    that may produce an empty collection.
///
/// [ApiException] already carries the server's frozen `error.code`, the
/// display-safe message, validation `errors`, and the `X-Request-Id` needed for
/// a support report.
library;

import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Converts a caught error into the canonical [ApiException].
///
/// The server's error contract is `{error: {code, message, details}, errors}`
/// with a Laravel-compatible top-level `errors` mirror for 422s
/// (`MOBILE_API_INTEGRATION_GUIDE.md:86-89`). When the body is not JSON at all
/// (a proxy HTML error page, an empty 502) the status code still carries the
/// truth, so the status-derived code is used instead of inventing one.
///
/// A [DioException] becomes the server's own error; an [ApiException] passes
/// through unchanged; anything else (a parse failure, a bug) becomes a
/// generic one that still carries the original message.
ApiException toApiException(Object error) {
  if (error is ApiException) return error;

  if (error is DioException) {
    final status = error.response?.statusCode ?? 0;
    final body = error.response?.data;

    if (body is Map<String, dynamic>) {
      return ApiException.fromJson(
        status == 0 ? 500 : status,
        body,
        requestId: error.requestOptions.headers['X-Request-Id'] as String?,
      );
    }

    // No JSON body. Keep the status code honest; a transport failure (no
    // response at all) is a service-unavailable condition.
    if (status == 0) {
      return ApiException(
        statusCode: 0,
        code: ApiErrorCode.serviceUnavailable,
        message: _transportMessage(error),
      );
    }

    return ApiException(
      statusCode: status,
      code: _codeForStatus(status),
      message: _statusMessage(status),
    );
  }

  return ApiException(
    statusCode: 0,
    code: ApiErrorCode.unknown,
    message: error.toString(),
  );
}

/// Maps an HTTP status to the closest frozen error code.
///
/// Only used when the server did not send a JSON error body — a JSON body
/// always wins because its `error.code` is the contract.
ApiErrorCode _codeForStatus(int status) {
  if (status == 401) return ApiErrorCode.authUnauthenticated;
  if (status == 403) return ApiErrorCode.forbidden;
  if (status == 404) return ApiErrorCode.notFound;
  if (status == 422) return ApiErrorCode.validationError;
  if (status == 426) return ApiErrorCode.upgradeRequired;
  if (status == 429) return ApiErrorCode.rateLimitExceeded;
  if (status >= 500) return ApiErrorCode.serviceUnavailable;
  return ApiErrorCode.unknown;
}

String _statusMessage(int status) {
  if (status == 401) return 'Your session has expired. Please sign in again.';
  if (status == 403) return 'You do not have access to this resource.';
  if (status == 404) return 'Not found.';
  if (status == 422) return 'Some of the submitted values were rejected.';
  if (status == 426) return 'A newer version of the app is required.';
  if (status == 429) return 'Too many requests. Please try again shortly.';
  if (status >= 500) return 'The server is having trouble. Please try again.';
  return 'Request failed with status $status.';
}

String _transportMessage(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'The request timed out. Check your connection and try again.';
    case DioExceptionType.connectionError:
      return 'Could not reach the server. Check your connection and try again.';
    case DioExceptionType.cancel:
      return 'The request was cancelled.';
    case DioExceptionType.badCertificate:
      return 'The server certificate could not be verified.';
    case DioExceptionType.badResponse:
    case DioExceptionType.unknown:
      return e.message ?? 'Network error.';
    // `transformTimeout` was added in Dio 5.7 and is not a transport failure
    // the user can act on beyond retrying.
    case DioExceptionType.transformTimeout:
      return 'The server took too long to deliver the response.';
  }
}

/// Raised when a 2xx response body does not match the documented contract.
///
/// This is *not* an [ApiException]: the server answered, so there is no HTTP
/// status to report. It is a distinct type precisely so the UI can say
/// "the server sent something we don't understand" instead of pretending the
/// user has no data.
class ContractViolation implements Exception {
  const ContractViolation(this.message, {this.endpoint});

  final String message;
  final String? endpoint;

  @override
  String toString() =>
      'ContractViolation(${endpoint ?? '?'}): $message';
}
