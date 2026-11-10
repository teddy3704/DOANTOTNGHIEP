# Chức năng V3 — Tích hợp Portal đào tạo DLU

Tài liệu cho báo cáo. Dữ liệu đào tạo lấy từ API Portal Online DLU Proxy do thầy Nguyễn Trọng Hiếu cung cấp. Đây là dữ liệu mô
phỏng có cấu trúc giống Portal đào tạo của Trường; ứng dụng đã thiết kế sẵn các biện pháp bảo vệ để nối với dữ liệu thật.

Ý tưởng lõi:
- **Moodle** biết sinh viên *đang học gì tuần này*: hoạt động, bài nộp, quiz.
- **Portal đào tạo** biết sinh viên *đã học được gì cả khóa*: bảng điểm, GPA, tín chỉ, CTĐT, rèn luyện, quyết định học vụ.
- Ứng dụng là **cầu nối**: biến tiến độ trên LMS thành dự báo GPA tích lũy và xếp loại (P3); gộp hai nguồn cho cố vấn học tập (P6).

Nhãn: **Khác biệt** / **Tiện ích** theo cùng định nghĩa ở `FEATURES_V2.md`. Nhãn là đề xuất của nhóm; bảng so sánh với Moodle
và Portal do phiên cloud kiểm chứng (`COMPARISON_FACTS.md`).

## Bảng tổng hợp

| Chức năng | Vai trò | Nhãn đề xuất | Nguồn dữ liệu | Thuật toán / công thức | Test |
| --- | --- | --- | --- | --- | --- |
| P0 Nền tảng tích hợp | — | — | Portal (POST + X-API-KEY) | Cache bộ nhớ TTL 10 phút, retry 1 lần, health 60 s | `PortalClientTest` 13, `PortalSupportTest` 7, `PortalPropertiesBindingTest` 2 |
| P1 Bảng điểm và GPA của tôi | SV | Tiện ích | `LayBangDiemSinhVien` | GPA Portal (TB_TL_HK_4) + GPA tự tính để đối chiếu | `AcademicEngineTest`, `StudentPortalServiceTest`, `portal_test.dart` |
| P2 Tiến độ chương trình đào tạo | SV | Khác biệt | `LayDanhSachHocPhanTheoCTDT` (gốc + chuyên ngành) + P1 + LMS | Trạng thái học phần, điều kiện tiên quyết | như trên |
| P3 Mô phỏng GPA, mục tiêu xếp loại | SV | Khác biệt | P1 + P2 + N1 (LMS) | Bảng quy đổi suy từ bảng điểm; need(band) | như trên |
| P4 Điểm rèn luyện của tôi | SV | Tiện ích | `LayBangDiemRenLuyenTheoLop` (lọc dòng của mình) | — | như trên |
| P5 Quyết định học vụ | SV | Tiện ích | `LayDanhSachQuyetDinh` | Phát hiện "cảnh báo học vụ" → liên kết P3 | như trên |
| P6 Lớp cố vấn học tập | GV | Khác biệt | `LayBangDiemSinhVienTheoLop`, `LayBangDiemRenLuyenTheoLop`, `LayDanhSachSinhVienTheoLop` + N9 (LMS) | Dò học kỳ có dữ liệu; cờ cần quan tâm; ẩn danh | `AdvisorPortalServiceTest` 8, `PortalSecurityTest` 5, `portal_test.dart` |
| P7 Nguồn dữ liệu và quyền riêng tư | SV, GV | Khác biệt | Cấu hình server + trạng thái nguồn | — | `portal_test.dart` |
| P8 Hoàn thiện | — | — | — | Trạng thái loading / chưa liên kết / chưa kết nối / lỗi + thử lại; cache client 5 phút | `portal_test.dart` |

Mọi endpoint nằm dưới `/api/v1/dev/students/{userId}/portal/…` hoặc `/api/v1/dev/teachers/{teacherId}/portal/…`:
- `PathIdentityAuthorizationManager`: người khác → 403; không token → 401.
- Chưa ánh xạ → 404 `{"code":"PORTAL_NOT_LINKED"}`; Portal tắt → 503 `PORTAL_DISABLED`; Portal lỗi → 503 `PORTAL_UNAVAILABLE`.

## Quyền riêng tư theo thiết kế (privacy by design)

