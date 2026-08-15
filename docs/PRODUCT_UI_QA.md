# Product UI QA

**Ngày kiểm tra:** 2026-08-16

**Thiết bị:** `DLU_LMS_Pixel`, Android 15/API 35, 1080 × 2400

**Entrypoint:** `lib/main_development.dart` với canonical synthetic dataset

**Trạng thái:** `PASS` cho product presentation flow; live Moodle integration vẫn blocked bên ngoài

Tài liệu này ghi kết quả sau khi thực hiện các quyết định trong `PRODUCT_UI_AUDIT.md`. Dữ liệu ảnh là dữ liệu hư cấu dành cho development/test; trạng thái này không đồng nghĩa Moodle API DLU đã được tích hợp.

## Final navigation

```text
Splash → Login → Trang chủ
                    ├── Khóa học → Course Detail → Assignment / Grades
                    ├── Lịch
                    └── Hồ sơ
```

Primary navigation cuối cùng gồm đúng bốn destination: `Trang chủ`, `Khóa học`, `Lịch`, `Hồ sơ`. Shell dùng bottom navigation trên phone và navigation rail ở viewport rộng.

## Screen evidence

| Screen | Evidence | QA result |
|---|---|---|
| Login | [01-login.png](screenshots/production-polish/01-login.png) | PASS — không có DEV/fixture label hoặc backend status; production variant giữ credential surface fail-closed. |
| Trang chủ | [02-dashboard.png](screenshots/production-polish/02-dashboard.png) | PASS — hierarchy greeting/priorities/courses/calendar rõ; không fake notification. |
| Khóa học | [03-courses.png](screenshots/production-polish/03-courses.png) | PASS — card compact, search/filter usable, nội dung theo học phần đã enroll. |
| Course Detail | [04-course-detail.png](screenshots/production-polish/04-course-detail.png) | PASS — overview/content/resources/tasks/grades có hierarchy; resource sheet scroll-safe. |
| Assignment | [05-assignments.png](screenshots/production-polish/05-assignments.png) | PASS — deadline/submission/feedback có ngữ cảnh; không có implementation disclaimer. |
| Grades | [06-grades.png](screenshots/production-polish/06-grades.png) | PASS — chỉ hiển thị điểm đã phát hành; không suy diễn average/weight/chart. |
| Lịch | [07-calendar.png](screenshots/production-polish/07-calendar.png) | PASS — group theo ngày, course context thân thiện, không raw event type/ID. |
| Hồ sơ | [08-profile.png](screenshots/production-polish/08-profile.png) | PASS — identity tối thiểu, theme local, logout; không endpoint/token/internal ID. |

## Automated coverage

| Gate | Result |
|---|---|
| `dart format .` | PASS — 66 files, 0 changed |
| `flutter analyze` | PASS — 0 issues |
| `flutter test` | PASS — 50/50 |
| DEV debug APK (`lib/main_development.dart`) | PASS — 193,806,149 bytes |
| Production debug APK (`lib/main.dart`) | PASS — 193,806,149 bytes |
| App shell destinations and navigation | PASS |
| Full student demo flow | PASS |
| Dashboard loading/success/error/retry presentation | PASS |
| Courses search/filter and state handling | PASS |
| Course Detail nullable deadline/resource behavior | PASS |
| Assignment/Grades state handling | PASS |
| Calendar grouping/friendly labels/state handling | PASS |
| Profile theme/logout/identity presentation | PASS |
| Production Login no-credential/friendly fail-closed state | PASS |
| User-facing technical-copy regression | PASS |

## Runtime observations

- Fresh product-polish run reached the first frame and completed the direct flow without the earlier transient Android ANR prompt recurring.
- Không quan sát crash, blank route, navigation dead-end, unhandled Flutter exception hoặc layout overflow trong walkthrough.
- Android native default focus highlight trên toàn bộ Flutter view đã được tắt; Flutter widget semantics/focus behavior vẫn giữ nguyên. Ảnh `02`–`08` được chụp lại từ emulator sau fix và không còn viền focus nền tảng.
- Production APK được cài lại trực tiếp trên cùng emulator: Login hiển thị trạng thái chưa sẵn sàng thân thiện, có `0` credential field và `0` forbidden technical/dev match trong UI hierarchy.
- Android predictive-back callback được khai báo để loại warning platform hiện tại; navigation vẫn do `go_router` quản lý.
- Course Detail no longer force-unwraps a nullable assignment deadline, and the resource sheet can scroll within a short viewport.

## Presentation safety checks

- Không hiển thị `DEV`, `FIXTURE`, `MOCK`, `SYNTHETIC`, `DEBUG`, raw blocker code hoặc technical implementation status trên các màn hình chụp.
- Không hiển thị token, cookie, password, endpoint, database/schema/repository detail hoặc nội dung từ browser session DLU.
- Email trong evidence dùng reserved synthetic domain `example.test`; tên và nội dung học phần đều hư cấu.
- Production data source vẫn fail closed; fixture không phải và không được gọi là Moodle integration.

## Remaining external gates

- `AUTHENTICATION_METHOD_UNCONFIRMED`
- `MOODLE_WEB_SERVICES_NOT_ENABLED`
- `TEST_ACCOUNT_REQUIRED`
- `MOODLE_API_TOKEN_REQUIRED` sau khi service được DLU bật/phê duyệt

Các blocker này không làm giảm trạng thái PASS của UI/synthetic emulator milestone, nhưng tiếp tục chặn mọi tuyên bố production Moodle integration.
