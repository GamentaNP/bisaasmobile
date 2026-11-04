/// `GET /api/v1/me/tenants` — the organizations the caller may assert.
///
/// The server route (verified 2026-11-04 in `C:\laragon\www\bisaas`,
/// `routes/api/v1.php:150`, `MeTenantsController`) exists precisely for this
/// feature. It sits **outside** the tenant-scoped v1 group on purpose: the
/// users it serves — multi-membership bearer clients with an unstamped token —
/// are the ones `EnforceTenantScope` fails closed on with `403
/// TENANT_MISMATCH`, so the list is how the ambiguity gets resolved.
///
/// Response shape:
///
/// ```json
/// {
///   "success": true,
///   "data": {
///     "tenants": [
///       {"id": 12, "name": "Acme Engineering", "slug": "acme", "role": "admin"}
///     ]
///   },
///   "message": "Tenant memberships retrieved"
/// }
/// ```
///
/// Notes that matter to the client:
///
///  * the list is under `data.tenants`, not directly under `data`;
///  * **inactive organizations and lapsed memberships are withheld** — every
///    row is an `X-Tenant` value the middleware will accept, so there is no
///    `is_active` field to handle;
///  * it is a bounded snapshot, not a paginated collection, so there is no
///    cursor to walk;
///  * zero rows is a legitimate answer (a platform-pool user), so an empty
///    list is data, while a malformed body is a [ContractViolation].
library;

import 'package:dio/dio.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/network/envelope.dart';
import '../domain/entities/organization.dart';

class OrganizationRemoteDataSource {
  const OrganizationRemoteDataSource(this._dio);

  final Dio _dio;

  static const String endpoint = '/me/tenants';

  Future<List<Organization>> fetchMemberships() async {
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    final data = requireDataMap(res.data, endpoint: endpoint);

    final rows = data['tenants'];
    if (rows is! List) {
      throw const ContractViolation(
        'Expected a `tenants` list under `data`',
        endpoint: endpoint,
      );
    }

    final organizations = <Organization>[];
    for (final row in rows) {
      if (row is! Map<String, dynamic>) {
        throw const ContractViolation(
          'A tenants entry is not an object',
          endpoint: endpoint,
        );
      }
      try {
        organizations.add(Organization.fromJson(row));
      } on FormatException catch (e) {
        // One malformed row invalidates the list: dropping it would hide an
        // organization the user belongs to, and the switcher would silently
        // offer a subset of the truth.
        throw ContractViolation(
          'Tenants entry not understood: ${e.message}',
          endpoint: endpoint,
        );
      }
    }

    return List<Organization>.unmodifiable(organizations);
  }
}
