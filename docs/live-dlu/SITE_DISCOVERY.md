# DLU LMS Live Site Discovery

**Discovery window:** 2026-08-13 00:18–00:27 ICT (UTC+07:00)

**Scope:** Public, unauthenticated, read-only

**Target:** `https://lms.dlu.edu.vn/`

## Summary

| Field | Result | Confidence |
|---|---|---|
| Base URL | `https://lms.dlu.edu.vn/` | `VERIFIED_NETWORK` |
| Reachable | Yes | `VERIFIED_NETWORK` |
| Final URL | `https://lms.dlu.edu.vn/` | `VERIFIED_NETWORK` |
| HTTPS | Direct HTTPS response `200 OK`; plain HTTP redirects to HTTPS | `VERIFIED_NETWORK` |
| Platform | Moodle | `VERIFIED_UI` — multiple independent Moodle-specific markers |
| Version | `UNKNOWN`; no generator metadata observed | UNKNOWN |
| Theme | `lambda` | `VERIFIED_UI` — public asset path and page CSS classes |
| Language | Vietnamese (`vi`) | `VERIFIED_UI` |
| Authentication hints | Username/password form and a `Google Login` option | `VERIFIED_UI`; backend/policy `UNKNOWN` |
| Public features | Course search, course-category links, site news block, online-members block, language selector, DLU unit/faculty links | `VERIFIED_UI` |

## Network and HTTPS evidence

- Local DNS resolution returned IPv4 `14.238.96.169`. No AAAA or CNAME answer was observed in the same query; this is not a claim that those records can never exist.
- `http://lms.dlu.edu.vn/` returned `302 Found` to `https://lms.dlu.edu.vn/`.
- `https://lms.dlu.edu.vn/` returned `200 OK` without another redirect. Observed protocol was HTTP/1.1 and server header was `LiteSpeed`.
- Observed content headers included `Content-Type: text/html; charset=utf-8` and `Content-Language: vi`.
- The public response set the cookie name `MoodleSession`. Its value was neither printed nor persisted.
- The observed response included `X-Frame-Options: sameorigin` and no HSTS, CSP, `X-Content-Type-Options`, Referrer-Policy or Permissions-Policy header. This is a response-specific observation, not a vulnerability assessment or whole-site audit.

### TLS observation

- Negotiated connection: TLS 1.2 with `TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384`. This does not establish that TLS 1.3 is unsupported.
- Leaf subject: wildcard certificate for `*.dlu.edu.vn`, issued to Trường Đại học Đà Lạt.
- Issuer: Sectigo RSA Organization Validation Secure Server CA.
- SAN: `*.dlu.edu.vn`, `dlu.edu.vn`.
- Observed validity: 2026-02-24 07:00 ICT through 2027-03-24 06:59:59 ICT.
- Certificate chain validation passed for the observed connection with revocation checking disabled in the local probe.

## Moodle and theme evidence

The platform is classified as Moodle with high confidence because the public HTML/runtime exposed several independent markers:

- JavaScript configuration object `M.cfg`;
- `/lib/requirejs.php` and Moodle YUI assets;
- `/theme/styles.php/lambda/...` and `theme_lambda` assets;
- `/login/index.php`, `/course/index.php` and `/course/search.php` routes;
- cookie name `MoodleSession`;
- footer link stating the site is developed on Moodle open source.

The exact Moodle version remains `UNKNOWN`. Asset timestamps, bundled library versions and visual appearance are not treated as version proof.

## Public interface observations

- Page title: `Hệ thống quản lý học tập Trường Đại học Đà Lạt LMS-DLU`.
- Header exposes the LMS-DLU brand, a login entry point, unit/ITC navigation, Vietnamese language selector and course search.
- Main content exposes a site-news block and public course-category tree. Sample observed categories include Khoa Công nghệ Thông tin, Khoa Toán - Tin học, Khoa Kinh tế - Quản trị Kinh doanh and Khoa Ngoại ngữ. This was a bounded sample; no bulk category/course scrape was performed.
- Footer exposes official DLU organizational/faculty links and public contact information.
- The page includes `meta viewport="width=device-width, initial-scale=1.0"`. A reliable mobile breakpoint capture could not be obtained in the current browser session, so responsive behavior is not marked verified.

## Evidence register

| Finding | Evidence | Classification |
|---|---|---|
| Base site is reachable over HTTPS | Direct GET returned `200 OK` on the final URL | `VERIFIED_NETWORK` |
| Plain HTTP upgrades to HTTPS | Single observed `302` redirect | `VERIFIED_NETWORK` |
| Site is Moodle | Moodle routes, runtime/assets, cookie name and footer attribution | `VERIFIED_UI` |
| Theme candidate is Lambda | `/theme/styles.php/lambda/...`, `theme_lambda` assets/classes | `VERIFIED_UI` |
| Exact Moodle version | No authoritative version evidence | UNKNOWN |
| Public course discovery exists | Visible search form and category links | `VERIFIED_UI` |
| Screenshot artifacts | Browser capture repeatedly timed out; no public screenshot was persisted | `UNKNOWN` — tooling did not produce an artifact |

## Unknowns

- Exact Moodle/PHP/database versions and database table prefix.
- Authentication backend behind the username/password form.
- Whether Google OAuth2 is required, optional, or available for all user groups.
- Whether Web Services, REST protocol or Moodle mobile service are enabled.
- External-service shortname, function allowlist, token policy and file-service policy.
- Authenticated modules, current-user fields, actual roles/capabilities and private course structure.

No login, write operation, port/vulnerability scan, fuzzing, bulk crawl or private-data collection was performed.
