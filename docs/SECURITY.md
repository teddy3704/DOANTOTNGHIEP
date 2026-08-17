# Security Baseline

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
- Production Login không hiển thị trường username/password trong khi `AUTHENTICATION_METHOD_UNCONFIRMED`; credential form chỉ tồn tại ở DEV fixture.
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
