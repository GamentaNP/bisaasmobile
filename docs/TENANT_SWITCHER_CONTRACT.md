# Organization switcher — the API contract (delivered)

**Status:** **delivered by the server on 2026-11-04** and wired in the client.
This file started as a proposal; the server shipped the route while the client
work was in flight, so the "what is missing" section is kept only as history.

**Rows:** TN-09 (Flutter organization context + switcher) / P5-22.

## The route

```
GET /api/v1/me/tenants
Authorization: Bearer <PAT>
```

Deliberately **outside** the tenant-scoped v1 group (`routes/api/v1.php:150`,
`App\Http\Controllers\Api\V1\Me\MeTenantsController`). The users it serves —
multi-membership bearer clients holding an unstamped token — are the ones
`EnforceTenantScope` fails closed on with `403 TENANT_MISMATCH`; inheriting
`tenant.scope` here would leave that ambiguity permanently unresolvable.

**Scope:** credential-scoped. Active memberships **plus active owned
organizations** (ownership counts as membership in `EnforceTenantScope`).
Inactive organizations and lapsed memberships are withheld, so every returned
id is an `X-Tenant` value the middleware accepts.

**Response** (canonical envelope, note the `tenants` key):

```json
{
  "success": true,
  "data": {
    "tenants": [
      { "id": 12, "name": "Acme Engineering", "slug": "acme-engineering", "role": "admin" },
      { "id": 34, "name": "Kathmandu Chapter", "slug": "kathmandu-chapter", "role": "owner" }
    ]
  },
  "message": "Tenant memberships retrieved",
  "timestamp": "2026-11-04T00:00:00+00:00",
  "api_version": "v1"
}
```

Field contract:

| Field | Type | Notes |
|---|---|---|
| `id` | integer | `quiz_tenants.id`; what the client sends as `X-Tenant` |
| `name` | string | display name |
| `slug` | string | `quiz_tenants.slug` |
| `role` | string | stored role; an owned organization without a membership row reports `owner` |

**Ordering:** `name`, then `id`. **Size:** a bounded snapshot, not a paginated
collection — a user's memberships are a handful by construction, so there is no
cursor. **Errors:** ordinary envelope; `401 AUTH_UNAUTHENTICATED` when the
bearer is missing or invalid. No `X-Tenant` is required or expected.

## What the client does with it

| Piece | Where |
|---|---|
| Fetch + parse (`data.tenants`) | `lib/features/organization/data/organization_remote_data_source.dart` |
| Entity (id, name, slug, role) | `lib/features/organization/domain/entities/organization.dart` |
| Cached list + selection state | `organizationMembershipsProvider`, `organizationControllerProvider` |
| Switcher screen (only reachable with a list) | `lib/features/organization/presentation/screens/organization_switcher_screen.dart` |
| Persistent selection (secure storage, cleared on logout/mismatch) | `lib/core/security/tenant_store.dart` |
| `X-Tenant` assertion + `TENANT_MISMATCH` handling | `lib/core/network/tenant_interceptor.dart` |

A failure fetching the list propagates (the screen offers Retry); it never
renders as "you belong to no organizations". Zero rows is a legitimate answer
and hides the switcher entry — it is not an error.

## History — what was missing before 2026-11-04

`GET /me` returned no tenant and the OpenAPI document listed no
membership-enumerating path; `TenantTokenStamper` refuses to stamp anything for
a multi-membership user; `EnforceTenantScope` answers `TENANT_MISMATCH` for
that user unless they assert a backed `X-Tenant`. The client therefore could
not enumerate the ids a switcher needs, and the initial scaffold used a
compile-time `--dart-define` list as an operator override. That define is gone:
the server list is now the only source, so no build can invent an organization.
