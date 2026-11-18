/// A membership-bearing organization the caller may act as.
///
/// ADR-002 calls this "organization" in product copy and keeps `tenant` in the
/// API and schema. This entity is the product-side view: the fields
/// `GET /api/v1/me/tenants` publishes, and nothing else.
///
/// The server withholds inactive organizations and lapsed memberships, so
/// every row is an `X-Tenant` value `EnforceTenantScope` accepts. There is no
/// `is_active` field on the wire and no inactive row to render — an
/// organization that closes mid-session is reported as `TENANT_INACTIVE` on a
/// request and handled by the global gate, not by a locally-computed flag.
library;

class Organization {
  const Organization({
    required this.id,
    required this.name,
    this.slug,
    this.role,
  });

  /// `quiz_tenants.id` — the value that travels in `X-Tenant`.
  final int id;

  final String name;
  final String? slug;

  /// `owner` / `admin` / `educator` / `learner`, as the server stores them.
  /// Null when the source did not publish it; the switcher does not invent a
  /// role.
  final String? role;

  /// Parses the shape of `GET /api/v1/me/tenants`.
  ///
  /// Throws [FormatException] on a payload it cannot trust, rather than
  /// fabricating an id or an empty name: an id is what the assertion sends,
  /// and a guessed one is a request into an organization the user may not
  /// belong to.
  factory Organization.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int || id <= 0) {
      throw const FormatException('organization id must be a positive integer');
    }
    final name = json['name'];
    if (name is! String || name.trim().isEmpty) {
      throw const FormatException(
        'organization name must be a non-empty string',
      );
    }
    final slug = json['slug'];
    final role = json['role'];
    return Organization(
      id: id,
      name: name,
      slug: slug is String && slug.isNotEmpty ? slug : null,
      role: role is String && role.isNotEmpty ? role : null,
    );
  }
}
