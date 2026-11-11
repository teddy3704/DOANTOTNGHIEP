# RESUME_STATE — checkpoint hiện tại (thay nguyên file mỗi lần cập nhật)

Cập nhật: 2026-11-10 (+07) · Workspace D:\DLU-LMS-Group · Branch codex/group-stack-takeover · Writer: Claude Code native (phiên duy nhất)
Nguồn việc: docs/FINAL_DEFENSE_PROMPT.md (F0→F7) + docs/EXECUTION_RULES.md. Không push, không remote, không DDL, không đổi DB target.

## Milestone
- FINAL F0–F7, LOGIN, PUSH (b), POLISH-1…8 DONE. Tổng kết: cuối docs/HANDOFF.md "TỔNG KẾT POLISH".
- GitHub: nhánh dlu-lms-group-bao-ve = tag bao-ve-2026-11-20-r2 = snapshot 12ef5ca312a5e3a557eb2c93116b2c89f231f2ea (cùng cây với commit
  cục bộ 53b685f), con của 4d00d98 (tag bao-ve-2026-11-20). Push 2026-11-11 03:08. Tag cục bộ: bao-ve-2026-11-20 → 41f888b,
  bao-ve-2026-11-20-r2 → 53b685f (lịch sử đầy đủ, KHÔNG push).

## Trạng thái tách riêng
- CODE: N1–N18, O1, E2, P0–P8, LOGIN, POLISH-1/2/4. Mã nguồn bản cuối 229ed71.
- TESTS: Backend 290/0/0/1 skip; Flutter 333, analyze sạch.
- APK final 910CEF7591C547C585770592447E34357231E41E46265A7F0FCF397728477131; JAR F1038DC02FB103D470BF0BC88FEF56B29BB77C1C8525FF0120D42E6F68D2C3F7.
- RUNTIME: emulator DB demo + Portal UP — DEMO_SCRIPT tập trọn (≈ 7:35), lớp cố vấn ≈ 0,25 s sau làm nóng; -PhysicalDevice NOT_RUN.
- OWNER_VALIDATION: Set-DemoPasswords, Rotate-AppRolePassword, Start-Demo sau khi đóng Claude — NOT_RUN (cần owner).

## Database
- Target lms_mobile_group_demo. Ghi app schema SV 205 qua API: thẻ (sửa 2, thêm 6, vài lần ôn), thông báo nhắc riêng đã đọc.

## Đang chạy
- Không (Stop-Demo trước gate POLISH-8).

NEXT_ACTION: không còn việc trong phạm vi; chờ owner (5 việc ở TỔNG KẾT POLISH). Cập nhật GitHub sau này chỉ khi owner yêu cầu:
  commit-tree 'HEAD^{tree}' -p 12ef5ca312a5e3a557eb2c93116b2c89f231f2ea, push fast-forward.
NEXT_ACTION_IS_MUTATING: no.

## DO_NOT_REPEAT
- Không làm lại N1–N18, O1, E2, P0–P8, chạy emulator hạng A/B/C, migration V2, tạo DB demo.
- Không làm lại F0–F7, LOGIN, POLISH-1…8, quay video, đi DEMO_SCRIPT, push GitHub. CẤM push HEAD/tag cục bộ/--tags/--all (lịch sử có 6f8c0ab).
- Không gửi lại nhắc riêng N8 (đã gửi 1 lần cho SV 205), không generate lại kế hoạch chỉ để thử.
- Không chạy lại cleanup Storage-Maintenance-2026-11-09.
