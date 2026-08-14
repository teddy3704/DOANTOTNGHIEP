# DLU LMS Authentication Discovery

**Observed:** Public login 2026-08-13; authenticated/session-service follow-up 2026-08-14 ICT

**Scope:** Public login surface plus the existing user-authenticated browser session. Codex did not enter, read or persist credentials.

## Login surface

| Item | Observation | Confidence |
|---|---|---|
| Login URL | `https://lms.dlu.edu.vn/login/index.php` | `VERIFIED_UI` |
| Page title | `Hệ thống quản lý học tập Trường Đại học Đà Lạt LMS-DLU: Đăng nhập vào hệ thống` | `VERIFIED_UI` |
| Local login form | POST to `/login/index.php` with username, password, login-token and remember-username controls | `VERIFIED_UI` |
| Username label | `Tên đăng nhập/Email` | `VERIFIED_UI` |
| Password recovery | `/login/forgot_password.php` | `VERIFIED_UI` |
| Federated option | Link labelled `Google Login` through Moodle `/auth/oauth2/login.php` | `VERIFIED_UI` |
| Cookies required | Login screen states that browser cookie management must be enabled | `VERIFIED_UI` |

The public instructions state that students use their student ID and lecturers/staff use the username portion of their `@dlu.edu.vn` email. This is a visible usage instruction, not proof of the underlying authentication plugin or password authority.

## Authentication conclusion

- A Moodle login form is visibly available.
- A Google OAuth2 login option is visibly configured through Moodle's OAuth2 route.
- The Google link contains transient session/query state. Documentation records only the sanitized route pattern and never the live value.
- The form does **not** prove that credentials are validated by Moodle native auth; LDAP, another directory or a custom backend may sit behind it.
- The visible OAuth2 option does **not** establish the external redirect/callback contract for the Flutter app. It was not clicked to avoid accidentally authenticating an existing browser account.
- The public page alone did not authorize Moodle username/password token acquisition or identify a service shortname. The later network checks below establish that standard Web Services currently report disabled.

Therefore:

```text
AUTHENTICATION_METHOD_UNCONFIRMED
MOODLE_WEB_SERVICES_NOT_ENABLED
SERVICE_SHORTNAME=UNKNOWN
```

No `MoodleTokenAuthProvider`, `BrowserSsoAuthProvider` or DLU-specific adapter should be selected from the public page alone.

## Authenticated-session outcome

- The existing browser session was directly verified signed in at `/my/` (`VERIFIED_UI`, `UI-AUTH-001`).
- Dashboard, current-user course overview, one representative course, Profile, Calendar and own grades navigation were inspected read-only. See `AUTHENTICATED_FEATURE_MAP.md`.
- The mechanism that created this browser session remains `UNKNOWN`; an authenticated cookie session does not reveal whether the user used the local form, Google OAuth2 or another backend.
- No cookie/session value, password, MFA/OTP, OAuth token or personal identity value was read into documentation or source.
- The browser session is discovery-only and must never be scraped or reused by the production Flutter app.

## Web Services authentication gate

Read-only anonymous checks to `/login/token.php` and its documented `appsitecheck=1` mode returned `200 application/json` with Moodle `errorcode=enablewsdescription` and no token-bearing field (`VERIFIED_NETWORK`, `NET-TOKEN-001/002`). The DLU endpoint therefore currently reports that standard Moodle Web Services are not enabled. No username/password or service shortname was submitted.

The standard REST entrypoint returned `403 text/html` (`NET-REST-001`). This does not identify the denial layer and does not prove a usable external service.

## Evidence still required for application authentication

1. DLU-approved mobile authentication mechanism and policy owner.
2. DLU decision to enable Web Services plus the approved REST/mobile or custom external service on test/staging first.
3. If browser OAuth2/SSO is required: approved redirect URI, app registration, state/PKCE requirements and supported token/session exchange.
4. External-service shortname/function allowlist, token expiry/revocation and file access policy.
5. A DLU-issued least-privilege student test identity/credential through an approved secret channel after the service gate is open.

No production admin password is requested.
