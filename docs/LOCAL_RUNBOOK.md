# Group local runbook

Use this NEW workspace only: D:\DLU-LMS-Group. No old database/Render configuration
is reused. Scripts do not change system JAVA_HOME/PATH.

## Tools and checks

PowerShell from workspace root:

```powershell
.\tools\Install-PortableBuildTools.ps1
.\tools\Test-Backend.ps1 -Package
.\tools\Test-Flutter.ps1 -BuildApk
```

Java21/Maven are portable under D:\DLU-LMS\Toolchains. Maven/Pub/Gradle caches and
temp/build output use D. Flutter SDK already supports Dart3.12.2. No Android Studio.
Backend database-dependent integration tests must remain explicitly excluded until
their isolated target is verified; a green unit suite is not database integration.

## Database prerequisite — currently blocked

> **Update 2026-10-31 (Claude):** the exact backup is available again at `D:\doan\lms_mobile_learning_backup.sql`; SHA256 re-verified as `936B84758CB87A36EA9D50BAD82DC99DDCF9F312CFCEF7E221829205041F4AD4`. File availability is resolved; restore remains gated (no approved target or import authorization). See docs/HANDOFF.md.

The exact lms_mobile_learning_backup.sql supplied earlier is missing from Downloads.
Restore the SAME file, then recheck its hash recorded in SOURCE_BASELINE.md.
Do not substitute the old mock SQL or run the source seed scripts.

An approved, new, empty PostgreSQL target is required. No server installation,
database creation/import or credential changes have been performed. Read the
database/README.md before restore. Run catalog verification after safe restoration.

## Backend configuration — after database is ready

Create a private, ignored .local/backend.json manually using the actual approved
local database credentials. Restrict its Windows file permissions to your account.
Do not paste values into chat or commit the file. Required keys:

- DB_URL: JDBC PostgreSQL URL for localhost/127.0.0.1 with explicit port and NEW
  database lms_mobile_group_dev. This launcher intentionally refuses remote/old DBs.
- DB_USERNAME and DB_PASSWORD: actual credentials of the approved local target.
- JWT_SECRET: cryptographically random secret of at least32 bytes, not a password
  or a sample literal. Never place it in Flutter.
- DEMO_STUDENT_ID and DEMO_TEACHER_ID: distinct identities whose enrollment/role
  must be verified in the restored group database; do not assume every dump has
  the same identities.

Then run:

```powershell
.\tools\Start-LocalBackend.ps1
```

Development role login is enabled only by this explicit local-development setup.
It is NOT Moodle production authentication and must never be publicly deployed.

## Flutter local APK/device connection

The build script uses a loopback API URL with adb reverse, so backend remains
bound to127.0.0.1 on Windows rather than exposing development login on the LAN.
For one authorized connected device/emulator:

```powershell
adb devices -l
adb -s <verified-device-id> reverse tcp:8081 tcp:8081
```

Use the group frontend APK (com.example.lms_mobile_app currently), not the old app.
Do not claim authenticated course data/runtime PASS until the restored DB and
backend are really running. An APK build alone does not prove that integration.
Physical devices need USB debugging authorization. No production release signing
has been configured; only debug APK is in scope.

## Handing off to Claude

Stop the current writer/builds, open Claude Code at D:\DLU-LMS-Group and ask it to
read CLAUDE.md plus docs/HANDOFF.md. Check git status before edits. Resume documented
steps; never silently swap in old runtime/database or report stale test results.

## Ngày bảo vệ (20/11/2026) — Start-Demo / Stop-Demo (V2-O1)

Chạy từ cửa sổ PowerShell của owner (không cần phiên Claude), tại `D:\DLU-LMS-Group`:

```powershell
.\tools\Start-Demo.ps1          # mặc định: DB lms_mobile_group_demo (đã dời ngày), Portal bật
.\tools\Stop-Demo.ps1           # tắt theo thứ tự ngược: emulator -> backend -> PostgreSQL
```

Tùy chọn: `-Database dev` (DB gốc, hạn nộp đều đã qua), `-NoEmulator` (chỉ PostgreSQL + backend),
`-PhysicalDevice` (điện thoại thật qua USB thay emulator), `-Apk <file>` (mặc định
`D:\DLU-LMS\Artifacts\final\dlu-lms-group-final-debug.apk` nếu có, nếu không là APK mới nhất trong Artifacts).

Bước 0 dừng nếu ổ C < 15 GiB và cảnh báo nếu < 22 GiB. Portal DOWN chỉ cảnh báo (phần LMS vẫn chạy). Cuối script in
**Tóm tắt demo**: database, Portal UP/DOWN/TẮT, thiết bị (serial + model), ổ C. Mỗi dịch vụ chạy trong cửa sổ PowerShell riêng tên
"DLU Demo - PostgreSQL/Backend/Emulator"; đóng cửa sổ Claude không làm tắt chúng.

### Đọc bảng SẴN SÀNG (cuối Start-Demo)

