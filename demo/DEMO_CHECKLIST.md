# Checklist trình diễn LMS Support — GROUP_39_20

## Current perfection readiness — 07/10/2026

**PARTIAL** only while visible pgAdmin candidate preparation and final Git receipt
remain. Code/API/runtime/artifact gates PASS. Preserved innovation `2e04089` is a fallback, not
the new hardening artifact. Do not reset/import data or replay applied migrations.

- [x] Candidate 002/003 rehearsal/apply and table row/type digests PASS; catalog
  3 schemas / 42 tables (35+7) / 20 views / 588 columns / 42 PK / 45 FK / 29 CHECK.
- [x] 94 missing assignment states and 3 completed next-item false candidates fixed;
  council SQL `database/council_pgadmin_demo.sql` gives 12 read-only resultsets.
- [x] Flutter targeted 107 PASS; original-owner form, null deadline, timeout and
  support UI 320/390px at scale 1.3/1.5 covered. Backend targeted subsets PASS.
- [x] Preflight API diagnostics PASS; dirty worktree is intentionally NOT_READY.
- [x] Final Flutter format156/0 changes, analyze0 issues,245 tests PASS +1 opt-in
  skipped/separately PASS; delayed-card runtime regression repaired/verified.
- [x] Backend96 tests/typecheck/build/format/audit0; local/staging181 checks each.
- [x] Precommit480-file/index secret scan0 actual matches/private/forbidden files;
  diff check PASS. Final clean Git/preflight receipt returned at handoff.
- [x] Existing Render c5231e2 Live from hardening; no database secret change.
- [ ] Human connects existing approved candidate in pgAdmin; run the bounded
  SELECT-only demo, do not display credential or create a local database.
- [x] Existing `DLU_LMS_Pixel`: final APK install and actual Student/Teacher,
  role/context, app-owned workflow/reminder privacy and LMS handoff smoke.
- [x] Actual APK metadata/hash for
  `D:\DLU-LMS\Artifacts\DLU_LMS_Support_Perfection_Final_Debug.apk`; no baseline hash reuse.
- [x] Actual screens reviewed;01–12 QA before correction,13 onward final artifact;
  current process log scan0 matched runtime/secret patterns. Continue to
  keep connection/environment screens out of evidence.
- [ ] Run `powershell -File scripts/council_preflight.ps1` after freeze. Diagnostics
  with dirty override do not certify release readiness. Final APK must match
  reviewed SHA256/package in `evidence/perfection/apk.json` (actual accepted build).

Current gate matrix: `docs/PERFECTION_FINAL_QA.md`. Explain rules as non-AI decision
support and staging aliases as sample selectors. Production DLU auth/Web Services
are TO_VERIFY_DLU; submission/quiz/grading remain LMS ONLY, and production needs
a dedicated least-privilege DB role.

## Innovation readiness — 06/10/2026

Product/runtime gate PASS: candidate apply/verify, backend 82/82 tests, local
real API 181 checks, public regression 165 checks và Flutter format/analyze/224
tests PASS (1 opt-in live test skipped, separately executed PASS). Render
`a0c2cb7` Live; final APK rebuilt/installed/relaunched. Student plan/reminder
delivery and Teacher action/follow-up/closure/persistence verified on emulator.
Handoff scans PASS on 07/10; the final commit/push receipt is returned separately
and the exact hash comes from Git. Baseline 23/09 below is history, not the current artifact.

- [x] Existing Render `a0c2cb7` Live; public contract/security regression 165 checks PASS; environment/database secret unchanged.
- [x] Candidate migration applied/verified; original rows/`lms` columns/20 views unchanged. Actual catalog: 3 schemas, 42 tables (35 lms + 7 app), 42 PK, 45 FK, 588 columns.
- [x] Local real API CRUD/persistence/scope smoke: 181 checks PASS, `evidence/innovation/local-smoke.json`.
- [x] Real API CRUD 181 checks and patched public regression 165 checks PASS; persistence, denied academic writes and scope isolation verified.
- [x] Existing `DLU_LMS_Pixel` online; installed final innovation APK successfully, no new AVD or Android Studio.
- [x] Student: create → edit 60-minute duration/note → postpone 07/10 17:22 → handled; exact state restored after SV001 relogin/restart. LMS remains unfinished.
- [x] Android study reminder delivered at 17:22; generic title/body, no PII (`12_study_reminder.png`); handled cancels alarm.
- [x] Teacher: attention → scoped student detail → action/09/10 follow-up → persisted restart → follow-up note → resolved/history; no causal-improvement claim.
- [x] SV002 week empty (no SV001 plan); GV001 has no Student navigation; switching back restores SV001's exact handled state.
- [x] Official LMS handoff still works; no official submission, quiz, grading or administrative write.
- [x] Responsive AppTheme.light at 320/390px and text scale 1.3; async/form states tested; stale form validation fixed with regression coverage.
- [x] Backend typecheck/build/format-check and 82/82 tests PASS; audit 0 vulnerabilities. Flutter format/analyze and 224 tests PASS, 1 opt-in skipped; separate live-contract PASS.
- [x] Final APK rebuild 17.4s/install/force-stop/relaunch Success; 221,242,818 bytes; package `vn.edu.dlu.lmsmobile`, minSdk 24, targetSdk 36; SHA256 `D34037F56D4D456D74B119E627A802DCEE4B70283EA7D328792BD70763B6AF06`; `D:\DLU-LMS\Artifacts\DLU_LMS_Support_Innovation_Final_Debug.apk`.
- [x] All 15 actual PNGs in `evidence/mobile/innovation-final/`; `09_intervention_action.png` recaptured with final clean form.
- [x] Final candidate/index secret scan and `git diff --check` PASS; no private config, cache or APK staged.
- Git handoff: focused commit and non-force push only to `innovation-study-planner-intervention`; verify final receipt / `git log -1`, never main/history rewrite.
- [ ] Follow `COUNCIL_DEMO_SCRIPT_INNOVATION.md`; explain synthetic data, app-owned writes and DLU integration limits honestly.
- [ ] Hide private connection/environment tabs; no database credential in output, screenshots, slides or exports.