Thiết kế cho Portal thật, giữ nguyên khi dùng dữ liệu mô phỏng:
1. **Không cho người dùng nhập MSSV.** API chỉ xác thực bằng key, nên nhập MSSV người khác là xem được bảng điểm của họ. Ánh xạ
   `userId → MSSV, CTĐT, lớp` và `teacherId → lớp cố vấn` do server cấu hình. Triển khai thật sẽ lấy MSSV từ đăng nhập SSO của Trường.
2. **App không gọi Portal.** Chỉ backend giữ key; key nằm trong `.local\backend.json` (git-ignore), không vào repo, APK, log.
3. **Tối thiểu hóa dữ liệu.** `PortalParser` chỉ đọc các trường cần cho học tập (bảng ở mục 1 của `V3_PORTAL_PROMPT.md`). Không ánh
   xạ: số điện thoại, ngày sinh, nơi sinh, hộ khẩu, giới tính, trường `*_Eng`, số hiệu bằng, quyết định tốt nghiệp, người cập nhật.
   Test khẳng định JSON trả về không chứa các giá trị này.
4. **Không tích hợp `LayDanhSachMienGiamHocPhi`.** Dữ liệu miễn giảm học phí cho biết đối tượng chính sách hoặc dân tộc, thuộc nhóm
   dữ liệu cá nhân nhạy cảm theo Nghị định 13/2023/NĐ-CP. Ứng dụng không cần dữ liệu này cho học tập nên không gọi endpoint.
5. **Không lưu vào CSDL.** Phản hồi Portal chỉ nằm trong cache bộ nhớ của backend (TTL 10 phút, tối đa 500 mục) và cache client
   (5 phút, xóa khi đăng xuất/đổi vai trò). Log chỉ ghi endpoint, mã trạng thái, thời gian, số bản ghi; test bắt log ở mức DEBUG.
6. **Lọc theo người gọi.** Endpoint "theo lớp" trả cả lớp; backend lọc trước khi trả: SV chỉ nhận dòng của mình (P4), GV chỉ nhận
   lớp cố vấn được cấu hình (P6). Tín hiệu LMS trong P6 chỉ hiện khi SV nằm trong khóa Moodle do chính GV dạy.
7. **Ẩn danh khi trình chiếu.** Màn giảng viên có công tắc: tên → "SV 01", MSSV → `23**A0**`; chi tiết mở theo số thứ tự nên MSSV
   không lộ trên đường dẫn. Mặc định do server quyết định: BẬT cho Portal thật, TẮT trong profile demo vì dữ liệu là mô phỏng.
   Xuất CSV chỉ khi đã tắt ẩn danh và xác nhận; ô bắt đầu bằng `= + - @` được vô hiệu hóa (chống chèn công thức).

## Đăng nhập bằng mã số sinh viên (LOGIN, 10/11/2026)

- **Màn "Đăng nhập"** giống LMS của Trường: ô "Mã số sinh viên / Tên đăng nhập" (SV dùng MSSV ở `lms.user.idnumber`, ví dụ
  2312005; GV dùng username, ví dụ teacher02) và "Mật khẩu" (nút hiện/ẩn). Vai trò do **máy chủ** quyết định theo tài khoản; không
  còn bước chọn vai trò. "Ghi nhớ mã số" chỉ lưu mã số trên máy, không bao giờ lưu mật khẩu; token chỉ nằm trong bộ nhớ.
  "Đăng xuất" (góc trái trang chủ) xóa token, cache ngoại tuyến N11 và lịch nhắc N7 trên máy.
- **API** `POST /api/v1/auth/login {login, password}` → JWT như cũ (issuer, audience, sub = userId, role). Sai mật khẩu hay tài
  khoản không tồn tại đều trả 401 với **một thông báo chung** "Mã số hoặc mật khẩu không đúng"; tài khoản không tồn tại vẫn so một
  hash BCrypt giả nên thời gian xử lý như nhau. **Khóa tạm:** 5 lần sai trong 15 phút cho cùng login + IP → 429 kèm `Retry-After`
  (bộ nhớ, `LoginAttemptLimiter`). Body: đúng 2 trường, login 1–64, mật khẩu 1–128 ký tự, tối đa 2 KB. Log chỉ có kết quả
  (OK/FAIL/LOCKED), userId khi OK, độ dài login.
