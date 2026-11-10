# Hỗ trợ học tập LMS — DLU (đồ án tốt nghiệp, bảo vệ 20/11/2026)

Nhánh này là ảnh chụp mã nguồn bản bảo vệ 20/11/2026; lịch sử phát triển đầy đủ được lưu tại máy của nhóm.

Ứng dụng di động hỗ trợ sinh viên và giảng viên Trường Đại học Đà Lạt học tập trên LMS (Moodle): gom dữ liệu LMS và Portal đào
tạo vào một chỗ, giải thích con số (điểm còn cần, mức theo dõi) và biến chúng thành việc làm cụ thể (kế hoạch tuần, nhắc học, ôn
thẻ SM-2, nhắc riêng của giảng viên). Ứng dụng không thay Moodle: nộp bài, làm quiz, chấm điểm vẫn trên LMS.

## Kiến trúc

- **Flutter** (`frontend/`): app Android cho sinh viên và giảng viên; không kết nối thẳng CSDL.
- **Spring Boot 3 / Java 21** (`backend/`): REST API `/api/v1`, JWT, kiểm tra danh tính theo đường dẫn, chỉ nghe 127.0.0.1 khi chạy local.
- **PostgreSQL 18**: bản sao CSDL Moodle (schema `lms`, `derived` — chỉ đọc) + schema `app` (dữ liệu riêng của ứng dụng).
- **API Portal Online DLU Proxy**: bảng điểm, chương trình đào tạo, rèn luyện, quyết định học vụ, lớp cố vấn; chỉ backend gọi.

Sơ đồ: `docs/diagrams/*.mmd` (01 bối cảnh, 02 thành phần, 03 triển khai, 04 xác thực, …).

## Chạy thử

Hướng dẫn đầy đủ: [`docs/LOCAL_RUNBOOK.md`](docs/LOCAL_RUNBOOK.md) (mục "Ngày bảo vệ"). Tóm tắt trên Windows:

```powershell
.\tools\Start-Demo.ps1            # PostgreSQL + backend + emulator + mở app (thêm -PhysicalDevice cho điện thoại USB)
.\tools\Stop-Demo.ps1
```

Kịch bản demo 10 phút: [`docs/DEMO_SCRIPT.md`](docs/DEMO_SCRIPT.md). Hướng dẫn sử dụng: [`docs/USER_GUIDE.md`](docs/USER_GUIDE.md).
Bản phát hành, số test, SHA-256: [`docs/RELEASE_NOTES.md`](docs/RELEASE_NOTES.md).

## Dữ liệu

- **LMS:** dữ liệu mẫu tổng hợp (bản sao CSDL Moodle cung cấp cho đồ án), không phải dữ liệu sinh viên thật.
- **Portal:** dữ liệu mô phỏng do thầy Nguyễn Trọng Hiếu cung cấp qua API Portal Online DLU Proxy.
- Repo không chứa dữ liệu sinh viên thật, bản dump CSDL, mật khẩu hay API key. Cấu hình bí mật nằm trong `.local\backend.json`
  (git-ignore) do owner tạo bằng các script trong `tools\`.

## Chức năng

- Sinh viên: mô phỏng điểm, tình trạng học tập Xanh/Vàng/Đỏ, gợi ý ôn lại, vị trí trong lớp ẩn danh, ôn tập SM-2, kế hoạch tuần,
  nhắc học trên điện thoại, học tập trung, lịch tháng/tuần + .ics, tìm kiếm không dấu, tuần của bạn, thành tích, xem khi mất mạng,
  chế độ tối; Portal: GPA, tiến độ CTĐT, mô phỏng GPA, rèn luyện, quyết định học vụ.
- Giảng viên: dự báo qua môn, phân tích bài kiểm tra, bản đồ nhiệt, nhắc riêng + xuất CSV, tìm kiếm; lớp cố vấn (Portal) có ẩn danh.
- Đăng nhập bằng mã số sinh viên / tên tài khoản + mật khẩu; vai trò do máy chủ quyết định.

Chi tiết: [`docs/FEATURES_V2.md`](docs/FEATURES_V2.md), [`docs/FEATURES_V3.md`](docs/FEATURES_V3.md),
[`docs/COMPARISON_FACTS.md`](docs/COMPARISON_FACTS.md).

## Kiểm thử

`tools\Test-Backend.ps1 -Package` (JUnit) và `tools\Test-Flutter.ps1 -BuildApk` (flutter analyze + test + APK). Số liệu bản cuối
trong `docs/RELEASE_NOTES.md`.
