# Security Baseline

## App-owned workflow controls — 06/10/2026

Academic queries still use the existing read-only database boundary. The new
writer accepts only reviewed, parameterized `app.*` statements with short
transactions; no submission, quiz, grade or administration mutation is enabled.
Candidate migration applied after successful rehearsal/rollback; verification
confirms original rows, `lms` columns and views unchanged. Backend 82/82 tests
and real local CRUD/scope smoke (181 checks) PASS, including forbidden academic
writes and identity/ownership controls. Render `a0c2cb7` is Live on the innovation
branch with environment/database secret unchanged. Public regression 165 checks
PASS; backend audit reports 0 vulnerabilities. Latest visible deployment-log
scan has 0 secret-like matches. Final candidate/index secret scan PASS: 416
files, zero actual/indexed secret matches, private config or forbidden staged
artifacts; diff check PASS. Actual runtime ownership tests PASS. This log
observation is limited to the visible latest logs, not proof of every historical
log. Historical results below are not final innovation verification.

- Owner identity is derived from the fixed staging alias map, never request
  user IDs. SQL rechecks active course roles, student enrolment, visibility and
  ownership on reads and mutations. Cross-owner and nonexistent records share
  the same inaccessible response. Mixed role headers are rejected.
- Closed schemas reject unknown fields, invalid dates/IDs, invalid status and
  scores; notes are capped at 500 characters, duration at 5–480 minutes and
  write bodies at 8 KiB. Source reasons/snapshots are server-owned. Record
  bounds, one active intervention per teacher/course/student and 30 workflow
  writes/minute/actor constrain public synthetic staging abuse.
- Flutter retains HTTPS-origin and method/path allowlists, sends only the active
  role header and rejects stale responses after identity switches. Providers
  invalidate per session; forms recheck the current owner before writing.
  No fixture fallback follows an API failure.
- Persisted personal plans and teacher notes are application data, not official
  academic records. Reminders stay device-local with generic notification text.
  Reminder failure reports the already-saved plan truthfully rather than losing
  authoritative state or claiming a failed save. Android delivery observed at
  17:22 uses generic title/body without PII; handled cancels that alarm.
  SV002 has no SV001 plan and GV001 no Student navigation; SV001 relogin restores
  its exact state. Teacher notes/follow-up/history persist across APK update/
  restart without official academic mutation. Only our test plan was deleted
  through confirmed UI; no database reset or LMS deletion occurred.
  Final read-only integrity check after runtime again confirms original rows,
  `lms` columns and derived views unchanged; the academic assignment remains
  unfinished, not implicitly submitted by marking the plan handled.
- Existing private candidate configuration is consumed silently. The baseline
  backup is off-repository; credentials, raw database errors, APKs and backups
  are excluded from Git/export/screenshots. Secret/index scan remains a final
  required gate.

The public demonstration selector is **not production authentication**. This
synthetic environment must not hold real PII. Production requires approved DLU
authentication/capabilities and least-privilege database credentials; client role
UI and staging aliases are not substitutes. No new dependency or credential
rotation is required by this extension.

## GROUP_39_20 runtime controls

Private candidate configuration is now populated and consumed silently by CLI.
Restore guard checks exact candidate endpoint/database and an empty schema set;
transaction applies constraints after data without disabling them permanently.
Catalog/smoke confirms zero non-NULL user password/secret and enrol passwords.
Source originals and current runtime database were not modified.

API selection requires explicit `DATABASE_MODEL=group_39_20`; the default retains
22/10. All runtime queries use existing read-only transactions and verified TLS.
Candidate aliases are allowlisted, not arbitrary request user IDs. Student access
checks active user/enrolment, course context role and visible modules/sections;
Teacher access checks active user and assigned course-context roles. Mixed role
headers are rejected. Teacher A/B forbidden courses return indistinguishable 404.
Public profile emails are reserved `example.test` aliases; raw group-seed emails,
password/secret fields and private file paths are not API projections. Staging
aliases are **not authentication suitable for real DLU data**. No academic writes.

## Candidate continuation

User confirmed remediation of the prior exposed candidate credential. No
credential dialog was reopened. New ignored candidate seed clears password/secret
fields to NULL; original group files stay read-only. A separate ignored
`.env.candidate` is required for CLI use; never reuse the current runtime `.env`.
No secret has been entered/read for this new connection yet. Temporary loopback
SQL transport was blocked by the browser and stopped; no bypass was attempted.

