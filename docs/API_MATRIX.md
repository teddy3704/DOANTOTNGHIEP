# DLU Moodle API Matrix

**Status:** `BLOCKED_EXTERNAL` — authenticated UI verified, but DLU currently reports Web Services disabled and `0` Moodle Web Service functions are `VERIFIED_API`.

**Updated:** 2026-08-14 ICT

## Service gate

| Item | DLU Evidence | Status | Consequence |
| ---- | ------------ | ------ | ----------- |
| Authenticated web session | `VERIFIED_UI` (`UI-AUTH-001`) | Available in the user-controlled browser | Supports read-only discovery only; browser cookies cannot become app authentication |
| Local login option | `VERIFIED_UI` (`UI-AUTH-OPTION-001`) | Visible | Does not prove approved mobile credential exchange |
| Google OAuth2 option | `VERIFIED_UI` (`UI-AUTH-OPTION-001`) | Visible | Redirect/app-registration/PKCE contract remains `UNKNOWN` |
| Web Services global enablement | `VERIFIED_NETWORK` (`NET-TOKEN-001`, `NET-TOKEN-002`) returned `enablewsdescription` | `MOODLE_WEB_SERVICES_NOT_ENABLED` | Token/site-check flow cannot proceed |
| REST entrypoint | `VERIFIED_NETWORK` (`NET-REST-001`) returned `403 text/html` | Access denied; denial layer `UNKNOWN` | No REST function POC can be claimed |
| External/mobile service | No enabled service evidence | `UNKNOWN` | Service shortname and function allowlist must not be guessed |
| Successful API response | None | `0 VERIFIED_API` | No live DTO/repository may be implemented from HTML |

## Read-only integration matrix

| App Feature | DLU Evidence | Moodle Function | Verified | Permission | Response Verified | Flutter Status |
| ----------- | ------------ | --------------- | -------- | ---------- | ----------------- | -------------- |
| Authentication | `VERIFIED_UI` login options; `VERIFIED_NETWORK` service-disabled response | `UNKNOWN` | NO | Mobile auth policy `UNKNOWN` | NO successful auth response | Production fail-closed; DEV fixture only |
| Site + current user | Authenticated identity UI exists (`UI-AUTH-001`) | `UNKNOWN` | NO | Approved session/token and function permission `UNKNOWN` | NO | `AuthSession` foundation; live mapper/repository absent |
| Own user profile | Profile UI verified (`UI-PROFILE-001`) | `UNKNOWN` | NO | Own-field visibility by API `UNKNOWN` | NO | Profile foundation; live fields/DTO absent |
| My Courses | Course overview verified (`UI-COURSES-001`) | `UNKNOWN` | NO | Enrolment/course visibility by API `UNKNOWN` | NO | Loading/empty/error/retry foundation; live repository blocked |
| One course detail | `COURSE-A` UI verified (`UI-COURSE-001`) | `UNKNOWN` | NO | Course-context API permission `UNKNOWN` | NO | Placeholder detail only |
| Course sections/activities | Section and activity types verified in UI (`UI-COURSE-002`) | `UNKNOWN` | NO | Module visibility/availability by API `UNKNOWN` | NO | Section/module models and repository method absent |
| Course file metadata/download | Protected-file link presence verified (`UI-COURSE-003`) | `UNKNOWN` | NO | File context/service-download policy `UNKNOWN` | NO | Not implemented |
| Own assignments — read only | Assignment activity type observed in `COURSE-A` UI | `UNKNOWN` | NO | Own-assignment/submission scope `UNKNOWN` | NO | Deferred until core live contracts PASS |
| Own grades — read only | Current-user grade overview UI verified (`UI-GRADES-001`) | `UNKNOWN` | NO | Sensitive own-grade API scope `UNKNOWN` | NO | Not implemented |
| Calendar — read only | Current-user calendar UI verified (`UI-CALENDAR-001`) | `UNKNOWN` | NO | Event visibility by API `UNKNOWN` | NO | Not implemented |
| Notifications — own only | Navigation control verified (`UI-NOTIFY-001`) | `UNKNOWN` | NO | Notification visibility/API availability `UNKNOWN` | NO | Not implemented |

## Authentication/service classification

```text
LOGIN_OPTION_OBSERVED = local form + Google OAuth2 route
MOBILE_AUTH_STRATEGY_VERIFIED = NO
WEB_SERVICES_ENABLED = NO (DLU response: enablewsdescription)
REST_FUNCTION_ACCESS = UNKNOWN / BLOCKED
SERVICE_SHORTNAME = UNKNOWN
VERIFIED_API_FUNCTION_COUNT = 0
```

`VERIFIED_NETWORK` for a standard entrypoint or error envelope is not `VERIFIED_API` for a Moodle function. No username/password, service shortname, token or function name was guessed or submitted.

## Row exit criteria

A function row can become `VERIFIED_API` only after all conditions are met:

1. DLU enables and approves the relevant authentication/service path.
2. Exact function and service membership are present in DLU-specific configuration/documentation.
3. An approved test identity invokes the function read-only in the intended context.
4. Success, empty, permission-denied and invalid-session behavior are recorded without secrets/PII.
5. A sanitized typed DTO/mapper, production repository wiring and deterministic tests exist.

No WRITE function will be probed on production. Teacher write features remain blocked until a test/staging environment and explicit authorization exist.