- **Nhà cung cấp (`AuthProvider`):**
  - `LocalCredentialProvider` (bật trong demo): tài khoản trong `.local\backend.json` (khối `AUTH`, git-ignore), mỗi mục
    `{login, userId, role, bcrypt}`, BCrypt cost 12 của Spring Security. Owner đặt mật khẩu bằng `tools\Set-DemoPasswords.ps1`
    (ô nhập ẩn; băm bằng `BcryptCli` trong JAR backend). Không dùng cột `lms.user.password` (là chuỗi giả trong bản dump).
  - `MoodleTokenProvider` (**TẮT**, `app.auth.moodle.enabled=false`): luồng như ứng dụng Moodle chính thức — `POST
    {lms}/login/token.php` (service `moodle_mobile_app`) rồi `core_webservice_get_site_info` lấy userid; vai trò suy từ dữ liệu LMS
    (dạy ít nhất một khóa → GV). Chỉ kiểm thử bằng `MockRestServiceServer`; **không gọi vào lms.dlu.edu.vn** khi chưa có văn bản
    cho phép của Trường. Triển khai thật chỉ cần bật provider này (https), MSSV lấy từ tài khoản đã xác thực nên ánh xạ Portal không
    còn cấu hình tay.
- **demo-login cũ** chỉ tồn tại khi profile `local-development` + `DEMO_AUTH_ENABLED`; trong app là nút nhỏ "Chế độ demo" dưới form,
  chỉ hiện ở bản build local — dự phòng ngày bảo vệ.
- MSSV thật của thành viên nhóm không có trong dữ liệu mẫu và **không** được gán vào tài khoản mẫu (sẽ là gán sai danh tính).
- Test: BE `LoginApiTest` (7: SV/GV đúng role, sai = không tồn tại, khóa 5 lần + mở lại sau 15 phút bằng đồng hồ giả, body sai 400,
  log không chứa login/mật khẩu, demo-login không có khi tắt cờ, token mới vẫn qua PathIdentity: 201 đọc 205 → 403),
  `MoodleTokenProviderTest` (3: token hợp lệ, sai mật khẩu, web service tắt); FE `login_test` (11).

## P0. Nền tảng tích hợp

- `PortalProperties` (`app.portal.*`): enabled, baseUrl, apiKey, cacheTtl 10 phút, connect 5 s, read 15 s, students, advisors,
  courseMap, lmsStudentLinks, presentationMask, gradeBands, conductThreshold (50).
- `PortalClient`: `RestClient` của Spring, header `X-API-KEY`, retry 1 lần với lỗi IO/5xx (backoff 500 ms), 4xx không retry.
  Envelope `ok=false` hoặc JSON sai → 503. Số dạng chuỗi → `BigDecimal`, `""` → null, ngày `dd/MM/yyyy`.
- `/api/v1/health` có thêm `portal: UP | DOWN | DISABLED` (cache 60 s). Portal tắt hay lỗi không ảnh hưởng chức năng LMS.
- Script owner `tools\Set-PortalConfig.ps1` (nhập key ẩn, hỏi ánh xạ, ghi gộp vào `.local\backend.json`, in tóm tắt đã che).

## P1. Bảng điểm và GPA của tôi

- Bảng điểm theo năm học/học kỳ: học phần, tín chỉ, điểm hệ 10, hệ 4, chữ, đạt/chưa đạt; học kỳ đang học hiện "Đang học".
- GPA học kỳ và tích lũy (hệ 4, hệ 10), tín chỉ tích lũy, xếp loại; biểu đồ đường GPA học kỳ và tích lũy; lọc "Chưa đạt".
- **Số chính thức:** `TB_TL_HK_4` của học kỳ cuối có điểm. **Đối chiếu:** GPA tự tính = Σ TC × điểm hệ 4 / Σ TC, chỉ học phần
  `IsGather` và không `NotComputeAverageScore`, lấy lần học cuối có điểm của mỗi học phần. Với SV demo, chênh lệch = 0,00.
- Dashboard SV: thẻ đầu tiên "GPA tích lũy · số tín chỉ · còn thiếu X TC bắt buộc" kèm "Dữ liệu Portal đến HKx năm …".
- Dữ liệu tĩnh: "dữ liệu đến" là học kỳ mới nhất **có điểm**, không suy từ đồng hồ máy.

## P2. Tiến độ chương trình đào tạo

- CTĐT = chương trình gốc + chuyên ngành: `CQ23CT-PM` chỉ chứa học kỳ 5–8, phần học kỳ 1–5 nằm ở `CQ23CT` (khảo sát API 09/11).
  Mã trùng chỉ giữ một lần.
