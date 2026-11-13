# REAL-DATA-1 — Nạp dữ liệu LMS thật (Khoa CNTT) vào `lms_mobile_group_real`

Chỉ số tổng hợp. Không có username, email, điểm hay dòng dữ liệu của ai trong tài liệu này.
Dữ liệu gốc nằm ngoài repo: `D:\DLU-LMS\RealData\Data_11-2026\Data_11-2026` (bị `.gitignore` chặn:
`/Data_*/`, `**/RealData/`, `*.rar`). Ảnh chụp màn hình: `D:\DLU-LMS\RealData\screens\` (ngoài repo).

## Nguồn

- Bản xuất Moodle do GVHD cung cấp (11/2026), 19 file CSV + `query.txt`. Không có dòng tiêu đề, giá trị
  trong `"`, `NULL` không có ngoặc, `""` là dấu nháy, có xuống dòng trong ô. Thứ tự cột theo `install.xml`
  của MOODLE_401_STABLE (bản 4.0/4.1). Đã kiểm tra trên từng file: số cột đồng nhất mọi dòng, vị trí cột
  khớp kiểu dữ liệu (epoch, khóa ngoại, giá trị liệt kê).
- Phạm vi giữ lại: 173 khóa của `dlu_course_cntt.csv` (năm học 2024–2025 đến 2026–2027) cùng user,
  ghi danh, vai trò, bài tập, bài kiểm tra và sổ điểm liên quan. Không gọi `lms.dlu.edu.vn`.
- Cột email của `dlu_user.csv` bị bỏ **trước khi** vào PostgreSQL (`tools/real-import/strip_user_email.py`).
  `lms."user".email` là `''` với mọi dòng. Mật khẩu ghi danh (`enrol.password`) không được chép.
  Schema staging `stg` (bản sao toàn trường) bị xóa ngay sau khi nạp.

## Cách chạy (owner)

```
.\tools\Import-RealData.ps1            # hỏi mật khẩu postgres (SecureString), ~40 s
.\tools\Import-RealData.ps1 -Recreate  # dựng lại; chỉ DROP đúng lms_mobile_group_real
```

Các bước: bỏ email → `CREATE DATABASE lms_mobile_group_real` → chép schema (không dữ liệu) bằng
`pg_dump --schema-only lms_mobile_group_demo` → `database/grants_lms_group_app.sql` →
`database/real/10_stage.sql` (COPY csv vào `stg`, mọi cột text, `NULL 'NULL'`) → `20_load_lms.sql`
(INSERT … SELECT có ép kiểu) → `30_substitutes.sql` (bảng dựng thay thế) → `40_views.sql` (view riêng
cho real) → `50_report.sql` (báo cáo tổng hợp, lưu `D:\DLU-LMS\RealData\import-report-*.txt`) →
`60_cleanup.sql` (xóa `stg`, VACUUM ANALYZE). Mọi DROP/TRUNCATE trong SQL đều có guard
`current_database() = 'lms_mobile_group_real'`. Không dời ngày: `shift_demo_dates.sql` không chạy lên real.
`lms_mobile_group_demo` và `lms_mobile_group_dev` chỉ được đọc schema, không bị sửa.

Đã chạy thử trọn vẹn (Windows PowerShell 5.1) trên một cụm PostgreSQL 18 dùng một lần, cổng 55499,
dựng từ đúng backup + migration V2 + grants của nhóm: 38–39 s.

## Số dòng sau import

| Bảng `lms` | Dòng | Loại |
| --- | ---: | --- |
| course | 173 | xuất |
| course_categories | 41 | xuất |
| course_sections | 1.287 | xuất |
| course_modules | 6.442 | xuất |
| modules | 32 | xuất |
| assign | 2.165 | xuất |
| assign_submission | 79.384 | xuất |
| assign_grades | 12.084 | xuất |
| grade_items | 2.725 | xuất |
| grade_grades | 163.913 | xuất (lọc từ ~3,2 triệu dòng toàn trường) |
| quiz_attempts | 6.735 | xuất |
| quiz_grades | 4.860 | xuất |
| enrol | 345 | xuất |
| user_enrolments | 10.851 | xuất |
| role | 12 | xuất |
| role_assignments | 10.928 | xuất |
| context | 6.657 | xuất |
| user | 2.996 | xuất (không email, không họ tên) |
| **quiz** | 150 | **dựng thay thế** |
| **grade_categories** | 166 | **dựng thay thế** |
| **course_modules_completion** | 77.737 | **dựng thay thế** |
| **logstore_standard_log** | 65.105 | **dựng thay thế** |
| attendance, attendance_sessions, attendance_log, attendance_statuses, user_lastaccess, course_completions, resource, folder, forum, cohort, groups… | 0 | không có trong bản xuất |

Khác: 2.907 user có MSSV 7 chữ số; 2.972 sinh viên có ghi danh; 39 khóa bắt đầu từ 15/07/2026.
Ghi chú nạp: 2 `user_enrolments.modifierid` trỏ tới tài khoản không có trong bản xuất được thay bằng chính
`userid` (cột kiểm toán, app không dùng); 322 `grade_grades.usermodified` như vậy thành NULL; 21 danh mục
cha nằm ngoài phạm vi CNTT thành NULL.

