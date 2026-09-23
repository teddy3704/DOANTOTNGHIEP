# Checklist trình diễn LMS Support — GROUP_39_20

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
