# Supabase API Contract

**Version:** Draft 1 / local foundation

**Runtime status:** `BLOCKED — SUPABASE_PROJECT_CONNECTION_REQUIRED`

## Purpose

This contract covers application-owned mobile preferences only. It is not a Moodle API, identity provider, academic-data API, or generic backend proxy.

## Authentication contract

- Every request requires a verified, non-anonymous authenticated JWT.
- JWT `sub` must be the approved stable UUID for the current DLU principal and must resolve through `auth.uid()`.
- A JWT with `is_anonymous: true` has no permitted row operation.
- Missing, expired, invalid, mismatched, or unverified identity context fails closed.
- Email, student code, display name, client role, and `user_metadata` are not authorization inputs.
- The Flutter client may use only a runtime-provided publishable project key. Secret/service-role keys and database credentials are server-only and are not part of this client contract.

The token exchange/third-party JWT mechanism is intentionally unspecified until DLU supplies and approves the authentication contract. No alternate Supabase signup/login is allowed as a workaround.

## Resource: `mobile_preferences`

Canonical representation:

```json
{
  "owner_id": "11111111-1111-4111-8111-111111111111",
  "theme_mode": "system",
  "created_at": "2026-08-16T00:00:00Z",
  "updated_at": "2026-08-16T00:00:00Z"
}
```

The values above are schema examples, not a real user or production payload.

| Operation | Data API route | Allowed input | Result | Moodle dependency | Security rule |
|---|---|---|---|---|---|
| Select own preference | `GET /rest/v1/mobile_preferences` through the typed SDK gateway | No UI-selected owner; gateway adds the authenticated UUID filter | Zero or one row | None | RLS enforces `owner_id = auth.uid()`; response ownership is verified again in the data source |
| Save theme preference | `POST /rest/v1/rpc/save_mobile_theme_preference` | `{ "p_theme_mode": "system|light|dark" }` | One atomically inserted/updated owned row | None | Security-invoker function derives owner from `auth.uid()`; table grants + INSERT/UPDATE RLS remain authoritative |
| Delete | No route exposed by the repository | None | Forbidden | None | No grant and no policy |

`theme_mode` accepts only `system`, `light`, or `dark`. `created_at` and `updated_at` are database-controlled. `owner_id` cannot be updated by the client.

The client data source queries by the authenticated owner UUID as an additional performance filter, but RLS remains the authorization boundary. The write RPC has a fixed name and accepts no owner/upstream/function/method selector. A missing row means the domain default is `system`; it is not an API failure and does not authorize fixture fallback.

## Error mapping

| Condition | Domain result |
|---|---|
| No project configuration | `SUPABASE_PROJECT_CONNECTION_REQUIRED` |
| Project exists but approved DLU identity bridge is absent | `SUPABASE_IDENTITY_MAPPING_REQUIRED` |
| No/expired/invalid Supabase user JWT | `SUPABASE_AUTHENTICATED_SESSION_REQUIRED`; clear Supabase session safely |
| RLS or grant rejection | Permission failure; do not retry as anonymous or service role |
| Invalid `theme_mode` | Validation failure |
| Network timeout/unavailable | Retryable network failure with bounded retry |
| Unexpected server/database error | Sanitized backend failure with correlation metadata only |

Raw SQL, access tokens, authorization headers, database messages, project secrets, Moodle payloads, and PII must not appear in user-facing errors or production logs.

## Edge Function contract

There is no callable Edge Function in this milestone. The client must not accept an arbitrary function name, Moodle Web Service function, upstream URL, or HTTP method.

If a later verified use case requires an Edge Function, its endpoint, exact request/response schema, allowed Moodle operation, capability requirement, timeout, payload limit, rate limit, secret source, redaction behavior, and negative tests must be specified before code or deployment. It may not become a transparent Moodle proxy or store Moodle credentials in `public` tables.

## Compatibility and rollout

- Schema changes are additive, reviewed migrations generated through the Supabase CLI.
- Database and Flutter models must be changed together when the contract version changes.
- The SQL contract test must pass on an isolated local/dev project before remote rollout.
- The offline static validator must pass before database-connected tests.
- Data API grants and RLS are both required; one does not replace the other.
- Production enablement requires explicit approval after non-production identity, RLS, advisor, and fail-closed tests pass.
