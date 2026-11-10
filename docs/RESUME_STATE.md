# RESUME_STATE — checkpoint hiện tại (thay nguyên file mỗi lần cập nhật)

Cập nhật: 2026-11-10 (+07) · Workspace D:\DLU-LMS-Group · Branch codex/group-stack-takeover · Writer: Claude Code native (phiên duy nhất)
Nguồn việc: docs/FINAL_DEFENSE_PROMPT.md (F0→F7) + docs/EXECUTION_RULES.md. Không push, không remote, không DDL, không đổi DB target.

## Milestone
- FINAL-F0…F7 DONE; LOGIN DONE; tag bao-ve-2026-11-20 (cục bộ). Tổng kết: cuối docs/HANDOFF.md "TỔNG KẾT CUỐI".
- PUSH GitHub BLOCKED: commit 6f8c0ab có mật khẩu demo dạng chữ thường (backend/docs/authentication_mvp.md) + hash
  (backend/db/auth/002_seed_demo_auth.sql). Chưa thêm remote. Chờ owner chọn a/b/c (HANDOFF mục PUSH).

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

NEXT_ACTION: chờ quyết định PUSH của owner; khi có → quét lại lịch sử, `git remote add github …`, push HEAD:refs/heads/dlu-lms-group-bao-ve
  (không --force, không main) + push tag, xác nhận ls-remote.
NEXT_ACTION_IS_MUTATING: yes (ghi ra ngoài) — chỉ khi owner đã chọn.

## DO_NOT_REPEAT
- Không làm lại N1–N18, O1, E2, P0–P8, chạy emulator hạng A/B/C, migration V2, tạo DB demo.
- Không làm lại F0–F7, LOGIN, quay video, đi DEMO_SCRIPT.
- Không gửi lại nhắc riêng N8 (đã gửi 1 lần cho SV 205), không generate lại kế hoạch chỉ để thử.
- Không chạy lại cleanup Storage-Maintenance-2026-11-09.
