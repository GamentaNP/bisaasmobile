/// A membership-bearing organization the caller may act as.
///
/// ADR-002 calls this "organization" in product copy and keeps `tenant` in the
/// API and schema. This entity is the product-side view: the fields a switcher
/// needs, and nothing else. It is deliberately **not** parsed from any
/// endpoint today — there is no membership-list endpoint (see
/// `OrganizationDirectory`).
library;

class Organization {
  const Organization({
    required this.id,
    required this.name,
    this.slug,
    this.role,
    this.isActive = true,
  });

  /// `quiz_tenants.id` — the value that travels in `X-Tenant`.
  final int id;

  final String name;
  final String? slug;

  /// `owner` / `admin` / `educator` / `learner`, as the server stores them.
  /// Null when the source did not publish it; the switcher does not invent a
  /// role.
  final String? role;

  /// An inactive organization cannot be acted as (`EnforceTenantScope` aborts
  /// 403 "Tenant inactive"). The switcher shows it disabled rather than hiding
  /// it, so a user whose workspace was closed understands why.
  final bool isActive;

  /// Parses the shape the proposed `GET /api/v1/me/tenants` would publish.
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
    final isActive = json['is_active'];
    return Organization(
      id: id,
      name: name,
      slug: slug is String && slug.isNotEmpty ? slug : null,
      role: role is String && role.isNotEmpty ? role : null,
      isActive: isActive is! bool || isActive,
    );
  }
}
