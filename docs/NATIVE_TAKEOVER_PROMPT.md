# Nhiệm vụ cho phiên Claude Code native trên Windows (2026-10-31)

Do chủ dự án giao. Không chứa secret. Phiên cloud/desktop trước đó đã dừng sửa source.

## 0. Nhận ca (làm trước tiên)

1. Xác minh đây là runner Windows native: `$PSVersionTable.PSVersion`, `[Environment]::OSVersion.VersionString`,
   `(Get-Location).Path` phải là `D:\DLU-LMS-Group`. Không phải WSL hay Linux VM.
2. Thêm một dòng vào đầu mục WRITER_TRANSFER trong `docs/HANDOFF.md`:
   `WRITER_TRANSFER: ACCEPTED by native Claude Code <claude --version> at <giờ +07>`.
   Từ thời điểm đó phiên này là writer duy nhất. Không chạy hai build hoặc migration cùng lúc.

## 1. Đọc trước khi sửa

AGENTS.md, CLAUDE.md, backend/AGENTS.md, frontend/AGENTS.md, docs/HANDOFF.md, docs/TASK_BOARD.md,
docs/ACCESS_MATRIX.md, docs/API_CONTRACT.md, docs/SOURCE_BASELINE.md, docs/LOCAL_RUNBOOK.md,
database/README.md. Hướng dẫn gốc dài: docs/CLAUDE_ACCESS_AND_RELAY_PROMPT.md.

## 2. Gate theo thứ tự

1. Đọc `tools/Use-LocalToolchain.ps1` và `tools/Test-Backend.ps1` trước khi chạy, rồi chạy:
   `.\tools\Test-Backend.ps1`
   Test mặc định là cô lập (SchemaVerificationTest đang @Disabled). Không bỏ @Disabled.
2. Sửa lỗi, chạy lại cho đến khi exit 0. Ghi tổng số surefire (tests/failures/errors/skipped).
3. `.\tools\Test-Backend.ps1 -Package`.
4. `.\tools\Test-Flutter.ps1`. Lệnh này chạy `dart format .` và có thể ghi lại file: liệt kê các file bị đổi.
5. Debug APK (`-BuildApk`) chỉ khi C còn trống ≥15GB. Cần kiểm tra Android SDK tại D:\DLU-LMS\Android\Sdk.
6. Runtime API + emulator chỉ sau khi có DB thật đã được duyệt. Hiện đang BLOCKED.

SQL gốc: `D:\doan\lms_mobile_learning_backup.sql`, SHA256 `936B84758CB87A36EA9D50BAD82DC99DDCF9F312CFCEF7E221829205041F4AD4`.
Chỉ đọc. Không import hoặc restore khi chưa có target trống được duyệt và chưa có chấp thuận riêng.

## 3. Giới hạn

- Giữ nguyên mọi thay đổi chưa commit. Không reset, clean, stash, commit, push hoặc gắn remote.
- Không cài lại Java/Maven/Flutter và không đổi JAVA_HOME/PATH toàn máy. D:\doan và Toolchains chỉ đọc.
- Nếu ExecutionPolicy chặn script: KHÔNG đổi policy máy. Hỏi chủ dự án trước khi dùng
  `powershell -ExecutionPolicy Bypass -File ...` cho riêng một tiến trình.
- Không dùng --dangerously-skip-permissions. Không đổi credential, Render/Neon/Supabase, không deploy.
- Không in secret, env value hoặc data row. Không báo PASS khi chưa chạy thật; gate chưa chạy ghi NOT_RUN.
- Thư mục `.claude/` sinh ra trong workspace chưa nằm trong .gitignore: không commit nó.
- Cập nhật docs/HANDOFF.md và docs/TASK_BOARD.md sau mỗi milestone.
