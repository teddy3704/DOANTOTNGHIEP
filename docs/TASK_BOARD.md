# Task board — 2026-10-31

One writer per working copy (currently native Claude Code on Windows, accepted 2026-10-31 01:52 +07). One migration owner per database (none yet).
Status: TODO / IN_PROGRESS / DONE / BLOCKED / NOT_RUN. "DONE (static)" means reviewed or
edited without compile/run evidence.

| ID | Task | Owner | File scope | Status | Acceptance gate |
| --- | --- | --- | --- | --- | --- |
| T01 | Takeover: rules, Git, SQL hash, diff vs D:\doan | Claude | none | DONE | Evidence in HANDOFF.md |
| T02 | Fix `InightsRepository` import typo | Claude | backend/.../service/ReflectionService.java | DONE | Compiled in T03 |
| T03 | Backend isolated tests | Native Claude Code on Windows | backend/target (generated) | DONE — exit 0, 71 tests / 0 F / 0 E / 1 skipped (2026-10-31 02:01) | `.\tools\Test-Backend.ps1` exit 0; record surefire totals; SchemaVerificationTest stays @Disabled |
| T04 | Backend package | Same runner, after T03 | backend/target | DONE — exit 0, 71/0/0/1, JAR 2026-11-03 18:55 (SHA256 in HANDOFF) | `.\tools\Test-Backend.ps1 -Package` exit 0; JAR built from current source |
| T05 | Flutter format/analyze/test | Same runner | frontend/ (format may rewrite) | DONE — exit 0: format 55 files, 21 info lints fixed (dart fix + 1 manual), analyze clean, 203 tests pass (2026-11-03) | `.\tools\Test-Flutter.ps1` exit 0; list files changed by format |
| T06 | Debug APK | Same runner, after T05 | frontend/build | DONE — exit 0, app-debug.apk 148 MB built 2026-11-03 22:55 (C free 22.4GB before/after; SHA256 in HANDOFF) | C free ≥15GB; `Test-Flutter.ps1 -BuildApk` exit 0; SDK D:\DLU-LMS\Android\Sdk has build-tools/platforms/ndk |
| T07 | Isolated DB restore | Owner-approved operator | new empty DB only | T07a DONE (PASS 2026-11-04 00:41) — verified EDB 18.6 set on D; owner initdb; Check/Start/Verify PASS: data_directory, pg_wal, logs on D; only 127.0.0.1:55432; SCRAM-only HBA; DBs postgres/template0/1; evidence D:\DLU-LMS\Artifacts\t07a-verify-20261104-004145.txt. T07b DONE (PASS 2026-11-04 01:00) — A0 tổng hợp + QUYEN_DUNG_LOCAL=CO; restore 0 errors, 44 COPY / 1,686 rows. Dump now at database\ (git-ignored, same SHA); D:\doan found empty | database/README.md gates 1–5; no import-over |
| T08 | Catalog verification + pgAdmin query tabs | After T07 | read-only | PARTIAL (2026-11-04) — all 9 structure metrics MATCHES_SNAPSHOT, 0 missing relations; integrity: app.learning_reflections 2 missing owner / 2 missing course — owner 2026-11-07: GIỮ NGUYÊN, ghi nhận là giới hạn của dữ liệu mẫu, không xóa; pgAdmin tabs not done | `verify_group_catalog.sql` reviewed counts; tabs per handoff §6 using real schema |
| T09 | API + emulator runtime: notes/reflections persist, role isolation | After T04/T06/T07 | none | DONE (2026-11-07) — all student/teacher flows PASS on emulator with lms_group_app; 403 fix in SecurityConfig (ERROR dispatch); reminder-to-1-student only via API (UI has no 1-student list in this data); evidence D:\DLU-LMS\Artifacts\t09 | Real backend + restored DB; no mock fallback |
| V2-N1 | Mô phỏng điểm / điểm cần đạt (SV) | V2 hạng A | none | DONE (2026-11-08) — gates PASS, chạy thật trên emulator (n1-01..03) |
| V2-N9 | Tình trạng học tập của tôi (SV) | V2 hạng A | none | DONE (2026-11-08) — điểm SV = điểm GV (46/46 hàng DB), emulator n9-01..03 |
| V2-N2 | Gợi ý ôn lại theo chương (SV) | V2 hạng A | none | DONE (2026-11-08) — emulator n2-01..02 |
| V2-N4 | Dự báo qua môn của lớp (GV) | V2 hạng A | none | DONE (2026-11-08) — emulator n4-01..03; "Nhắc riêng" chờ N8 |
| V2-N3 | Vị trí trong lớp ẩn danh (SV) | V2 hạng A | none | DONE (2026-11-08) — ẩn khi <5 SV; emulator n3-01..02 |
| V2-MIG | Migration app.flashcard_reviews/study_plan_items/study_sessions + grants + DB demo dời ngày | V2 hạng A | DDL schema app (owner) | DONE (2026-11-09) — owner chạy -CreateDemo -DemoTargetDate 2026-11-20; dev+demo exit 0, quyền khớp grants |
| V2-N5 | Ôn tập ngắt quãng SM-2 | sau MIG | app.flashcard_reviews | DONE (2026-11-09) — gates PASS; emulator DB demo 2026-11-10 n5-01..03 |
| V3-P0 | Nền tảng tích hợp Portal (client, cache, health, cấu hình, script owner) | V3 | none (chỉ bộ nhớ) | DONE (2026-11-09) — gate BE 163; chạy thật API (dữ liệu mô phỏng, key dev dùng chung theo phụ lục) |
| V3-P1 | Bảng điểm và GPA của tôi | V3 | none | DONE (2026-11-09) — gate BE 209 / FE 246; chạy thật API (dữ liệu mô phỏng) + emulator, ảnh D:\DLU-LMS\Artifacts\v3\screens |
| V3-P2 | Tiến độ CTĐT + điều kiện tiên quyết | V3 | none | DONE (2026-11-09) — gate BE 209 / FE 246; chạy thật API (dữ liệu mô phỏng) + emulator, ảnh D:\DLU-LMS\Artifacts\v3\screens |
| V3-P3 | Mô phỏng GPA / mục tiêu xếp loại (cầu nối N1) | V3 | none | DONE (2026-11-09) — gate BE 209 / FE 246; chạy thật API (dữ liệu mô phỏng) + emulator, ảnh D:\DLU-LMS\Artifacts\v3\screens |
| V3-P4 | Điểm rèn luyện của tôi | V3 | none | DONE (2026-11-09) — gate BE 209 / FE 246; chạy thật API (dữ liệu mô phỏng) + emulator, ảnh D:\DLU-LMS\Artifacts\v3\screens |
| V3-P5 | Quyết định học vụ của tôi | V3 | none | DONE (2026-11-09) — gate BE 209 / FE 246; chạy thật API (dữ liệu mô phỏng) + emulator, ảnh D:\DLU-LMS\Artifacts\v3\screens |
| V3-P6 | Lớp cố vấn học tập (GV) | V3 | none | DONE (2026-11-09) — gate BE 209 / FE 246; chạy thật API (dữ liệu mô phỏng) + emulator, ảnh D:\DLU-LMS\Artifacts\v3\screens |
| V3-P7 | Nguồn dữ liệu và quyền riêng tư | V3 | none | DONE (2026-11-09) — gate BE 209 / FE 246; chạy thật API (dữ liệu mô phỏng) + emulator, ảnh D:\DLU-LMS\Artifacts\v3\screens |
| V3-P8 | Hoàn thiện tích hợp (trạng thái, cache client, E2) | V3 | none | DONE (2026-11-09) — gate BE 209 / FE 246; chạy thật API (dữ liệu mô phỏng) + emulator, ảnh D:\DLU-LMS\Artifacts\v3\screens |
| V3-DIAG | Sơ đồ docs/diagrams + COMPARISON_FACTS + FEATURES_V3 | V3 | none | DONE (2026-11-09) — 12 file .mmd (01…11, use case tách 08/09); mmdc không có → chưa render SVG (phiên cloud render) |
| V2-N6 | Kế hoạch học tuần | sau MIG | app.study_plan_items | DONE (2026-11-10) — gates PASS; emulator DB demo n6-01..05 (lỗi trùng thẻ ôn khi lập lại → sửa 238dd7e) |
| V2-N7 | Nhắc học trên điện thoại + cài đặt | sau MIG | app.notification_preferences | DONE (2026-11-10) — gates PASS; emulator: thông báo thử + nhắc hằng ngày tự hiện khi đóng app (n7-01..04) |
| V2-N10 | Pomodoro + mục tiêu phút học | sau MIG | app.study_sessions | DONE (2026-11-10) — gates PASS; emulator n10-01..06 (đúng sau 77 s chạy nền; sửa thẻ dashboard a6535d8) |
| V2-N8 | Nhắc riêng 1 SV + xuất CSV | hạng B | app.notifications/teacher_notes | DONE (2026-11-10) — gates PASS (BE 246, FE 277); emulator n8-01..05 (gửi thật 1 nhắc, CSV ra share sheet) |
| V2-N15 | Bản đồ nhiệt tương tác (GV) | hạng B | none | DONE (2026-11-10) — đối chiếu ActivityHeatmapSection: giữ nguyên, chỉ thêm 4 mức màu + endpoint engagement-heatmap; gates PASS (BE 257, FE 281); emulator n15-01 |
| V2-N16 | Phân tích bài kiểm tra (GV) | hạng B | none | DONE (2026-11-10) — gates PASS (BE 255, FE 280); API + emulator n16-01..03 (khóa 3000015 có cờ thật) |
| V2-B-RUN | DB demo + APK r2 + emulator N5/N6/N7/N10, kiểm lại N1–N4, N9, P1–P7 | — | none | DONE (2026-11-10) — xem HANDOFF "Bước b" |
| V2-O1 | Start-Demo/Stop-Demo độc lập phiên Claude | hạng B | none | DONE (2026-11-10) — Claude chạy thật 8/8 + Stop; owner chạy lại sau khi đóng Claude: NOT_RUN; cần C ≥22 GiB |
| V2-E2 | Đo hiệu năng API | hạng B | none | DONE (2026-11-10) — Measure-Api.ps1, 12 endpoint × 200, p95 3,1–28,7 ms, 0 lỗi; gộp số Portal V3 trong FEATURES_V2 §E2 |
| V2-N11 | Xem khi mất mạng | hạng C | none (bộ nhớ máy) | DONE (2026-11-10) — gate FE 286; emulator n11-01 (dữ liệu lưu + banner; sửa khoảng trống dưới banner, FE 300) |
| V2-N12 | Lịch tổng hợp + xuất .ics | hạng C | none | DONE (2026-11-10) — gates PASS (BE 259, FE 289); emulator n12-01..02 (lịch 3 nguồn thật, .ics ra share sheet) |
| V2-N13 | Tìm kiếm nhanh (SV, GV) | hạng C | none | DONE (2026-11-10) — gates PASS (BE 265, FE 290); emulator n13-01 + API (không dấu, injection 0 kết quả, q ngắn 400) |
| V2-N14 | Tuần của bạn | hạng C | none | DONE (2026-11-10) — gates PASS (BE 268, FE 292); emulator n14-01 |
| V2-N17 | Thành tích | hạng C | none | DONE (2026-11-10) — gates PASS (BE 273, FE 294); 'hết Đỏ' thay bằng 'không còn khóa Đỏ' (không có lịch sử N9); emulator n17-01 |
| V2-N18 | Đánh bóng (chế độ tối, cỡ chữ 1.3, onboarding, Semantics, bộ chọn giờ tiếng Việt) | hạng C | none | DONE (2026-11-10) — gate FE 300; emulator n18-01..02 (giới thiệu, chế độ tối; sửa màu cứng màn chọn vai trò) |
| FINAL-F0 | Checkpoint RESUME_STATE + chỉ dẫn CLAUDE.md | final | none | DONE (2026-11-10) |
| FINAL-F1 | Sơ đồ khớp code (02, 08, 09, 10, 06) | final | none | DONE (2026-11-10) — sửa 02, 08, 09, 10; 06 không đổi (luồng cầu nối như cũ); chưa render (phiên cloud) |
| FINAL-F2 | Giảm rủi ro demo (quyền thông báo, chế độ tối, USB, lỗi đã biết, kiểm tra Start-Demo) | final | none | DONE (2026-11-10) — gates BE 274, FE 316; emulator: hộp thoại quyền + từ chối + mở cài đặt + thông báo thử (f2-01..06), lịch tháng (f2-07). PARTIAL runtime: lịch tuần, chế độ tối 5 màn, nhãn 'sau hôm nay' → chụp ở phiên emulator F3; -PhysicalDevice chưa thử máy thật (không có máy) |
| FINAL-F3 | Hồi quy + APK/JAR cuối + RELEASE_NOTES | final | none | DONE (2026-11-10) — gate BE 284 / FE 329 trên 08e41e6, APK+JAR final + SHA256SUMS, Measure-Api p95 ≤ 21 ms, đi hết DEMO_SCRIPT trên emulator, RELEASE_NOTES.md |
| FINAL-F4 | DEMO_SCRIPT + USER_GUIDE | final | none | DONE (2026-11-10) — docs; đi thử kịch bản trên emulator ở F3 |
| FINAL-F5 | Video quay màn hình thật | final | none | DONE (2026-11-10) — 5 đoạn trong D:\DLU-LMS\Artifacts\final\video (1:06–2:28); đoạn mở đầu sv-1 sẽ quay lại sau khi có đăng nhập MSSV |
| FINAL-F6 | Rotate-AppRolePassword.ps1 (owner chạy) | final | owner (mật khẩu postgres) | DONE code (2026-11-10) — parse PS5/PS7 OK; chạy thật: NOT_RUN, chờ owner |
| FINAL-F7 | Tag bao-ve-2026-11-20 + tổng kết | final | none | DONE (2026-11-10) — tag cục bộ, Stop-Demo, tổng kết cuối HANDOFF; push lần 2 BLOCKED cùng lý do PUSH |
| LOGIN | Đăng nhập MSSV/tên tài khoản + mật khẩu (docs/LOGIN_MSSV_PROMPT.md) | sau F5, trước F7 | .local AUTH (hash) | DONE (2026-11-10) — BE 284, FE 329; emulator login-01..06; video sv-1 quay lại; MoodleTokenProvider TẮT (mock) |
| PUSH | Push nhánh dlu-lms-group-bao-ve lên GitHub (cách b: một commit ảnh chụp) | owner chọn (b) 10/11 | remote GitHub | IN_PROGRESS — bước 1 (gỡ mật khẩu/hash khỏi cây, 6d88f2a), bước 2 (DB: không có app.auth_account) xong |
| T10 | Supabase role in stack | Claude | none | DONE (static) | No Supabase reference in source; connector stays unused |
| T11 | Backup-status notes in baseline docs | Claude | docs/, database/README.md | DONE | Dated notes added |
| T12 | Teacher notes need courseId (backend now requires it) | Claude | frontend teacher_notes_screen | DONE (static) | Only caller passes non-null courseId; confirm in T09 |