## 2026-09-19 candidate connection UI incident

After creation of the isolated Free candidate branch, Neon automatically opened
a connection dialog whose accessibility output contained an unmasked credential.
The dialog was immediately hidden and closed. The value was not used for a
connection, copied into project files or captured in a screenshot. Database work
is paused for human rotation on the affected candidate branch. Do not reproduce
the tool output, reuse that credential, rotate the current runtime automatically,
or change Render configuration. No claim is made that existing tool output can
be erased. Future connection forms require human handoff before inspection.

## 2026-09-19 council alignment

Current Neon `lms.users` has no password column. Group SQL was not imported or
used for authentication. Its local backup copy replaces all 18 user password
and secret fields with a non-authenticating marker; originals remain unchanged.
Raw group inputs/backup exports are ignored by Git. Demo SQL is READ ONLY;
connection values and raw database errors are never printed. No credentials
were copied to Postman, Flutter, screenshots or documents.

**Status:** Phase 3B hardening + synthetic-data and product-presentation disclosure controls implemented; live authentication remains blocked by DLU service/auth configuration.

**Scope:** Flutter client, Moodle REST boundary, local data, build/release process.

## Synthetic dataset controls — 2026-08-15

- Canonical fixture được phân loại `SYNTHETIC_DATA`, sinh offline với seed `202608`, chỉ được dùng trong DEV/test.
- Identity dùng `SVTEST*`/`GVTEST*` và `example.test`; generator không tạo password, Moodle token, cookie, signing secret, database credential hoặc live DLU payload.
- `main.dart` giữ unconfigured repositories và không fallback asset. Chỉ `main_development.dart` tạo `SyntheticFixtureDataSource`.
- Validator kiểm tra PK uniqueness, declared/local fixture links, mandatory values, state coverage và privacy markers trước khi asset được chấp nhận.
- `schema.sql`/`seed.sql` là local `PROJECT_SUBSET_SCHEMA`, không phải deployment migration và không tạo đường Flutter → MySQL.
- File rows chỉ có synthetic metadata. `contenthash` không được coi là download URL; repository không chứa file bytes hoặc `moodledata`.

## Product UI disclosure controls — 2026-08-16

- Production Login fail closed bằng một thông báo thân thiện và không render username/password field, raw blocker code, endpoint hoặc hướng dẫn kỹ thuật cho người dùng cuối.
- Development entrypoint vẫn inject canonical `SYNTHETIC_DATA` ở composition root nhưng presentation không hiển thị nhãn `DEV`/`FIXTURE`/`MOCK`, schema/repository metadata hoặc infrastructure state.
- `userMessageFor` map failure theo loại sang thông báo hành động bằng tiếng Việt; raw transport exception, diagnostic message và backend detail không được dùng làm UI copy.
- Profile đã bỏ internal ID, endpoint, token/secure-storage status và các chi tiết không cần cho tác vụ sinh viên; chỉ giữ identity tối thiểu, theme local và logout.
- Dashboard đã bỏ notification affordance không có nguồn dữ liệu thật. Grades đã bỏ average/chart suy diễn để tránh trình bày thông tin học vụ chưa được Moodle xác nhận.
- Calendar map event type sang category thân thiện và không render raw type/ID. Resource sheet chỉ hiển thị metadata synthetic an toàn, không biến `contenthash` thành URL.
- Bộ screenshot product-polish ở `docs/screenshots/production-polish/` chỉ dùng identity/course content hư cấu và domain `example.test`; không chứa token, cookie, password, production DLU payload hoặc dữ liệu tài khoản đang đăng nhập trên browser.
- Regression tests kiểm tra production credential surface và quét presentation text để ngăn backend terminology/raw blocker code quay lại UI.

## Student Support staging consumer controls — 2026-09-18

- The verified Render service is a development/staging API only. Flutter reaches it
  only through explicit `main_staging.dart`; `main.dart` neither selects it nor
  falls back to it.
- `StudentSupportStagingConfig` accepts a credential-free HTTPS origin and a
  synthetic development identity format only. The identity header is not DLU
  authentication, a password, token or authorization grant.
- The staging selector accepts only its fixed sample-student allowlist and keeps
  at most the selected non-secret scope code in platform-backed storage. It does
  not persist a password, token, profile payload or DLU session. A staging 401
  clears that scope before the router returns to the selector.
