# DLU LMS Network Evidence

**Observed:** 2026-08-14 ICT

**Safety:** Read-only, minimal requests. No cookie, Authorization header, credential, token, `sesskey`, identifier value or raw private response is stored.

| ID | Trigger | Method | Sanitized Path | Status | Content Type | Moodle Function | Purpose | Evidence |
| -- | ------- | ------ | -------------- | ------ | ------------ | --------------- | ------- | -------- |
| `NET-NAV-001` | Open authenticated Dashboard | GET | `/my/` | `UNKNOWN` — browser timing API did not expose it | `text/html` | N/A | Load current-user Dashboard | `VERIFIED_NETWORK` + `VERIFIED_UI` |
| `NET-NAV-002` | Open `COURSE-A` | GET | `/course/view.php?id=<redacted>` | `UNKNOWN` — browser timing API did not expose it | `text/html` | N/A | Load one enrolled course | `VERIFIED_NETWORK` + `VERIFIED_UI` |
| `NET-NAV-003` | Open current-user Profile | GET | `/user/profile.php?id=<redacted>` | `UNKNOWN` — browser timing API did not expose it | `text/html` | N/A | Load profile UI | `VERIFIED_NETWORK` + `VERIFIED_UI` |
| `NET-NAV-004` | Open Calendar | GET | `/calendar/view.php?<redacted>` | `UNKNOWN` — browser timing API did not expose it | `text/html` | N/A | Load calendar UI | `VERIFIED_NETWORK` + `VERIFIED_UI` |
| `NET-NAV-005` | Open current-user grades overview | GET | `/grade/report/overview/index.php` | `UNKNOWN` — browser timing API did not expose it | `text/html` | N/A | Load own grade overview | `VERIFIED_NETWORK` + `VERIFIED_UI` |
| `NET-REST-001` | Anonymous REST entrypoint check; no parameters | GET | `/webservice/rest/server.php` | `403` | `text/html` | `UNKNOWN` | Determine whether the standard REST entrypoint accepts an unauthenticated probe | `VERIFIED_NETWORK` |
| `NET-TOKEN-001` | Anonymous token entrypoint check; no credentials | GET | `/login/token.php` | `200` | `application/json` | N/A | Inspect service-enablement response without attempting login | `VERIFIED_NETWORK` |
| `NET-TOKEN-002` | Moodle mobile site check; no credentials | GET | `/login/token.php?appsitecheck=1` | `200` | `application/json` | N/A | Use the endpoint's read-only mobile availability check | `VERIFIED_NETWORK` |

## Web Services conclusion

Both token checks returned a JSON exception envelope whose `errorcode` was `enablewsdescription`; neither response contained `token`, `privatetoken`, password or `sesskey` fields. The mobile site-check response did not contain the expected `appsitecheck` success field.

Moodle's official `login/token.php` source for the inspected stable branches throws `enablewsdescription` when the site-wide `enablewebservices` configuration is false, before credential parsing or the `appsitecheck` success branch. DLU's exact Moodle version remains `UNKNOWN`, so the source comparison does not establish a version. It does support this DLU-specific conclusion:

```text
MOODLE_WEB_SERVICES_NOT_ENABLED
```

The REST `403` is recorded independently; it does not identify whether the denial came from Moodle, LiteSpeed or an upstream rule. No service shortname or Web Service function was supplied or guessed, and no login/API function POC was attempted.

## AJAX observation limit

No `/lib/ajax/service.php` resource entry was exposed by the browser timing buffer during the bounded Dashboard observation. This is not proof that the LMS never uses Moodle AJAX. No UI action was triggered merely to manufacture network traffic because preferences, notification read state or other server state could change.

## Official source used for interpretation

- Moodle 4.5 stable `login/token.php`: <https://github.com/moodle/moodle/blob/MOODLE_405_STABLE/login/token.php#L25-L36>
- Moodle 4.1 stable `login/token.php`: <https://github.com/moodle/moodle/blob/MOODLE_401_STABLE/login/token.php>

These are `VERIFIED_OFFICIAL_DOC` references for the meaning of the standard source branch only, not proof of DLU's version or enabled service configuration.
