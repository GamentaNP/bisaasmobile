# Organization switcher — the API contract the client needs

**Status:** proposal. No server route exists for this today, and the client does
not invent one (`AGENTS.md`: verify a route before calling it).

**Row:** TN-09 (Flutter organization context + switcher) / P5-22.

## What the client already has (2026-11-04)

* `TenantStore` persists one optional organization id in
  `flutter_secure_storage`, cleared on logout, account deletion and
  `TENANT_MISMATCH`.
* `TenantInterceptor` sends `X-Tenant: <id>` **only** when that selection
  exists. Single-membership users keep working through the credential stamp.
* `403 TENANT_MISMATCH` is a typed `ApiErrorCode.tenantMismatch`, the local
  selection is cleared, and the UI offers re-authentication.
* A switcher screen exists, but it is only reachable when a list is available.
  Today the only source is the compile-time
  `--dart-define=TENANT_DIRECTORY='[{"id":1,"name":"…"}]'`; with no define the
  settings entry is hidden and a deep link shows "no organizations available".

## What is missing

The caller's memberships cannot be enumerated. Verified against
`C:\laragon\www\bisaas`:

| Surface | What it returns |
|---|---|
| `GET /api/v1/me` | user only — no tenant |
| OpenAPI (`/api/v1/openapi.json`) | no membership-list path |
| `/tenant-invitations/{token}/acceptance` | accepts one invitation; lists nothing |
| `/tenants/{slug}/sso/*` | per-slug SSO; requires knowing the slug already |

`TenantTokenStamper` deliberately stamps **nothing** for a user with more than
one active membership, and `EnforceTenantScope` answers `TENANT_MISMATCH` for
that user unless they assert a membership-backed `X-Tenant`. So a
multi-organization user can authenticate but cannot discover which ids are
valid — the one thing the switcher needs.

## Proposed route

```
GET /api/v1/me/tenants
Authorization: Bearer <PAT>
X-Tenant: not required
```

**Scope:** credential-scoped. Return the organizations the *authenticated user*
has an **active** `quiz_tenant_memberships` row in (or owns via
`quiz_tenants.owner_id`). Never return the platform pool, never another user's
memberships, never an organization the caller can only reach by id.

**Response** (canonical envelope, `data` is a list):

```json
{
  "success": true,
  "data": [
    {
      "id": 12,
      "name": "Acme Engineering",
      "slug": "acme-engineering",
      "role": "admin",
      "is_active": true
    },
    {
      "id": 34,
      "name": "Kathmandu Chapter",
      "slug": "kathmandu-chapter",
      "role": "learner",
      "is_active": false
    }
  ],
  "message": "ok",
  "timestamp": "2026-11-04T00:00:00+00:00",
  "api_version": "v1"
}
```

Field contract:

| Field | Type | Rules |
|---|---|---|
| `id` | integer | `quiz_tenants.id`; what the client sends as `X-Tenant` |
| `name` | string | display name, non-empty |
| `slug` | string | `quiz_tenants.slug` |
| `role` | string | stored role: `owner` \| `admin` \| `educator` \| `learner` |
| `is_active` | boolean | mirrors `QuizTenant::isActive()`; an inactive organization is listed so the client can explain it, but cannot be selected |

**Ordering:** active organizations first, then by `name`. **Size:** a user's
membership count is bounded by invitations/SCIM; if the server ever expects a
large list it should paginate with the same cursor contract as the four
question collections, and the client will add the walk here. For now a plain
list under `data` is enough.

**Errors:** ordinary envelope — `401 AUTH_UNAUTHENTICATED` when the bearer is
missing/invalid. This route must **not** require `X-Tenant` and must not be
tenant-scoped: it is the route a user calls *because* they do not yet know
which organization to assert.

## Client work when the route ships

1. Add `OrganizationRemoteDataSource.fetchMemberships()` calling
   `/me/tenants`, parsing with `Organization.fromJson` (already implemented).
2. In `OrganizationDirectory`, replace the compile-time source with that call
   when the user is authenticated; keep the define as an operator override for
   provisioned builds.
3. The settings tile and the switcher screen need no change: they already read
   `OrganizationContext.organizations`.
4. Pick one policy for `is_active: false`: list-and-disable (current screen) or
   hide. The screen currently disables, so that decision is already made.

Nothing in the client may derive memberships from anything else — no guessing
an id, no "first organization" fallback, no local role inference.