- `StudentSupportApiClient` has a static read-only GET allowlist for the 11
  documented routes, rejects an arbitrary origin/path/query, and does not send an
  `Authorization` header, Moodle credential or database credential.
- Staging UI identifies itself as a read-only preview without exposing source
  infrastructure, passwords, tokens, raw errors or database details. Its Flutter
  format/analyze/test (93 tests) and emulator read-only walkthrough gates have
  passed; this does not enable DLU authentication, upload, submission, grading or
  another write workflow.
- The official-LMS handoff validates the exact canonical HTTPS origin and opens it
  through the platform external-application mechanism only. It rejects arbitrary
  URLs and never derives an activity link from a sample identifier, response ID or
  unverified database mapping.

## App-owned local reminder controls — 2026-09-18

- A reminder is a learner-controlled, device-local setting, not a Moodle event
  or an API mutation. The Flutter flow makes no Moodle, Render, Neon or Supabase
  write request when a learner creates, updates, enables, disables or deletes it.
- Secure local storage contains only opaque owner/course/assignment references,
  due/reminder timestamps, enabled state and local audit timestamps. It excludes
  course/assignment titles, descriptions, grades, feedback, submissions, file
  paths, passwords, tokens and full API payloads.
- `SecureLocalReminderRepository` applies owner scope on every operation;
  immutable academic references prevent a stored reminder from being reassigned
  across a learner, course or assignment. Invalid duplicate, past or post-deadline
  schedules are rejected. A persistence failure triggers scheduler restoration
  where possible rather than silently retaining an inconsistent state.
- Android notification permission is requested only when a learner enables a
  reminder. The scheduled text is generic and contains no academic content;
  delivery is not claimed until manual device/emulator verification. The feature
  must not be described as an official LMS notification.
- Automated coverage includes local persistence/owner isolation and scheduler
  permission, generic-copy, cancellation and safe-failure paths. `flutter
  analyze` is clean and the current full Flutter suite passes 137 tests; final
  APK/emulator verification remains pending.

## 1. Security invariants

- Production traffic dùng HTTPS.
- Token/password/private key/signing key/database credential không nằm trong source, Git history, logs, screenshots hoặc analytics.
- Password Moodle không được lưu lâu dài.
- Token/session secret dùng OS-backed secure storage và được xóa khi logout/user switch.
- Flutter không kết nối trực tiếp Moodle database.
- Authorization cuối cùng thuộc Moodle/backend; UI visibility không phải security boundary.
- Không bypass SSO, CAPTCHA, MFA/2FA hoặc certificate validation.
- Không WRITE production Moodle/database khi chưa có explicit approval.
- Không dùng dữ liệu cá nhân thật làm fixture.

## 2. Data classification

| Class | Ví dụ | Client handling |
|---|---|---|
| Public | Public course title nếu DLU công khai | Cache có giới hạn theo UX |
| Internal | Non-public course metadata | Authenticated access; clear on logout as required |
| Personal | Profile, enrolment, messages | Data minimization; no logs; controlled cache |
| Sensitive Academic | Grades, submissions, feedback | Strongest minimization; no analytics payload; retention documented |
| Secret | Token, password, signing/database credentials | Secure storage/runtime only; never log/commit |

## 3. Threat model

