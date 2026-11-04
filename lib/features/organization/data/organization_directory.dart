/// Where the switcher's list of organizations comes from.
///
/// ## The server has no membership-list endpoint
///
/// Verified 2026-11-04 against `C:\laragon\www\bisaas`:
///
///   * `GET /api/v1/me` returns the user and **no tenant**;
///   * the OpenAPI document has no path that lists a caller's memberships;
///   * the only tenant-named mobile routes are
///     `/tenant-invitations/{token}/acceptance` and `/tenants/{slug}/sso/*`,
///     neither of which enumerates organizations.
///
/// So this client cannot truthfully render a list. Inventing a route is
/// forbidden by `AGENTS.md`, and guessing an id would send `X-Tenant` into an
/// organization the user may not belong to. The directory therefore has two
/// honest sources:
///
///  1. today: an explicit compile-time `--dart-define=TENANT_DIRECTORY='…'`
///     for a build that is provisioned for one or more known organizations;
///  2. later: `GET /api/v1/me/tenants` (contract proposed in
///     `docs/TENANT_SWITCHER_CONTRACT.md`), plugged in here and nowhere else.
///
/// With neither, `available` is **null** and the switcher is unreachable. That
/// is the fail-closed path: no list, no switch, and the app keeps working for
/// single-membership users through the credential stamp.
library;

import 'dart:convert';

import '../../../core/logging/app_logger.dart';
import '../domain/entities/organization.dart';

class OrganizationDirectory {
  OrganizationDirectory({String? source})
      : _source = source ?? const String.fromEnvironment(defineKey);

  /// The compile-time source, for builds that are provisioned explicitly.
  ///
  /// Shape: `[{"id":1,"name":"Acme","slug":"acme","role":"owner",
  /// "is_active":true}, …]`
  static const String defineKey = 'TENANT_DIRECTORY';

  final String _source;

  List<Organization>? _parsed;
  bool _didParse = false;

  /// The organizations this build may offer, or null when no truthful list is
  /// available.
  ///
  /// An empty list is reported as null on purpose: "the switch is available
  /// and there is nothing in it" is a screen a user should never see, and
  /// treating it as unavailable keeps the settings tile hidden.
  List<Organization>? get available {
    if (!_didParse) {
      _didParse = true;
      _parsed = _parse(_source);
    }
    return _parsed;
  }

  static List<Organization>? _parse(String source) {
    if (source.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(source);
      if (decoded is! List) {
        AppLogger.w(
          '$defineKey is not a JSON list; the organization switcher is unavailable',
        );
        return null;
      }
      final organizations = <Organization>[];
      for (final row in decoded) {
        if (row is! Map<String, dynamic>) continue;
        try {
          organizations.add(Organization.fromJson(row));
        } on FormatException catch (e) {
          // One malformed row invalidates the whole list: dropping it
          // silently would leave the user unable to switch to an
          // organization that actually exists, with no explanation.
          AppLogger.w('$defineKey has an invalid entry: $e');
          return null;
        }
      }
      if (organizations.isEmpty) return null;
      return List<Organization>.unmodifiable(organizations);
    } on Object catch (e) {
      // Never log the payload — it carries organization names and ids.
      AppLogger.w('$defineKey is not valid JSON: $e');
      return null;
    }
  }
}