- Trạng thái (ưu tiên từ trên xuống): **Đã đạt** → **Chưa đạt** (có điểm, chưa đạt) → **Đang học trên LMS** (ánh xạ `courseMap`) →
  **Đang học** (đã đăng ký trên Portal, chưa có điểm) → **Chưa học**.
- Tổng hợp: TC bắt buộc đạt/tổng, TC tự chọn đã đạt, % hoàn thành = TC bắt buộc đã đạt / TC bắt buộc. `groupSelection` rỗng nên
  không tính yêu cầu nhóm tự chọn (API trả `electiveGroupsKnown=false`).
- Tiên quyết: `HPTienQuyet` phải **đạt**, `HPHocTruoc` phải **đã học**; hỗ trợ danh sách ngăn bằng dấu phẩy, chấm phẩy, khoảng
  trắng. Danh sách "Đủ điều kiện đăng ký" và "Chưa đủ điều kiện" kèm học phần còn thiếu. Dữ liệu mô phỏng hiện không có tiên quyết.

## P3. Mô phỏng GPA và mục tiêu xếp loại — cầu nối quan trọng nhất

- Ngưỡng (Thông tư 08/2021/TT-BGDĐT, hệ 4, cấu hình `gradeBands`): Xuất sắc ≥ 3,6; Giỏi ≥ 3,2; Khá ≥ 2,5; Trung bình ≥ 2,0.
  Cần đối chiếu với quy chế đào tạo của Trường ĐH Đà Lạt trước khi dùng thật.
- Ký hiệu: G = GPA tích lũy chính thức, C = TC tính GPA (như P1), R = TC còn lại = TC bắt buộc chưa đạt + TC đang học (LMS/Portal).
- **need(band) = (band × (C + R) − G × C) / R.** need ≤ 0 → Đã chắc; ≤ 4 → Khả thi; > 4 → Không còn khả thi. R = 0 → Đã chắc khi
  G ≥ band.
- **Cầu nối LMS:** với học phần có ánh xạ Moodle, lấy `current` (%) từ engine N1 → hệ 10 = % / 10 → điểm chữ → hệ 4.
  GPA dự kiến = (G × C + Σ TC × điểm4) / (C + Σ TC); R giảm tương ứng.
- **Bảng quy đổi** suy từ chính bảng điểm SV: với mỗi điểm chữ, DiemTK_10 nhỏ nhất/lớn nhất và DiemTK_4. Chữ chưa từng gặp dùng
  bảng mặc định A ≥ 8,5 → 4; B ≥ 7,0 → 3; C ≥ 5,5 → 2; D ≥ 4,0 → 1; F → 0 (API trả cờ `derived`). Điểm nằm giữa hai khoảng
  quan sát rơi về chữ thấp hơn.
- App tính lại tức thì khi SV chọn "nếu tôi được…" (`GpaSimulator`, cùng công thức; test đối chiếu số với backend).
- Ví dụ thật (SV demo, dữ liệu mô phỏng): 2 môn đang học trên LMS → GPA dự kiến 3,30; để đạt Giỏi cần 2,67 ở 21 TC còn lại.

## P4. Điểm rèn luyện của tôi

- Năm học lấy từ bảng điểm P1; gọi tuần tự HK01, HK02 của từng năm (tối đa 10 lần, có cache); chỉ giữ dòng của chính SV.
- Hiển thị tự đánh giá, lớp, khoa, điểm cuối, xếp loại (Xuất sắc ≥ 90, Tốt ≥ 80, Khá ≥ 65, Trung bình ≥ 50, Yếu ≥ 35, Kém) và
  biểu đồ cột theo học kỳ.

## P5. Quyết định học vụ của tôi

- Danh sách quyết định của chính SV (tên, loại, ngày ký, năm học, học kỳ, nội dung), mới nhất trước.
- Tên chứa "cảnh báo học vụ/học tập" (không phân biệt dấu) → thẻ cảnh báo + nút "Xem mức cần đạt" mở P3.

## P6. Lớp cố vấn học tập