| Dòng | Đạt khi | Nếu không |
| --- | --- | --- |
| DB | `lms_mobile_group_demo` | chạy lại không kèm `-Database dev` |
| Backend | `/health UP, database CONNECTED` | xem cửa sổ "DLU Demo - Backend" |
| Portal | `UP, prewarm N/N` (N = M) | `prewarm 48/67` = đang làm nóng, đợi 1–2 phút; `DOWN` = bỏ đoạn Học vụ/Lớp cố vấn |
| Thiết bị | `emulator-5554 (…)` hoặc serial điện thoại | xem bước 5/8 |
| APK | `xxxxxxxxxxxx (= bản cuối)` | khác bản cuối → `Start-Demo.ps1 -Apk D:\DLU-LMS\Artifacts\final\dlu-lms-group-final-debug.apk` |
| Ổ C | ≥ 22 GiB | dọn ổ C |
| Kết luận | `SẴN SÀNG` | làm từng dòng "CẦN XỬ LÝ" in bên dưới |

Các kiểm tra chỉ đọc, chỉ cảnh báo, không đổi cài đặt Windows: máy đang chạy pin (Win32_Battery), Windows chờ khởi động lại
(RebootRequired, RebootPending, PendingFileRenameOperations), không có internet hoặc Portal không trả lời trong 5 s.

### Demo trên điện thoại thật qua USB (`-PhysicalDevice`)

1. Trên điện thoại: Cài đặt > Giới thiệu > bấm 7 lần "Số bản dựng" → Tùy chọn nhà phát triển > bật **Gỡ lỗi USB**.
2. Cắm cáp USB, chạy `.\tools\Start-Demo.ps1 -PhysicalDevice`, bấm **Cho phép** ở hộp thoại khóa RSA trên điện thoại.
3. Script chờ tối đa 120 s đến khi `adb devices` có máy thật (không phải `emulator-…`), chạy
   `adb reverse tcp:8081 tcp:8081`, cài APK cuối nếu máy chưa có bản đó (so SHA-256 với lần cài trước, lưu trong
   `.local\device-apk-<serial>.txt`), rồi mở app.
4. Backend vẫn chỉ nghe `127.0.0.1`; điện thoại đi qua `adb reverse`, không cần Wi-Fi chung, không mở cổng ra mạng.
5. Rút cáp là mất kết nối: cắm lại rồi chạy lại script (các bước đã chạy được dùng lại).
6. Nếu báo "Cài APK lỗi" vì khác chữ ký: `adb uninstall com.example.lms_mobile_app` rồi chạy lại.

### Checklist (làm theo thứ tự)

1. Hôm trước: ổ C còn **≥ 22 GiB** (emulator làm pagefile trên C tăng ~6 GiB khi khởi động; script dừng nếu < 15 GiB).
2. Hôm trước: chạy thử `Start-Demo.ps1` → đủ 8 bước OK → `Stop-Demo.ps1`.
3. Rút sạc/chế độ ngủ: tắt Sleep của Windows trong lúc demo.
4. Mở PowerShell 7, `cd D:\DLU-LMS-Group`, chạy `.\tools\Start-Demo.ps1`.
5. Xác nhận dòng `[4/8] … status UP, database CONNECTED, portal UP`.
6. Xác nhận `[8/8] đã mở ứng dụng` và màn chọn vai trò hiện trên emulator.
7. Sinh viên: dashboard có thẻ GPA (Portal), "Tình trạng học tập", "Hôm nay: N việc", "Học tập trung".
8. Giảng viên: trang chủ có "Lớp cố vấn ITK47A" và "hoạt động sắp đến hạn trong 7 ngày tới".
9. Không đóng 3 cửa sổ "DLU Demo - …" trong lúc trình bày.
10. Xong: `.\tools\Stop-Demo.ps1` → "Đã dừng demo."

### 5 sự cố thường gặp

| Sự cố | Dấu hiệu | Cách xử lý |
| --- | --- | --- |
| Cổng bận (55432/8081) | `[3/8] cổng 8081 đã có tiến trình` nhưng dữ liệu cũ, hoặc PostgreSQL báo port in use | `.\tools\Stop-Demo.ps1` rồi chạy lại `Start-Demo.ps1` (Stop tắt mọi Java của backend và pg_ctl stop). |
| Emulator treo / màn đen | `[6/8]` quá 240 s | Đóng cửa sổ "DLU Demo - Emulator"; `& D:\DLU-LMS\Android\Sdk\emulator\emulator.exe -avd DLU_LMS_Pixel -no-snapshot-load` (cold boot); chạy lại `Start-Demo.ps1` (bước đã chạy được dùng lại). |
| Mất `adb reverse` (app báo không kết nối máy chủ) | Màn hình lỗi mạng sau khi emulator khởi động lại | `D:\DLU-LMS\Android\Sdk\platform-tools\adb.exe reverse tcp:8081 tcp:8081` rồi kéo để làm mới. |
| Backend 401 (token hết hạn) | Mọi màn báo phiên hết hạn / 401 | Trong app bấm quay lại màn chọn vai trò và chọn lại vai trò (đăng nhập demo lấy token mới). Nếu vẫn lỗi: khởi động lại backend bằng Stop/Start-Demo. |
| Ổ C đầy | `[1/8]` hoặc `[5/8]` báo C < 15 GiB, hoặc emulator tự tắt | Dọn Thùng rác, `%TEMP%`, thư mục Downloads; KHÔNG xóa D:\DLU-LMS. Có thể chạy `Start-Demo.ps1 -NoEmulator` và dùng điện thoại thật. Chuyển pagefile sang D cần quyền admin (owner quyết). |
