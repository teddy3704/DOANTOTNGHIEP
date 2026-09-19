# Checklist trình diễn LMS Support

Các dấu chọn phải dựa trên lần mở máy trước buổi báo cáo, không kế thừa máy móc.

- [ ] Có Internet; mở được https://lms.dlu.edu.vn/.
- [ ] Render `/health` trả `ok`; chờ cold start Free instance nếu cần.
- [ ] `adb devices -l`: DLU_LMS_Pixel / emulator-5554 online.
- [ ] Cài APK cuối theo `docs/FLUTTER_TEST_RESULT.md`; không cài Android Studio.
- [ ] Chọn SV001: Home, Courses, Assignment, Progress, Profile có dữ liệu.
- [ ] Chọn GV001: Teacher Home, Courses, Work, Calendar, Profile đúng vai trò.
- [ ] Quyền thông báo đã cấp; lời nhắc lưu được và bật/tắt được.
- [ ] Chỉ bấm “Mở LMS”, “Nộp bài trên LMS”, “Chấm bài trên LMS”; **không nộp/chấm**.
- [ ] pgAdmin dùng kết nối Neon hiện hữu; không tạo database mới.
- [ ] Chạy `01_verify_database_baseline.sql`: số liệu đúng phiên bản báo cáo.
- [ ] Giải thích baseline staging hiện tại 22 bảng khác mô hình nhóm 39 bảng.
- [ ] Có schema export nhóm `lms_mobile_learning_schema.sql` (**đang thiếu**).
- [ ] Có mock SQL backup (**không import bản nhóm vào Neon hiện tại**).
- [ ] Có ảnh runtime, APK và OpenAPI local.

## Dự phòng khi mạng yếu

- APK và ảnh: `D:\DoAnTotNghiep\evidence\mobile\`.
- DDL/seed baseline hiện tại và OpenAPI: `D:\DoAnTotNghiep\evidence\council-backup\`.
- Mock nhóm: `group_mock_data_AUTH_DISABLED.sql` trong thư mục backup; khác schema
  hiện tại, chỉ dùng đọc/đối chiếu. Word gốc và SQL gốc vẫn ở Downloads.
- SQL demo/script: thư mục `demo/` trong worktree hiện tại.
- Không có video; không yêu cầu cài phần mềm mới. Khi offline, Student hiển thị
  lỗi/thử lại thật; dùng ảnh và contract, không tự đổi Student sang dữ liệu giả.
- Dữ liệu mô phỏng đã chọn được khôi phục khi mở lại. Không có mật khẩu demo hay
  nút reset phá dữ liệu. Đổi hồ sơ bằng “Đổi dữ liệu mô phỏng” trong Profile.

## Lệnh sử dụng

```powershell
& D:\DLU-LMS\Android\Sdk\platform-tools\adb.exe devices -l
Invoke-RestMethod https://dlu-lms-student-support-staging.onrender.com/health
# Mở hai file SQL trong pgAdmin bằng kết nối đã lưu; chỉ chạy SELECT/READ ONLY.
```

Không đưa connection string vào slide, terminal, Postman hay ảnh. Không đổi
database/seed để làm số liệu báo cáo “khớp”.