| Threat | Risk | Required control | Verification |
|---|---|---|---|
| Token leakage through logs/URL/errors | Account compromise | Central redaction; no request body/tokenized URL logs | Unit tests + log review |
| Credential persistence | Password theft | Never persist password; clear input/memory references when feasible | Code review + tests |
| Insecure local token storage | Session theft | `flutter_secure_storage`; platform configuration review | Device/integration test |
| Client-side role spoofing | Unauthorized UI/action | Server capability checks; no trusted role boolean from client | Permission-negative tests |
| TLS interception/misconfiguration | Data exposure | HTTPS validation; no trust-all certificate handler | Static/code review + network test |
| Overbroad Web Service token | Excess data/action scope | DLU service allowlist, expiry/revocation, least privilege | Admin config evidence |
| PII in fixtures/screenshots | Privacy breach | Synthetic fixtures; screenshot checklist/redaction | Repository scan + review |
| Cached data after logout/user switch | Cross-user exposure | Namespaced cache; atomic clear on logout/switch | Integration test |
| Malicious filename/path | File overwrite/path traversal | Safe app-owned directory and sanitized display filename | Unit/integration tests |
| Accidental production WRITE | Academic data integrity loss | Environment banner/guard; WRITE disabled until approved | Config tests + manual gate |
| Development identity mistaken for DLU authentication | Unauthorized or misleading production use | Explicit staging-only entrypoint, allowlisted non-secret scope, 401 invalidation, read-only route allowlist, no production fallback | Source/isolation tests + staging smoke |
| Unverified activity/deep link | Open arbitrary destination or imply unsupported Moodle action | Exact canonical-origin handoff only; no response-ID URL synthesis or mobile submit control | Launcher unit tests + UI review |
| Local reminder metadata or notification disclosure | Device-local exposure of academic context | Secure minimal metadata, owner scope, generic notification copy and runtime permission | Repository/scheduler tests + device review pending |
| Supply-chain/dependency issue | App compromise | Minimal dependencies, lockfile review, advisories/license review | CI/release checklist |
| Secret in Git/database dump | Long-lived exposure | `.gitignore`, pre-commit/CI scan, history review before publish | Secret scan |

## 4. Secret lifecycle

1. Secret được DLU/người dùng cung cấp qua approved private channel, không qua committed file.
2. Development token có scope nhỏ, expiry ngắn và test data.
3. App nhận runtime token qua approved auth flow.
4. Token được lưu secure storage, không copy vào general cache/state dump.
5. Logout/session invalidation xóa token và user-scoped cache.
6. Suspected exposure được report; revocation/rotation do authorized owner thực hiện.

Không tự rotate credentials.

## 5. Safe network logging

Production logging chỉ giữ metadata tối thiểu như operation category, local correlation ID, duration, status class và sanitized Moodle error code. Luôn redact:

- authorization/token/password fields;
- query/body values có token;
- tokenized file URLs;
- username, email, student ID và profile fields;
- grades, feedback, submission content và message content.

Không log raw request/response body trên production.

`MoodleApiClient` hiện không giữ raw `DioException`, request options, headers, request/response body hoặc cross-origin URL trong `AppFailure`. `NetworkFailureDiagnostic` chỉ giữ scalar method, same-origin path đã bỏ query, HTTP status và Dio error type; cross-origin path bị ẩn hoàn toàn. Request origin được kiểm tra trước authorizer và kiểm tra lại sau authorizer trước khi gửi, nên injected client/authorizer không thể chuyển secret sang origin khác. Synthetic sentinel tests xác minh token/query/header/body/transport error không xuất hiện trong diagnostics.

## 6. Authentication and session controls

- Validate base URL and site identity after authentication.
- Treat HTTP success with Moodle exception payload as failure.
- On invalid/expired token: clear session safely, preserve no private screen data, require re-authentication.
- Rate-limit repeated interactive login attempts in UX; do not defeat server controls.
- SSO uses system browser/deep-link flow only according to DLU contract; validate redirect/state parameters where protocol requires.
- Do not embed a WebView to capture password or scrape authenticated pages.
- Production Login không hiển thị trường username/password trong khi `AUTHENTICATION_METHOD_UNCONFIRMED`; current development/staging runtime entrypoints use a non-secret sample-scope selector rather than an interactive password form. Isolated test fixtures are not a runtime authentication path.
- Browser session dùng cho discovery không được đọc cookie/session store hoặc chuyển sang Flutter.

## 7. Authorization controls

- Bind every sensitive operation to correct user/course/module context.
- UI capability snapshot only changes affordances; each request may still receive `PermissionFailure`.
- Student negative tests include other-user profile, grades, submissions and hidden course content.
- Teacher negative tests include courses/modules where the teacher has no grading/management capability.
- WRITE operations are disabled in production configuration until specifically approved and verified.

## 8. Android/release controls

- No debug logging/backup exposure of secrets in release configuration.
- Review Android backup/data extraction rules before release.
- Release signing key ownership, storage and rotation policy belong to an authorized DLU/project owner; key is never committed.
- Use unique production application ID after ownership approval.
- Review exported Android components, deep links and intent validation.
- Request notification permission only as a direct learner action; confirm local
  reminder scheduling/cancellation and generic notification copy on a real
  Android runtime before release.
- Minification/obfuscation is defense-in-depth, not secret protection.

