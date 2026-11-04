/// Carries the organization assertion and interprets its refusal.
///
/// The server contract this implements (`EnforceTenantScope`):
///
///   * the tenant is a property of the **credential** — login/refresh stamp
///     the token with a single active membership, or with nothing;
///   * `X-Tenant` is an **assertion**: sending a different id than the
///     credential resolves to is `403 TENANT_MISMATCH`;
///   * a bearer client with no stamp and no assertion but with memberships also
///     gets `TENANT_MISMATCH` (the client must say which one);
///   * an assertion backed by an active membership *resolves* the tenant for a
///     bearer client.
///
/// Two consequences shape this file:
///
///  * The header is sent **only when the user has selected an organization**.
///    A single-membership user works today because the token carries the
///    stamp; sending a stale remembered id would break exactly the users who
///    need no switcher.
///  * A mismatch is not retried and not swallowed. The local selection is
///    cleared and recorded, so the UI can offer a fresh login. Retrying
///    without the header would silently move the user into the credential's
///    tenant — the opposite of what they asked for.
library;

import 'package:dio/dio.dart';

import '../security/tenant_store.dart';
import 'api_exception.dart';

class TenantInterceptor extends Interceptor {
  TenantInterceptor(this._tenants);

  final TenantStore _tenants;

  /// The wire header. `X-Quiz-Tenant` is accepted by the server as a legacy
  /// alias; the client sends only the canonical one.
  static const String header = 'X-Tenant';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final tenantId = await _tenants.read();
    if (tenantId != null) {
      options.headers[header] = '$tenantId';
    } else {
      // Defensive: if a previous attempt put one on these options (a retry
      // clones them), an unselected client must not keep asserting it.
      options.headers.remove(header);
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final failure = _failureOf(err);
    if (failure != null) {
      // Awaited: the stale assertion has to be gone before the caller reacts.
      // A re-login request that still carried it would 403 for the same reason
      // and look like a credentials problem.
      await _tenants.reportFailure(failure);
    }
    handler.next(err);
  }

  /// The tenant failure this error represents, if any.
  ///
  /// Reads the already-mapped [ApiException] when present. `AuthInterceptor`
  /// maps JSON error bodies, but interceptor `onError` runs in reverse order:
  /// this one sits after auth on the request path, so on the way out it runs
  /// *before* auth has mapped the body. Both shapes therefore have to be
  /// understood.
  TenantFailure? _failureOf(DioException err) {
    final mapped = err.error;
    if (mapped is ApiException) return _kindOf(mapped);

    final body = err.response?.data;
    if (body is Map<String, dynamic>) {
      return _kindOf(
        ApiException.fromJson(err.response?.statusCode ?? 0, body),
      );
    }

    return null;
  }

  TenantFailure? _kindOf(ApiException exception) {
    if (exception.isTenantMismatch) return TenantFailure.mismatch;
    if (exception.isTenantInactive) return TenantFailure.inactive;
    return null;
  }
}
