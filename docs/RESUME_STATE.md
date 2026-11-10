# RESUME_STATE — checkpoint hiện tại (thay nguyên file mỗi lần cập nhật)

Cập nhật: 2026-11-10 (+07) · Workspace D:\DLU-LMS-Group · Branch codex/group-stack-takeover · Writer: Claude Code native (phiên duy nhất)
Nguồn việc: docs/FINAL_DEFENSE_PROMPT.md (F0→F7) + docs/EXECUTION_RULES.md. Không push, không remote, không DDL, không đổi DB target.

## Milestone
- FINAL-F0…F7 DONE; LOGIN DONE; tag bao-ve-2026-11-20 (cục bộ). Tổng kết: cuối docs/HANDOFF.md "TỔNG KẾT CUỐI".
- PUSH GitHub DONE (cách b) 2026-11-10 23:22: nhánh dlu-lms-group-bao-ve + tag bao-ve-2026-11-20 trên GitHub = snapshot
  4d00d9820fad6702307fdebc4b15baf36c50b8a4, cùng cây với commit cục bộ 41f888b. Tag cục bộ bao-ve-2026-11-20 → 41f888b (lịch sử đầy đủ,
  KHÔNG push). Cập nhật GitHub sau này: commit-tree -p 4d00d982…, chỉ khi owner yêu cầu.

## Trạng thái tách riêng
- CODE: N1–N18, O1, E2, P0–P8, LOGIN. Mã nguồn bản cuối 08e41e6.
- TESTS (08e41e6): Backend 284/0/0/1 skip; Flutter 329, analyze sạch.
- APK final E285526E2BDC1E5AB2CC0E6382C1DEBE5090B547666E8B7D0793A7CD4F048917; JAR 3169A50465347CABE25686B650B2A569B856BC99B0F3C352FDAB10AAF8C9F046.
- RUNTIME: emulator DB demo + Portal UP — DEMO_SCRIPT đi hết, LOGIN login-01..06, 5 video.
- OWNER_VALIDATION: Start-Demo sau khi đóng Claude, Set-DemoPasswords, Rotate-AppRolePassword — NOT_RUN (cần owner).

## Database
- Target: lms_mobile_group_demo. Ghi app schema SV 205 (1 thẻ ghi nhớ + 1 lần ôn). .local/backend.json có khối AUTH (hash tạm).

## Đang chạy
- Không (Stop-Demo đã chạy ở F7).

POLISH (docs/POLISH_PROMPT.md, owner 23:30) ĐANG LÀM. WIP chưa commit: POLISH-1 PortalPrewarmer + /health prewarm + Start-LocalBackend
  -DemoCache (cache-ttl 6h, prewarm) + PortalPrewarmerTest 6; POLISH-2 AccountMenu (Giao diện + Đăng xuất) + account_menu_test 4;
  POLISH-4 Start-Demo kiểm tra pin/khởi động lại/internet + bảng SẴN SÀNG. Đo "trước" (backend không DemoCache, Portal nhanh lúc 23:33):
  overview lạnh 3569 ms (17 lời gọi Portal nối tiếp), chi tiết SV đầu 954 ms; 21:52 Portal chậm: > 20 s (timeout).
  KHÔNG chạy Set-DemoPasswords; emulator dùng nút "Chế độ demo".
POLISH-1..7 DONE (commit 229ed71 code; docs đến 0fed544). Đang làm POLISH-8.
NEXT_ACTION: Measure-Api (backend đang chạy) → Stop-Demo → Test-Backend -Package (polish8-backend.log) → Test-Flutter -BuildApk
  (polish8-flutter.log) → đổi tên APK/JAR final cũ thành -r1, copy mới + SHA256SUMS + RELEASE_NOTES → commit → tag bao-ve-2026-11-20-r2
  → snapshot r2 (commit-tree -p 4d00d9820fad6702307fdebc4b15baf36c50b8a4) → quét → push nhánh + tag r2 → ls-remote → tổng kết.
NEXT_ACTION_IS_MUTATING: push — kiểm `git ls-remote github` trước (tag r2 chưa có, nhánh = 4d00d98).

## DO_NOT_REPEAT
- Không làm lại N1–N18, O1, E2, P0–P8, chạy emulator hạng A/B/C, migration V2, tạo DB demo.
- Không làm lại F0–F7, LOGIN, quay video, đi DEMO_SCRIPT, push GitHub. CẤM push HEAD/tag cục bộ/--tags/--all (lịch sử có 6f8c0ab).
- Không gửi lại nhắc riêng N8 (đã gửi 1 lần cho SV 205), không generate lại kế hoạch chỉ để thử.
- Không chạy lại cleanup Storage-Maintenance-2026-11-09.