Only our test plan was deleted through the confirmed UI to allow repeating the
presentation; no LMS record was changed. Do not reset or restore the database.
Keep verified
old evidence and private backup for recovery; when offline, use captured evidence
while the app shows its honest retry state, never a silent fixture fallback.

## Historical baseline checklist — 23/09/2026

Kiểm tra lại trước buổi báo cáo; dữ liệu phát triển là dữ liệu mẫu, không phải hồ sơ DLU.

QA 23/09: Student/Teacher/API/APK/screenshots PASS. Render Free cold start từng
vượt timeout một lần sau khởi động emulator: mở `/health` trước khi lên sân khấu,
sau đó chọn lại hồ sơ mẫu nếu cần. Dữ liệu hiện không có hạn nộp tương lai, nên
không trình bày thông báo Android là đã được kiểm chứng; dùng màn hình nhắc việc
và test tự động làm bằng chứng phạm vi hiện có.

- [ ] Mở được https://lms.dlu.edu.vn/; không trình chiếu credential/cookie.
- [ ] Render /health trả ok; dự phòng thời gian cold start Free instance.
- [ ] Student và Teacher API hoạt động (script staging-group-smoke.ts).
- [ ] AVD DLU_LMS_Pixel / emulator-5554 online; dùng APK cuối trong FLUTTER_TEST_RESULT.md.
- [ ] SV001: Home → Courses → Course Detail → Assignment → Progress → Profile.
- [ ] GV001: Home → Courses → Theo dõi sinh viên → Work → Calendar → Profile.
- [ ] Quyền thông báo đã cấp; kiểm tra tạo/bật/tắt lời nhắc. Không tuyên bố notification fire PASS: dữ liệu cuối không có hạn tương lai phù hợp để quan sát.
- [ ] Mở LMS từ Student/Teacher; không nộp bài, nhập điểm hay thay đổi học phần.
- [ ] pgAdmin chọn database candidate đã lưu, không tạo database local mới.
- [ ] Chạy 01_verify_database_baseline.sql: 3 schema, 39 bảng (35 lms + 4 app),
      20 view, 39 PK, 38 FK, 548 cột.
- [ ] Chạy 02_council_database_demo.sql: role/context, enrolment, module,
      Student/Teacher read model và app-owned data.
- [ ] Có APK, ảnh thật, schema gốc, sanitized seed, SQL demo, OpenAPI và kịch bản offline.
- [ ] Không giới thiệu Neon là database production DLU, hoặc chỉ báo quy tắc là AI.

## Lệnh xác minh không cần secret

```powershell
& D:\DLU-LMS\Android\Sdk\platform-tools\adb.exe devices -l
node --experimental-strip-types integration-api/scripts/staging-group-smoke.ts
# Trong pgAdmin, chạy hai file SQL demo trên candidate; chỉ SELECT/READ ONLY.
```

## Dự phòng

Bộ GROUP_39_20 ở evidence/council-backup/group39-20-final trong worktree.
APK ở D:\DoAnTotNghiep\evidence\mobile và ảnh mới ở evidence/mobile/group39-20-final.
Giữ nguyên backup 22/10 cũ để rollback. Không restore lại candidate đã có dữ liệu.
Khi mất mạng, dùng APK để giải thích điều hướng và bộ ảnh/contract đã lưu;
ứng dụng phải báo lỗi/thử lại, không silently đổi sang fixture.
Đổi hồ sơ bằng thao tác trong Profile; không có mật khẩu demo hoặc reset phá dữ liệu.

## Ngày trước buổi bảo vệ

- [ ] Sạc laptop, mang sạc; kiểm tra điện thoại Android nếu có.
- [ ] Mở thử AVD `DLU_LMS_Pixel`, APK debug staging và ảnh runtime cuối.
- [ ] Lưu APK, 15 ảnh, schema/sanitized seed, hai SQL chỉ đọc, OpenAPI và các file demo trong `D:\DLU-LMS-FINAL-DEMO` và bản ZIP.
- [ ] Chuẩn bị slide, hotspot và bản script offline; không lưu credential trong bộ backup.

## Trước 30 phút

- [ ] Kiểm tra Internet và `https://lms.dlu.edu.vn/`; mở Render `/health` trước 5–10 phút để vượt cold start, không spam request.
- [ ] Khởi động emulator, mở app, thử Student và Teacher identity mẫu, link LMS và quay lại app.
- [ ] Kiểm tra pgAdmin đang chọn đúng database candidate đã lưu; hai SQL demo chỉ SELECT, không đổi Render/database.
- [ ] Chuẩn bị tab kiến trúc, API `/docs`, SQL demo và ảnh. Đóng tab credential/kết nối riêng tư.

## Trước 5 phút

- [ ] Đóng tab riêng tư, ẩn notification và credential, kiểm tra âm lượng, phóng to cửa sổ cần dùng.
- [ ] Đưa app về Student Home. Nếu `/health` timeout lần đầu, chờ rồi thử lại một lần; chuẩn bị ảnh/contract offline.
