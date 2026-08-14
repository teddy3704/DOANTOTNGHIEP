# DLU LMS Administrator Requirements for Mobile Integration

**Purpose:** Minimum evidence and access needed to implement Phase 3 safely.

**Principle:** Least privilege, test/staging first, no production admin password.

## Required information

| Requirement | Why it is needed | Minimum acceptable evidence/permission |
|---|---|---|
| Exact Moodle version | Select compatible official contracts and avoid version guesses | Version page/export or administrator confirmation |
| Mobile authentication policy | Choose token flow vs approved browser SSO without bypassing DLU policy | Written confirmation from LMS/identity owner |
| Google OAuth2/other IdP policy | Public page exposes Google Login, but app flow and eligible users are unknown | Provider/protocol description and approved mobile redirect requirements |
| Web Services enablement decision | DLU currently returns `enablewsdescription`; integration cannot proceed while globally disabled | Approve and enable Web Services in test/staging first, or formally select another supported integration |
| REST/mobile or external service | REST entrypoint currently returns `403`; no service is verified | Approved protocol, enabled service name/shortname and status through an admin-approved record |
| Function allowlist | Implement only functions DLU actually exposes | Sanitized service function list or API-documentation export |
| Token/session policy | Handle expiry, revocation, logout and storage correctly | Lifetime, revocation, IP/device restrictions and secure delivery policy |
| File-service policy | Prevent unsafe tokenized URLs and unsupported transfers | Download/upload flags, allowed file scope and size/type policy |
| Staging/test LMS | Verify contracts without risking production data | Preferred staging URL or explicitly approved read-only production scope |
| Student test account | Verify current user, own courses and own course content | DLU-issued non-privileged representative account |
| Teacher test account | Verify capability-driven read behavior later | DLU-issued least-privilege test account; no write tests in Phase 3 |
| Function/capability documentation | Avoid role guessing and enforce context permissions | Relevant capabilities/contexts for each enabled function |
| Custom plugin policy | Needed only if a verified standard-API gap exists | Review/deployment owner, allowed versions and test environment |

## Optional database evidence

Database access is not required for standard Moodle Web Services. If DLU later authorizes schema analysis, provide only a sanitized schema/data dictionary, anonymized representative dump, or read-only metadata access with the engine/version and actual prefix. Flutter will never connect directly to the Moodle database.

## Secret delivery rules

- Do not send production admin passwords.
- Test credentials or tokens must use an approved private channel, never Git, chat transcript, documentation, command history or screenshots.
- Prefer short-lived/revocable test credentials scoped to the minimum service and functions.
- Live contract tests must be explicit opt-in and must not run automatically in CI against production.

## Minimum Phase 3D enablement package

1. Confirmed authentication mechanism for this mobile app.
2. DLU approval to enable Web Services and the selected REST/mobile or external service, preferably on test/staging.
3. Verified service shortname and least-privilege read-only function allowlist.
4. One DLU-issued student test account/token delivered securely after enablement.
5. Permission to perform only site-info, current-user, own-course and one-course-content reads.

Until that package exists, Flutter production remains fail-closed and never falls back to DEV fixtures.

## Current exact blocker

```text
ACTION_REQUIRED: DLU_ENABLE_MOODLE_WEB_SERVICES

REASON:
The read-only Moodle mobile site check returns errorcode=enablewsdescription.

MINIMUM REQUIRED FROM DLU:
Approve mobile integration, enable Web Services plus the selected protocol/service in test/staging, and provide the sanitized service shortname/function allowlist.

SECURITY NOTE:
No production admin password, database password, broad token or write permission is requested.
```