Kiểm tra: không có cột thời gian nào ngoài 0..2^31. Khớp tham chiếu: submission → user 99,98% (bỏ 3.662
dòng nộp theo nhóm có userid 0), course_modules → assign/quiz 100%, grade_items → grade_categories 100%,
quiz_attempts → quiz 100%.

## Bảng thay thế và cách tính

| Không có | Thay bằng | Nhãn trên app |
| --- | --- | --- |
| `quiz` | **Cập nhật 12/11 tối:** GVHD gửi thêm `dlu_quiz_cntt.csv` (150 dòng, 42 cột Moodle 4.x, khớp 150/150 quiz instance của grade_items). Import dùng file này (nhận cả tên `dlu_quiz.csv`): tên, timeopen, timeclose, timelimit, attempts, sumgrades, grade thật; **không nạp** password/subnet (đã trống). 116/150 bài có timeclose > 0, 149 có sumgrades > 0. Không có file thì dựng từ `grade_items` như trước (timeclose = 0). | Bài có hạn đóng: vào Việc cần làm, Lịch, cảnh báo như bài tập (vẫn chỉ học kỳ hiện tại). Không hạn: "Không đặt hạn đóng". Phân tích bài kiểm tra: % lượt làm = sumgrades lượt / sumgrades bài. |
| `grade_categories` | Mỗi khóa một danh mục gốc, id = iteminstance của mục itemtype='course', giả định Natural (13), tên = tên khóa. | — |
| Trọng số mục | `aggregationcoef2`; nếu tổng của danh mục bằng 0 thì chia theo grademax. | — |
| `course_modules_completion` | Chỉ hoạt động có chấm điểm (module hiện, có grade item). Hoàn thành khi: assign có submission `submitted` hoặc đã có điểm; quiz có `quiz_grades` hoặc lượt làm `finished`; attendance, h5p, lesson… có finalgrade. Thời điểm = bằng chứng sớm nhất. | "Tiến độ (theo hoạt động có chấm điểm)" |
| `logstore_standard_log`, `user_lastaccess` | Chỉ sự kiện nộp bài: submission `submitted` tại timemodified, lượt làm quiz `finished` (không preview) tại timefinish. Không dùng thời điểm giảng viên chấm. contextlevel 50, origin 'derived' (không có sự kiện xem hoạt động nên app không bao giờ nói "chưa mở"). | "… ngày chưa nộp bài hoặc làm bài kiểm tra", "Số lượt nộp bài và làm bài kiểm tra theo ngày", "Chuỗi ngày nộp bài" |
| Bảng điểm danh | finalgrade / grademax của grade item mod/attendance (132 mục); khóa có nhiều mục thì cộng điểm / cộng điểm tối đa. Số buổi = NULL. | "Điểm chuyên cần (theo điểm danh trên LMS)", không hiện từng buổi; không có điểm thì "Không có dữ liệu điểm danh trên LMS" |
| Tên resource/url/forum/folder/page/videotime | Theo loại ("Tài liệu", "Liên kết", "Diễn đàn", "Thư mục", "Trang", "Video") kèm tên chương (`course_sections.name`, mặc định "Chủ đề N"/"Chung"). h5p/lesson/attendance dùng tên mục điểm thật. | như cột trái |
| firstname, lastname, idnumber | idnumber = username khi là 7 chữ số (đăng nhập bằng MSSV). firstname = username (MSSV với sinh viên, username với giảng viên), lastname = ''. Không bịa họ tên. | "Xin chào, <MSSV>" |

View riêng cho real (`database/real/40_views.sql`, cùng tên/cột với snapshot nên backend không đổi SQL):
- Sinh viên của khóa = ghi danh đang hoạt động **và** có role student trong context khóa (snapshot dùng role
  mặc định của phương thức ghi danh, khiến giảng viên cũng thành "sinh viên").
- Việc cần làm và cảnh báo (risk) chỉ xét **khóa của học kỳ hiện tại**: bắt đầu từ 15/07/2026 và chưa hết hạn
  (`realimport.settings.term_start`). Nhiều khóa 2024–2025 không có ngày kết thúc nên nếu không giới hạn,
  bài từ năm trước sẽ hiện "quá hạn 600+ ngày". Màn Khóa học và Điểm vẫn hiện mọi khóa. App ghi
  "Việc cần làm · Học kỳ hiện tại".
- Chỉ hoạt động đang hiện với sinh viên; "đã hoàn thành" gồm cả bài đã có điểm.
- Hai tập phụ trợ (sinh viên của khóa, hoạt động có chấm điểm) là bảng có index trong `realimport`, dựng một
  lần lúc import (dữ liệu tĩnh) để mỗi truy vấn theo sinh viên không tính lại: tìm kiếm 6,4 s → 0,6 s.

