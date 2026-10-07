# DLU LMS Support

Đồ án “Xây dựng ứng dụng di động và hỗ trợ học tập trên nền tảng LMS” của nhóm Đại học Đà Lạt. Ứng dụng Flutter giúp sinh viên xem học phần, bài cần làm, tiến độ, điểm và lời nhắc; giúp giảng viên theo dõi lớp, công việc và sinh viên cần hỗ trợ. [DLU LMS](https://lms.dlu.edu.vn/) vẫn là hệ thống chính thức cho xác thực, nộp bài, quiz, chấm điểm và quản trị học phần.

## Checkpoint hiện tại — hardening 07/10/2026

Nhánh `innovation-perfection-hardening` tiếp tục milestone innovation `2e04089`,
không thay `main` (`c773b7e`) hay hệ thống LMS chính thức. Candidate đã sửa 94
assignment states bị mất JOIN và 3 next-item đã completed; 42 bảng/20 views/588
cột/42 PK/45 FK/29 CHECK, row/type digests giữ nguyên. Ba view definitions được
sửa có kiểm chứng, không tuyên bố “views không đổi” cho checkpoint mới.

Flutter hardening mục tiêu **107/107 PASS**: owner biểu mẫu, timestamp/NULL deadline,
timeout hữu hạn, loading/retry và layout 320/390px với text scale 1.3/1.5.
Final format PASS (156 files/0 changes), analyze0 issues, **245 tests PASS +1
opt-in live skipped**; live payload chạy riêng PASS. Backend96/96 tests/audit0,
real local/staging181 checks mỗi môi trường PASS; c5231e2 Live Render hiện hữu.
Runtime phát hiện/sửa vòng đời coordinator khi xử lý plan qua mạng chậm, có test
hồi quy và APK sửa đã PASS Student/Teacher/isolation/network recovery. APK cuối
`D:\DLU-LMS\Artifacts\DLU_LMS_Support_Perfection_Final_Debug.apk`, SHA/SDK/size
trong evidence/perfection/apk.json; giữ nguyên APK innovation và QA bị loại.
Xem [Perfection QA](docs/PERFECTION_FINAL_QA.md) và
[preflight](scripts/council_preflight.ps1). Preflight API diagnostics PASS nhưng
worktree chưa freeze nên chưa gọi READY. pgAdmin UI chờ người dùng nhập kết nối
candidate đã được duyệt; không chụp/điều khiển credential. Toàn bộ council gate
vẫn PARTIAL đến khi bước UI này được quan sát, không suy từ SQL runner PASS.
DLU auth/Web Services vẫn **TO_VERIFY_DLU**; production cần DB role least-privilege.

## Milestone innovation đã PASS — 06/10/2026 (baseline được giữ)

`innovation-study-planner-intervention` bổ sung **Student Smart Study Planner**
và **Teacher Intervention Inbox** vào hệ thống hiện có. Sinh viên nhận ưu tiên
có lý do, tạo/sửa/hoãn kế hoạch học và nhắc giờ; giảng viên ghi nhận hỗ trợ, hẹn
theo dõi và xem lịch sử/snapshot. Thao tác này chỉ ghi dữ liệu thuộc ứng dụng
trong `app.*`; nộp bài, quiz và chấm điểm vẫn ở LMS.

Đây là quy tắc có thể giải thích từ deadline, trạng thái bài và tiến độ hiện có,
**không AI**, không tự suy ra dữ liệu thiếu. Flutter staging dùng API repository
thật; lỗi mạng không đổi sang fixture. Production entrypoint không chọn dữ liệu
mẫu. Identity staging không phải tài khoản hay xác thực DLU.

**PRODUCT/RUNTIME PASS:** migration đã áp dụng và xác minh trên candidate: 3 schema,
42 bảng (35 `lms` + 7 `app`), 20 views, 42 PK, 45 FK, 588 cột. Original rows,
`lms` columns và derived views không đổi. Backend build/typecheck/format-check
và 82/82 tests PASS; local real API CRUD/scope smoke 181 checks PASS
(`evidence/innovation/local-smoke.json`). Render backend `a0c2cb7` đã **Live** trên
nhánh innovation ở service hiện hữu; environment/database secret không đổi.
Public workflow 181 checks PASS (`evidence/innovation/staging-smoke.json`);
separate patched read-only regression 165 checks PASS (runtime checkpoint / Final QA).
Flutter format/analyze PASS, **224 tests PASS + 1 opt-in live test skipped**;
live contract đã chạy riêng PASS. Responsive UI dùng AppTheme.light, 320/390px,
text scale 1.3; lỗi validation tồn đọng khi sửa form đã được sửa và regression
test PASS. APK cuối build 17.4s, cài/force-stop/relaunch thành công trên
`DLU_LMS_Pixel`: `D:\DLU-LMS\Artifacts\DLU_LMS_Support_Innovation_Final_Debug.apk`
(221,242,818 bytes; package `vn.edu.dlu.lmsmobile`, minSdk 24, targetSdk 36).
Student tạo/sửa/hoãn/handled và restore kế hoạch đúng; nhắc học đã **delivered**
lúc 17:22 với nội dung generic, handled hủy alarm và không thay trạng thái LMS.
Teacher ghi nhận hỗ trợ → follow-up → resolved/history persist qua restart;
đổi SV001/SV002/GV001 không lẫn plan hay navigation. [15 PNG thật](evidence/mobile/innovation-final/)
ghi lại các bước đã kiểm tra. Chỉ xóa plan kiểm thử của mình qua UI xác nhận để
trình diễn lại, không xóa dữ liệu LMS. Final candidate/index secret scan và diff
check PASS. Commit hash tra từ Git; receipt push nhánh innovation được bàn giao
ở kết quả cuối, không dùng hash suy đoán. Kết quả cuối nằm ở
[PROJECT_STATUS](docs/PROJECT_STATUS.md); 167/54 dưới đây chỉ là baseline lịch sử.
Final read-only verification after runtime also PASS: original rows/columns/
views unchanged, SV001 plan cleanup persists, Teacher resolved case/history
persists. [Final QA](docs/INNOVATION_FINAL_QA.md) records these actual checks.

APK SHA256: `D34037F56D4D456D74B119E627A802DCEE4B70283EA7D328792BD70763B6AF06`.

- [Đóng góp sản phẩm](docs/PRODUCT_DIFFERENTIATION.md), [phản hồi góp ý](docs/REVIEWER_FEEDBACK_RESPONSE.md).
- [Kiến trúc innovation](docs/INNOVATION_ARCHITECTURE.md), [truy vết](docs/FINAL_TRACEABILITY_MATRIX.md).
- [Kịch bản innovation](demo/COUNCIL_DEMO_SCRIPT_INNOVATION.md), [checklist](demo/DEMO_CHECKLIST.md).

## Baseline đã xác minh ngày 23/09/2026 (lịch sử, được giữ nguyên)

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
