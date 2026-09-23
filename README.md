# DLU LMS Support

Đồ án “Xây dựng ứng dụng di động và hỗ trợ học tập trên nền tảng LMS” của nhóm Đại học Đà Lạt. Ứng dụng Flutter giúp sinh viên xem học phần, bài cần làm, tiến độ, điểm và lời nhắc; giúp giảng viên theo dõi lớp, công việc và sinh viên cần hỗ trợ. [DLU LMS](https://lms.dlu.edu.vn/) vẫn là hệ thống chính thức cho xác thực, nộp bài, quiz, chấm điểm và quản trị học phần.

## Bản đã xác minh ngày 23/09/2026

| Thành phần | Trạng thái |
|---|---|
| Database First | PostgreSQL development/staging dữ liệu mẫu: 3 schema `lms`/`app`/`derived`, 39 bảng vật lý (35 + 4), 20 view, 39 PK, 38 FK, 548 cột. **Không phải database production DLU.** |
| Backend | Node.js, TypeScript, Fastify, PostgreSQL; Render staging; Student + Teacher GET API với scope server-side; 54 test PASS |
| Flutter | Android, Material 3, Riverpod, go_router và repository tách production/staging; `flutter analyze` PASS, 167/167 test PASS; runtime Student/Teacher và đổi role PASS |
| Bằng chứng | APK debug staging `D:\DoAnTotNghiep\evidence\mobile\DLU_LMS_Support_staging_final_debug.apk`, 15 ảnh `evidence/mobile/group39-20-final/` |
| Chưa xác minh | DLU Authentication/Web Services `TO_VERIFY_DLU`; Android notification fire `NOT_VERIFIED` vì dataset cuối không có deadline tương lai phù hợp |

Luồng hiện chạy: `Flutter → HTTPS → Render staging → Fastify API → PostgreSQL lms/app/derived`. Identity mẫu của staging **không phải** tài khoản DLU. Production entrypoint `lib/main.dart` không tự fallback sang dữ liệu mẫu. Mobile chỉ mở link LMS chính thức khi người dùng muốn nộp bài hoặc chấm điểm; không có Mobile academic write.

## Chạy lại khi cần

Không dùng Android Studio. SDK/JDK/cache/build đã đặt trên D theo `tool/flutter_dlu.ps1`. Emulator hiện có: `DLU_LMS_Pixel`; không tạo AVD mới để xem demo.

```powershell
# Từ worktree Flutter này; cần emulator online và mạng để gọi Render staging.
.\tool\flutter_dlu.ps1 run -t lib/main_staging.dart

# Quality gate chỉ chạy lại khi có thay đổi Flutter hoặc cần xác minh mới.
.\tool\flutter_dlu.ps1 analyze
.\tool\flutter_dlu.ps1 test
```

API local cần Node 24 và cấu hình `.env` riêng trong `integration-api/` (không commit, không in giá trị). Chỉ dùng database development/staging được cấp quyền; không tự tạo DB production hoặc đổi Render.

```powershell
Set-Location integration-api
npm ci --cache D:\DLU-LMS\Cache\npm
npm run build
npm test
npm run dev
# API local: http://localhost:3000/health và /docs
```

Để xem API staging đã deploy, mở `https://dlu-lms-student-support-staging.onrender.com/health` và `/docs`; Render Free có thể cold start. Không đặt Neon credential trong URL, Postman export hay source.

## Đọc và trình diễn

- [Trạng thái cuối](docs/PROJECT_STATUS.md), [kết quả Flutter](docs/FLUTTER_TEST_RESULT.md), [đối chiếu báo cáo](docs/REPORT_ALIGNMENT_NOTES.md).
- [Kịch bản hội đồng](demo/COUNCIL_DEMO_SCRIPT.md), [checklist](demo/DEMO_CHECKLIST.md), [Q&A và kiến trúc](docs/council/README.md).
- SQL demo chỉ đọc: `demo/01_verify_database_baseline.sql`, `demo/02_council_database_demo.sql`.
- `docs/FINAL_TRACEABILITY_MATRIX.md` nối yêu cầu → bảng/view → API → màn → hành động LMS.

Phần Supabase foundation lịch sử chỉ dành dữ liệu app-owned (theme preference), chưa thay Moodle hay được bật làm nguồn học vụ. `main_development.dart` là đường dữ liệu synthetic riêng; không nhầm với staging cuối hoặc production.

Quy tắc kỹ thuật/bảo mật của repository: [AGENTS.md](AGENTS.md). Không commit `.env`, credential, dữ liệu DLU thật hoặc APK.