- Chỉ lớp trong `advisors[teacherId]`; lớp khác → 404.
- Học kỳ: dò từ năm sau năm hiện tại lùi tối đa 8 năm (HK02, HK01), lấy các học kỳ **có điểm**; mặc định học kỳ mới nhất có dữ liệu.
- Tổng quan: sĩ số (`IsInClass`), ĐTB lớp hệ 4, chênh lệch so với học kỳ có dữ liệu liền trước, phân bố xếp loại, histogram
  ĐTB [0;1), [1;2), [2;2,5), [2,5;3,2), [3,2;3,6), [3,6;4].
- Cần quan tâm: ĐTB hệ 4 < 2,0; xếp loại Yếu/Kém; rèn luyện < ngưỡng (50); chưa có điểm.
- Chi tiết SV: ĐTB học kỳ/tích lũy, tín chỉ, xếp loại, rèn luyện, lịch sử theo học kỳ. **Cầu nối cho GV:** nếu MSSV khớp
  `lms.user.idnumber`, hoặc khớp ánh xạ server, **và** SV nằm trong khóa Moodle của GV → hiện tín hiệu N9 (mức, điểm theo dõi,
  tiến độ, việc quá hạn) của các khóa đó; ngược lại "Chưa có dữ liệu LMS cho sinh viên này".
- Xuất CSV (UTF-8 BOM): chỉ khi tắt ẩn danh + xác nhận; app sao chép vào clipboard. Xuất file thật sẽ dùng chung với N8.

## P7. Nguồn dữ liệu và quyền riêng tư

Trạng thái LMS và Portal (hoạt động/mất kết nối/chưa kết nối, lần cập nhật gần nhất, thời gian lưu tạm), trường dùng và không dùng
kèm lý do (gồm miễn giảm học phí), liên kết (lớp cố vấn, ánh xạ khóa Moodle ↔ học phần, nhãn "ánh xạ demo").

## P8. Hoàn thiện tích hợp

- Mọi màn P: loading; chưa liên kết; chưa kết nối; Portal lỗi + "Thử lại". Thẻ dashboard ẩn khi chưa liên kết; chỉ hiện "Thử lại"
  khi Portal 503.
- Cache client 5 phút, xóa khi đăng xuất/đổi vai trò.
- E2 (09/11, backend local, API thật, dữ liệu mô phỏng): mỗi lời gọi Portal chưa cache 140–255 ms; endpoint ghép nhiều lời gọi
  khi chưa cache 1,1–2,0 s (summary 1110 ms, rèn luyện 6 học kỳ 1268 ms, lớp cố vấn 1958 ms); khi có cache 2–27 ms.

## Ánh xạ demo (cấu hình server, không phải dữ liệu nhập từ người dùng)

| Đối tượng | Ánh xạ | Lý do chọn |
| --- | --- | --- |
| SV demo (Moodle 205) | MSSV `2347A008`, CTĐT `CQ23CT-PM`, lớp `ITK47A` | Gợi ý của phụ lục; 8 học kỳ, 64 học phần, có học kỳ đang học |
| Moodle 13 Software Testing | `20CT3206` Kiểm thử phần mềm | Có trong học kỳ đang học của SV mô phỏng, chưa có điểm |
| Moodle 14 Mobile Application Development | `20CT4106D` Phát triển ứng dụng di động nâng cao | Học phần di động duy nhất trong CTĐT, chưa có điểm |
| Moodle 3000015 Hỗ trợ học tập số | không ánh xạ | CTĐT không có học phần tương ứng; không ghép gượng |
| GV demo (Moodle 102) | lớp cố vấn `ITK47A` | 66 SV, dữ liệu điểm và rèn luyện 2023-2024…2025-2026 |
| Moodle 206, 207, 208 | 3 SV khác của ITK47A có điểm HK2 2025-2026 | Minh họa cầu nối GV (cùng khóa của GV 102) |

## Giới hạn đã biết

- Dữ liệu tĩnh và mô phỏng; endpoint gắn nhãn "Developing" có thể đổi. Code chịu lỗi: trường lạ bị bỏ qua, số/ngày không đọc được
  → null, envelope lỗi → 503.
- Trang docs có 2 key `mk_dev_` khác nhau; chỉ một key còn hiệu lực (key kia trả 401).
- Yêu cầu tín chỉ tự chọn chưa có trong dữ liệu (`groupSelection` rỗng) nên "còn thiếu" chỉ tính TC bắt buộc.
- Ngưỡng xếp loại và xếp loại rèn luyện theo thông tư; cần đối chiếu quy chế riêng của Trường.