Backend: `app.data-profile=real` (Start-LocalBackend tự đặt khi DB_URL là real) → đăng nhập trả
`dataProfile`, lý do cảnh báo và đơn vị biểu đồ dùng chữ "nộp bài hoặc làm bài kiểm tra"; dữ liệu real
không bị gắn nhãn "minh họa". Truy vấn đếm hoàn thành bỏ điều kiện `cm.completion <> 0` (trên snapshot:
412 dòng hoàn thành, 0 dòng thuộc module không theo dõi, nên dev/demo không đổi).

## Tỉ lệ khớp trọng số

`aggregationcoef2` (chuẩn hóa lại trên các mục sinh viên đã có điểm) so với `grade_grades.aggregationweight`
của các dòng `aggregationstatus = 'used'`, sai số ≤ 0,001: **29.972 / 30.027 = 99,82%**. Toàn bộ 30.027 dòng
lấy trọng số từ aggregationcoef2 (không khóa nào phải chia theo grademax).

## Portal

`tools\Test-PortalStudents.ps1` (chỉ nhận 3 MSSV nhóm): Portal trả lời bình thường (lớp đã cấu hình OK),
nhưng **không có dữ liệu** cho 2212472, 2212496, 2212412 (không thuộc lớp nào, không có bảng điểm với CTĐT
đã cấu hình, quyết định 404). Trên real các màn Học vụ/GPA hiện "Chưa có dữ liệu Portal cho MSSV này".

## Kiểm thử

- `mvn test`: 297 chạy, 0 lỗi, 1 skip (có `RealDataProfileTest` 7 test: nhãn real, quiz không hạn,
  lịch không có buổi điểm danh, bản đồ nhiệt rỗng, user chỉ có mã số).
- `RealDatabaseQueriesIT` (6 test, chỉ chạy khi `REAL_TEST_DB_URL` trỏ tới cụm dùng một lần, không phải
  55432): chạy SQL thật của repository dưới quyền `lms_group_app` trên real: bảng điểm danh rỗng → danh
  sách rỗng, không có log xem hoạt động, quiz không hạn/không quá hạn, user không tên/không email. 6/6 đạt.
- `flutter test`: tất cả đạt (có `real_data_profile_test.dart`).

## Quy tắc cảnh báo trên dữ liệu thật (REAL-DATA-2, 12/11 tối)

Điểm theo dõi giữ nguyên trọng số của snapshot: lâu chưa nộp +25/+40, quá hạn +15/+30, tiến độ <60%/<30% +10/+25,
7 ngày không nộp +10; nhóm: ≥60 cần hỗ trợ, ≥30 cần theo dõi. Có một thay đổi cho real:

- **"Lâu chưa nộp bài" (+25/+40) và "7 ngày không nộp" (+10) chỉ tính khi sinh viên có bài ĐÃ QUÁ HẠN mà chưa nộp.**
  Lý do: trên dữ liệu thật, tín hiệu duy nhất là nộp bài. Một sinh viên đã nộp hết, hoặc chỉ còn bài chưa tới hạn,
  thì không có gì để nộp. Trước khi sửa, khóa Đồ án tốt nghiệp (học kỳ hiện tại, 1 bài, 93/93 em đã nộp)
  bị xếp 93/93 em "cần theo dõi" chỉ vì đã lâu không có bài mới. Sau khi sửa: 0/93.
- Các nguồn "thiếu dữ liệu" khác vốn đã không gây cờ: bài giới hạn theo nhóm lớp chỉ tính khi có bằng chứng
  truy cập; khóa không có hoạt động chấm điểm không có tiến độ (không cộng điểm); bài chưa tới hạn không bao giờ
  là "quá hạn"; quiz không đặt hạn đóng không bao giờ quá hạn.

Khóa Mẫu Thiết kế CTK47 (học kỳ hiện tại, bắt đầu 09/2026, 124 sinh viên): 52 em (42%) ở nhóm theo dõi, gồm 39 cần
hỗ trợ và 13 cần theo dõi. Quy tắc mới không đổi con số này, vì cả 52 em đều có bài quá hạn thật:
- Khóa có 12 bài tập, 11 bài đã qua hạn (bài gần nhất qua hạn 1 ngày trước ngày kiểm tra). Không bài nào nộp
  theo nhóm (teamsubmission = 0), không bài nào giới hạn theo nhóm lớp, chưa bài nào được chấm.
- 51/52 em quá hạn từ 3 bài trở lên, 1 em quá hạn 2 bài. 21 em chưa nộp bài nào trong khóa.
- Tổ hợp lý do: 29 em = lâu chưa nộp + quá hạn + tiến độ thấp + 7 ngày không nộp; 10 em = lâu chưa nộp + quá hạn +
  7 ngày không nộp; 7 em = tiến độ thấp + quá hạn; 6 em = chỉ quá hạn (≥3 bài).
Kết luận: tỉ lệ 42% phản ánh bài quá hạn chưa nộp có thật trên LMS, không phải do thiếu dữ liệu.