## 9. Repository controls

Current `.gitignore` blocks common env, credential, key and database dump patterns. Before first public/pushed commit:

- inspect `git status` and staged diff;
- run an approved secret scan;
- confirm no DLU PII or copyrighted/unauthorized logo asset;
- check generated Android signing/config files;
- review dependency lockfile and licenses.

## 10. Security release gate

- [ ] Authentication method and token lifecycle documented from DLU evidence.
- [ ] No plaintext token/password persistence.
- [ ] Redaction tests PASS.
- [ ] Permission-negative tests PASS for student and teacher contexts.
- [ ] Logout/user-switch cache clearing PASS.
- [ ] TLS verification is not disabled.
- [ ] Production WRITE policy reviewed and explicitly approved where applicable.
- [ ] Secret/PII scan PASS.
- [ ] Android exported components/backup/deep-link configuration reviewed.
- [ ] Known limitations and incident contact/owner documented.

## 11. Implemented Phase 2 controls

- `AppConfig` enforces HTTPS and refuses DEV fixtures in production.
- Production repositories and request authorizer fail closed until DLU contract exists.
- `SecureTokenStorage` uses `flutter_secure_storage`; no password persistence exists.
- Android disables cleartext traffic and application backup.
- Release build has no debug signing fallback or fabricated release secret.
- DEV fixtures are synthetic, isolated behind `main_development.dart` and tested not to appear through production repositories.
- No request/response logging is enabled in `MoodleApiClient`.
- `AppConfig` chỉ nhận credential-free HTTPS origin và loại userinfo/path/query/fragment trước khi tạo client.
- Course/course-detail/profile Riverpod providers dùng `autoDispose`; test xác minh state được giải phóng và tải lại thay vì tái sử dụng cache phiên trước.
- Authenticated DLU discovery chỉ lưu URL pattern/evidence đã khử định danh; không lưu user/course/grade/message values.
- Web Services probe không gửi credential/cookie/token và nhận `enablewsdescription`; không thực hiện token/API brute force hoặc fallback sang HTML scraping.

## 12. Supabase foundation controls

- Chỉ `public.mobile_preferences` là app-owned; không có bảng clone Moodle hoặc credential/session column.
- Migration revoke mặc định rồi chỉ grant `authenticated` quyền `SELECT`, `INSERT(owner_id, theme_mode)` và `UPDATE(theme_mode)`; không grant `anon`, `DELETE` hoặc app-table privilege cho `service_role` trong baseline.
- Flutter không dùng table upsert có thể đòi UPDATE `owner_id`; write đi qua RPC hẹp `SECURITY INVOKER`, server derive `auth.uid()` và `ON CONFLICT` chỉ SET `theme_mode`. Chỉ `authenticated` có EXECUTE.
- RLS được enable + force với ba policy riêng; mọi policy ràng buộc `(select auth.uid()) = owner_id` và từ chối JWT `is_anonymous=true`.
- `owner_id` là UUID primary key và client-immutable; timestamps do database quản lý. Không thêm FK `auth.users` trước khi lifecycle identity DLU được duyệt.
- Flutter chỉ chấp nhận HTTPS project origin cùng `sb_publishable_*` hoặc legacy JWT role `anon`; mọi opaque/user/secret/service-role key class khác bị từ chối trước khi tạo client.
- Access token đi qua injected one-login identity session; thiếu/mismatch/anonymous identity fail closed và không fallback sang anonymous auth hay fixture.
- Supabase/PostgREST raw message không được giữ trong `AppFailure`; auth, RLS, timeout, unavailable, rate-limit và malformed response được map sang stable sanitized code.
- Edge Function hiện contract-only: không generic proxy, không arbitrary upstream/function/method và chưa có server secret/deployment.
- Remote migration/RLS verification chưa được tuyên bố PASS; cần project non-production được chọn và identity mapping DLU → stable UUID `sub` được xác minh.
# Current Teacher API/mobile boundary

Render candidate secret was entered privately by the user. Mobile contains no
database credential and performs only allowlisted HTTPS GET requests. Student and
Teacher headers are mutually exclusive; inherited role headers are removed.
Responses arriving after an identity switch are rejected; a late 401 cannot clear
a newly selected identity. Typed monitoring validates course ID, duplicates,
progress/count bounds. No fixture fallback, grading write or DLU auth claim.
