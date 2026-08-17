# Supabase App-Owned Data Boundary

**Status:** Local foundation complete; remote connection and deployment blocked.

**Blocker:** `SUPABASE_PROJECT_CONNECTION_REQUIRED`

## Decision

Supabase is an optional backend for data owned exclusively by DLU LMS Mobile. It does not replace Moodle, mirror Moodle tables, or become the source of truth for academic data.

The initial scope contains exactly one table: `public.mobile_preferences`.

| Data | Owner | Why Supabase | Moodle equivalent? | Store? |
|---|---|---|---|---|
| Theme preference | Mobile application user | Synchronize one app-specific UI setting across approved devices | No authoritative Moodle field selected | YES — `mobile_preferences.theme_mode` |
| Course, enrolment, module, assignment | Moodle | No app-owned reason; duplication would create drift | Yes | NO |
| Grade, feedback, submission | Moodle | No app-owned reason; academic authorization belongs to Moodle | Yes | NO |
| Moodle profile, role, capability | Moodle | No app-owned reason; client must not become the authority | Yes | NO |
| Moodle password, token, cookie/session | Runtime identity/security owner | Credentials are not application data | Not applicable | NO |
| Bookmarks/favourites | Unconfirmed | Cross-device sync may be useful, but ownership may overlap Moodle favourites | Possibly; capability/API unknown | DEFER |
| Notification state | Unconfirmed | App-specific read state may be useful only after a real notification source exists | Source/API unknown | DEFER |

No production table named `users`, `profiles`, `courses`, `assignments`, `grades`, `submissions`, or an equivalent Moodle clone may be added without a new reviewed ownership decision.

## `mobile_preferences` contract

| Column | Type | Rule |
|---|---|---|
| `owner_id` | `uuid` | Primary key; equals the authenticated JWT `sub`/`auth.uid()` |
| `theme_mode` | `text` | Required; one of `system`, `light`, `dark`; default `system` |
| `created_at` | `timestamptz` | Database-generated and client-immutable |
| `updated_at` | `timestamptz` | Database-generated; refreshed by an invoker-rights trigger; client-immutable |

`owner_id` is intentionally not a foreign key to `auth.users` yet. Adding that foreign key before DLU identity mapping is approved would assert a lifecycle and identity source that have not been verified.

The primary key is also the RLS ownership lookup index; a second `owner_id` index would be redundant.

## Identity precondition

Remote deployment remains blocked until all of these facts are approved and verified in a non-production environment:

1. DLU confirms the Moodle/SSO authentication method used by the mobile app.
2. A trusted backend produces or exchanges for a Supabase-compatible access token with an immutable UUID `sub` for the same DLU principal.
3. Collision, account merge, account disable, token refresh, and logout/revocation behavior are defined.
4. Anonymous Supabase sign-in remains disabled. A token with `is_anonymous: true` is rejected by every table policy.
5. Identity is not mapped by mutable email, display name, student code, or a client-supplied role.

The repository does not implement a second login screen or create shadow accounts. One DLU login must yield both the Moodle session and the approved Supabase identity context, if Supabase is enabled later.

## Access and lifecycle

- `anon`: no table privileges and no RLS policy.
- Permanent `authenticated` identity: select, insert, and update its own row only.
- Table INSERT privilege is limited to `owner_id` and `theme_mode`; UPDATE is limited to `theme_mode`.
- Flutter writes through the fixed `save_mobile_theme_preference(theme_mode)` invoker-rights RPC. The function derives `owner_id` from `auth.uid()` and performs one atomic insert-or-update; the caller never supplies an owner UUID for a write.
- Delete has no client grant and no policy.
- `service_role`: no app table grant in this baseline because no trusted server use case exists.
- RLS is enabled and forced; every policy combines ownership with anonymous-session rejection.

Preferences contain no academic records or credentials. Retention/deletion requirements must be approved together with the identity lifecycle before a remote rollout.

## Evidence in repository

- CLI-generated migration: `supabase/migrations/20260815172943_create_mobile_preferences.sql`
- Isolated 28-assertion database contract test: `supabase/tests/database/mobile_preferences_rls.test.sql`
- Offline static validator: `tool/validate_supabase_foundation.ps1`
- Local CLI config disables seed, signup, and anonymous sign-in.

Run the offline contract gate with `powershell -ExecutionPolicy Bypass -File tool/validate_supabase_foundation.ps1`. The pgTAP SQL test is ready for an isolated local/dev Supabase database. It must not be run against production. It cannot be executed in the current milestone because no Supabase project is connected and no local Supabase stack is running.
