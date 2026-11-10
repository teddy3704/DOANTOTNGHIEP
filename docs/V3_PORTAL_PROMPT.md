# V3 — TÍCH HỢP PORTAL ĐÀO TẠO DLU (API của thầy Hiếu) VÀ LÀM RÕ KHÁC BIỆT VỚI LMS

Phiên cloud soạn ngày 09/11/2026. Phiên native là writer duy nhất. Mọi quy tắc và gate của V2 vẫn giữ nguyên: không ghi vào `lms`, không push hay deploy, gate sau mỗi chức năng, ghi HANDOFF theo mẫu, fail 3 lần thì ghi BLOCKED rồi làm tiếp.

## 0. Vì sao có V3 — đọc kỹ

Hai yêu cầu của giảng viên hướng dẫn:

1. **Ứng dụng phải khác LMS một cách rõ ràng và chứng minh được lợi ích**, đồng thời **phải lấy dữ liệu đào tạo từ API của thầy Hiếu** (Portal Online DLU Proxy).
2. **Sơ đồ phải chi tiết và rõ**, mỗi sơ đồ đứng riêng, không dồn chung một màn hình đến mức lan man. Phải có so sánh để thấy ứng dụng khác các hệ thống khác ở đâu và có lợi gì.

**Ý tưởng lõi để bảo vệ:**
- **Moodle** biết sinh viên *đang học gì tuần này*: hoạt động, bài nộp, quiz.
- **Portal đào tạo** biết sinh viên *đã học được gì cả khóa*: bảng điểm, GPA, tín chỉ, chương trình đào tạo, điểm rèn luyện, quyết định học vụ.
- Hai hệ thống **không nói chuyện với nhau**. Ứng dụng là **cầu nối**: biến hoạt động trên LMS thành dự báo ảnh hưởng tới GPA tích lũy, tín chỉ và xếp loại tốt nghiệp. Với giảng viên cố vấn, ứng dụng gộp hai nguồn vào một chỗ.

**Thứ tự ưu tiên mới:**
1. Làm xong chức năng V2 đang làm dở và qua gate.
2. Làm **toàn bộ Đợt P** (mục 4) và **Sơ đồ** (mục 5).
3. Quay lại phần V2 còn lại theo thứ tự cũ.

## 1. Sự thật về API (phiên cloud đã kiểm tra ngày 09/11/2026)

- Docs: https://kg8vuz7mh4.apidog.io/. Base URL: `https://quan-ly-dao-tao-api.nguyentronghieu.io.vn`.
- `GET /health` trả `{"app":"ok","db":"ok"}` (đã gọi thử, đang chạy).
- Mọi endpoint nghiệp vụ đều là **POST**, header `X-API-KEY: <key>` và `Content-Type: application/json`.
- Envelope chung `{ "status": 200, "ok": true, "body": … }`.
- Tất cả endpoint đều gắn nhãn "Developing", tức API có thể thay đổi hoặc ngừng. Code phải chịu lỗi tốt.
- Nhiều số trả về dạng chuỗi (`"2.77"`, `"3"`). Có giá trị `null` và chuỗi rỗng. Ngày theo dạng `dd/MM/yyyy`.

| Endpoint | Body | Trường được phép dùng |
| --- | --- | --- |
| `/api/v1/LayDanhSachSinhVienTheoLop` | `{"Id":"ITK47C"}` | StudentID, StudentNameWithoutID, ClassStudentID, StudyProgramID, IsInClass, ClassRoleID |
| `/api/v1/LayBangDiemSinhVienTheoLop` | `{"YearStudy":"2025-2026","TermId":"HK02","Id":"ITK47C"}` | StudentID, HoLot, FirstName, STC, AverageScore, AverageScore4, AverageGatherScore, AverageGatherScore4, Ranks, BehaviorScore, BehaviorScoreRank |
| `/api/v1/LayBangDiemRenLuyenTheoLop` | `{"YearStudy":"2024-2025","TermId":"HK02","Id":"ITK46B"}` | `body.resultDanhSach[]`: StudentID, StudentScore, ClassScore, DepartmentScore, LastScore, StatusID |
| `/api/v1/LayBangDiemSinhVien` | `{"p1":"<MSSV>","p2":"<StudyProgramID>","p3":"ALL","p4":"ALL"}` | `body[].NamHoc` → `DanhSachDiem[].HocKy` → `DanhSachDiemHK[]`: CurriculumID, CurriculumName, Credits, DiemTK_10, DiemTK_4, DiemTK_Chu, IsPass, IsGather, NotComputeAverageScore, TB_HK_4, TB_HK_10, TB_TL_HK_4, TB_TL_HK_10, Dat_HK, Dat_TL_HK, TenXepLoai, YearStudy, TermID |
| `/api/v1/LayDanhSachHocPhanTheoCTDT` | `{"p1":"CQ23CT-PM"}` | `body.tbStudyPrograms[]`: MaHP, TenHP, STC, LT, TH, HocKy, TermID, YearStudy, BatBuoc, HPTienQuyet, HPHocTruoc, MaCTDT. `body.groupSelection` / `groupSelection2` (cấu trúc chưa rõ, ví dụ rỗng) |
| `/api/v1/LayDanhSachQuyetDinh` | `{"p1":"<MSSV>"}` | DecisionName, DecisionTypeID, FullText, SignDate, YearStudy, TermID |
| `/api/v1/LayDanhSachMienGiamHocPhi` | — | **KHÔNG TÍCH HỢP**. Xem quy tắc 3.4 |

Mã lớp hợp lệ theo docs: ITK46A, ITK46B, ITK47A, ITK47B, ITK47C, ITK48A, ITK48B, ITK49A, ITK49B, ITK49C.
CTĐT: CQ25CT, CQ24CT, CQ23CT, CQ23CT-PM, CQ23CT-MMT, CQ22CT, CQ22CT-PM, CQ22CT-MMT.

## 2. Đây là dữ liệu THẬT của sinh viên DLU — quy tắc bắt buộc

1. **API key**
   - Không bao giờ xuất hiện trong repo, APK, log, HANDOFF, ảnh chụp hay console.
   - Trang docs có hiển thị công khai một key `mk_dev_…`. **Không chép key đó vào file nào.** Owner sẽ tự nhập key do thầy Hiếu cấp, bằng script ở mục 3.
   - Flutter **không gọi Portal trực tiếp**, chỉ backend gọi.
2. **Danh tính**
   - API chỉ xác thực bằng key, không xác thực từng sinh viên. Vì vậy **không bao giờ cho người dùng tự nhập MSSV**, vì nhập MSSV người khác là xem được bảng điểm của họ.
   - Ánh xạ `userId → MSSV, StudyProgramID, ClassStudentID` (sinh viên) và `teacherId → [mã lớp cố vấn]` (giảng viên) **do server cấu hình**, giống nguyên tắc "ID do máy chủ quyết định" đã có.
   - Với bản demo, owner cấu hình MSSV của **một thành viên nhóm đã đồng ý** cho dùng dữ liệu của mình.
   - Ghi rõ trong docs: triển khai thật sẽ lấy MSSV từ đăng nhập SSO của trường.
3. **Tối thiểu hóa dữ liệu**
   - DTO chỉ ánh xạ các trường ở bảng mục 1, dùng `@JsonIgnoreProperties(ignoreUnknown = true)`.
   - **Không ánh xạ, không lưu, không hiển thị:** MobilePhone, BirthDay, BirthPlace, PermanentResidence, Gender, `*_Eng`, SoHieuBang, QuyetDinhTotNghiep, UpdateStaff.
4. **Không tích hợp `LayDanhSachMienGiamHocPhi`.** Dữ liệu này cho biết đối tượng chính sách hoặc dân tộc, thuộc nhóm dữ liệu cá nhân nhạy cảm theo Nghị định 13/2023/NĐ-CP. Ghi lý do vào `FEATURES_V3.md` như một quyết định "privacy by design". Đây là điểm mạnh khi bảo vệ.
5. **Không lưu phản hồi Portal vào CSDL**
   - Chỉ cache trong bộ nhớ backend, TTL mặc định 10 phút, khóa cache theo (endpoint, tham số).
   - Log chỉ ghi endpoint, mã trạng thái, thời gian và **số bản ghi**. Không log body.
6. **Các endpoint "theo lớp" trả về cả lớp.** Backend phải lọc ra đúng phần người gọi được phép xem trước khi trả về. Sinh viên chỉ nhận dòng của chính mình.
7. **Chế độ ẩn danh khi trình chiếu** cho màn hình giảng viên: mặc định **BẬT** trong profile demo.
   - Tên hiển thị thành "SV 01", "SV 02"…; MSSV bị che thành `23**C0**`.
   - Có công tắc trong màn hình, nhưng server quyết định giá trị mặc định.
8. **Khi phiên Claude kiểm thử với dữ liệu thật**
   - Chỉ in số bản ghi và danh sách trường có mặt. **Không in tên, MSSV hay điểm** ra console hoặc HANDOFF.
   - Ảnh chụp có dữ liệu thật phải ở chế độ ẩn danh. Ngoại lệ duy nhất là màn hình sinh viên của chính thành viên đã đồng ý; với màn này vẫn che MSSV.
9. **Fixture test hoàn toàn bịa** (ví dụ "Nguyễn Văn A", "2399Z001", "ITK99Z"). Không dùng phản hồi thật làm fixture.

## 3. P0 — Nền tảng tích hợp (làm trước, không cần key thật)

**Cấu hình `PortalProperties`:**
- `enabled`, `baseUrl`, `apiKey`, `cacheTtl`, `connectTimeout` (5 s), `readTimeout` (15 s).
- `students` (map `userId → {studentId, studyProgramId, classId}`).
- `advisors` (map `teacherId → [classId]`).
- `courseMap` (map `lms courseId → MaHP`, tùy chọn).
- `presentationMask` (mặc định true).
- `gradeBands` (ngưỡng xếp loại, xem P3).

**`PortalClient`:**
- Dùng `RestClient` của Spring, không thêm thư viện HTTP mới. Header `X-API-KEY`.
- Retry 1 lần với lỗi IO hoặc 5xx, backoff 500 ms.
- Envelope có `ok=false` hoặc lỗi parse thì ném `PortalUnavailableException`. API của ứng dụng trả **503** `{"code":"PORTAL_UNAVAILABLE"}`.
- Parser an toàn: chuỗi số chuyển sang `BigDecimal`, `""` chuyển thành null, ngày đọc theo `dd/MM/yyyy`.

**Cache và health:**
- Cache trong bộ nhớ dùng `ConcurrentHashMap` kèm thời điểm hết hạn, có giới hạn số mục.
- `/api/v1/health` thêm trường `portal: UP | DOWN | DISABLED`, kết quả cache 60 giây.

**Trạng thái tắt:** Portal tắt hoặc chưa cấu hình thì mọi màn P hiện "Chưa kết nối Portal đào tạo" kèm giải thích. Chức năng LMS không bị ảnh hưởng.

**Script owner `tools\Set-PortalConfig.ps1`:**
- Nhập key bằng `Read-Host -AsSecureString`.
- Hỏi ánh xạ demo: MSSV và CTĐT của thành viên đã đồng ý, mã lớp; mã lớp cố vấn cho giảng viên 102.
- Ghi gộp vào `.local\backend.json`. Kiểm tra `.local` có nằm trong `.gitignore`.
- In bản tóm tắt đã che (key chỉ hiện 4 ký tự cuối, MSSV bị che).
- `Start-LocalBackend.ps1` đọc cấu hình này.

**Test** (dùng `MockRestServiceServer` sẵn có trong spring-test, không thêm WireMock):
- Có header key; không có key thì Portal ở trạng thái DISABLED.
- Timeout, lỗi 500, `ok=false`, JSON sai, chuỗi số rỗng.
- Cache hit và cache hết hạn.
- **Test bắt log:** key và body không bao giờ xuất hiện trong log.

**Khi P0 xong**, DỪNG MỘT LẦN và nhờ owner chạy `Set-PortalConfig.ps1`. Trong lúc chờ, tiếp tục làm P1–P8 với client giả lập và test. Khi owner chạy xong, chạy thật trên emulator.

## 4. Đợt P — chức năng cầu nối LMS và Portal

Mọi endpoint mới nằm dưới `/api/v1/dev/students/{userId}/portal/…` hoặc `/api/v1/dev/teachers/{teacherId}/portal/…`, có PathIdentity và test 401, 403, 404. Sinh viên chưa được ánh xạ thì trả 404 kèm `{"code":"PORTAL_NOT_LINKED"}`.

### P1. Bảng điểm và GPA của tôi (sinh viên)

**Nguồn:** `LayBangDiemSinhVien`.

**Hiển thị:**
- Bảng điểm theo năm học và học kỳ: tên học phần, tín chỉ, điểm hệ 10, hệ 4, điểm chữ, Đạt/Chưa đạt.
- GPA học kỳ và tích lũy (hệ 4 và hệ 10).
- Tín chỉ tích lũy và xếp loại.
- Biểu đồ đường GPA theo học kỳ (fl_chart).
- Bộ lọc "Học phần chưa đạt".

**Dashboard sinh viên** thêm thẻ đầu tiên: **"GPA tích lũy · số tín chỉ · còn thiếu X tín chỉ"**. Đây là thứ đầu tiên người xem thấy, chứng minh ứng dụng đã tích hợp Portal.

**Lưu ý:** dùng GPA do Portal tính (`TB_TL_HK_4`) làm số chính thức. Nếu ứng dụng tự tính lại (ΣTC×điểm4 / ΣTC, chỉ học phần có `IsGather` và không có `NotComputeAverageScore`), phải có test đối chiếu với số của Portal và ghi chênh lệch nếu có.

### P2. Tiến độ chương trình đào tạo (sinh viên) — chức năng khác biệt

**Nguồn:** `LayDanhSachHocPhanTheoCTDT(StudyProgramID)` kết hợp bảng điểm P1 và LMS.

**Trạng thái mỗi học phần** trong CTĐT, nhóm theo HocKy:
- Đã đạt.
- Chưa đạt (học lại).
- **Đang học trên LMS**: khóa Moodle được ánh xạ tới MaHP qua `courseMap` hoặc `lms.course.idnumber`.
- Chưa học.

**Tổng hợp:**
- Tín chỉ bắt buộc đã đạt / tổng.
- Tín chỉ tự chọn đã đạt. Nếu `groupSelection` rỗng hoặc chưa hiểu cấu trúc thì ghi rõ "chưa có dữ liệu nhóm tự chọn", **không đoán**.
- Phần trăm hoàn thành CTĐT.

**Điều kiện tiên quyết:**
- Đọc `HPTienQuyet` / `HPHocTruoc`, hỗ trợ cả danh sách nhiều mã ngăn cách bằng dấu phẩy hoặc chấm phẩy.
- Màn "Học kỳ tới bạn đủ điều kiện đăng ký" liệt kê các học phần chưa học mà điều kiện đã thỏa. Học phần bị chặn thì ghi rõ đang thiếu học phần nào.

### P3. Mô phỏng GPA và mục tiêu xếp loại (sinh viên) — màn hình cầu nối quan trọng nhất

**Ngưỡng xếp loại** cấu hình trong `gradeBands`. Mặc định theo Thông tư 08/2021/TT-BGDĐT, hệ 4:
- Xuất sắc ≥ 3,6
- Giỏi ≥ 3,2
- Khá ≥ 2,5
- Trung bình ≥ 2,0

Màn hình ghi chú "đối chiếu với quy chế đào tạo của Trường ĐH Đà Lạt".

**Engine** (hàm thuần):
- Đầu vào: tín chỉ đã tích lũy, GPA tích lũy, tín chỉ còn lại lấy từ P2.
- Tính GPA trung bình cần đạt trên số tín chỉ còn lại để đạt mỗi mức xếp loại.
- Trạng thái: Đã chắc / Khả thi / Không còn khả thi.

**Cầu nối từ LMS:**
- Với các học phần **đang học trên LMS**: lấy dự báo % từ engine N1 (V2), quy sang hệ 10, rồi sang điểm chữ và hệ 4.
- **Bảng quy đổi** suy ra từ chính bảng điểm của sinh viên: khoảng DiemTK_10 nhỏ nhất và lớn nhất ứng với mỗi DiemTK_Chu và DiemTK_4.
- Nếu dữ liệu không đủ thì dùng bảng mặc định trong cấu hình, kèm nhãn "giả định".

**UI:**
- Câu kết luận bằng số thật, ví dụ: "Nếu giữ phong độ hiện tại ở 2 môn đang học trên LMS, GPA tích lũy dự kiến 2,87; để đạt Giỏi cần trung bình 3,41 ở 28 tín chỉ còn lại."
- Mỗi học phần đang học hoặc chưa học có bộ chọn điểm chữ "nếu tôi được…", kết quả cập nhật ngay.

**Test:**
- Biên của từng ngưỡng xếp loại.
- Không còn tín chỉ nào.
- Bảng quy đổi suy ra từ fixture.
- Học phần không có ánh xạ LMS.

### P4. Điểm rèn luyện của tôi (sinh viên)

- Gọi `LayBangDiemRenLuyenTheoLop` cho từng (YearStudy, TermId) kể từ năm nhập học. Lấy danh sách năm học từ P1.
- Lọc ra **chỉ dòng của mình**.
- Hiển thị điểm tự đánh giá, lớp, khoa và điểm cuối, kèm biểu đồ theo học kỳ.
- Gọi tuần tự, có cache, tối đa 10 học kỳ.

### P5. Quyết định học vụ của tôi (sinh viên)

- Nguồn `LayDanhSachQuyetDinh(MSSV)`, chỉ của chính sinh viên.
- Danh sách quyết định gồm loại, ngày và năm học.
- Nếu có quyết định thuộc nhóm "Cảnh báo học vụ" thì hiện thẻ cảnh báo, kèm liên kết sang P3 để xem cần đạt bao nhiêu.

### P6. Lớp cố vấn học tập (giảng viên) — chức năng khác biệt

Chỉ áp dụng cho các mã lớp cấu hình trong `advisors[teacherId]`; mã lớp khác trả 404.

**Tổng quan lớp:**
- Sĩ số (`IsInClass`).
- Phân bố xếp loại (`Ranks`) và histogram ĐTB hệ 4.
- So sánh với học kỳ trước: GPA trung bình của lớp tăng hay giảm.

**Danh sách cần quan tâm:**
- ĐTB hệ 4 dưới 2,0, hoặc xếp loại Yếu/Kém.
- Điểm rèn luyện dưới ngưỡng cấu hình (mặc định 50).
- Không có điểm (null) trong học kỳ.

**Chi tiết một sinh viên** chỉ hiện các trường phục vụ cố vấn. Nếu `StudentID` khớp với `lms.user.idnumber` thì hiện thêm tín hiệu LMS (N9: tiến độ, việc quá hạn, điểm theo dõi): đây là **cầu nối dành cho giảng viên**. Nếu không khớp thì ghi "Chưa có dữ liệu LMS cho sinh viên này".

**Chế độ ẩn danh:** BẬT theo mặc định.

**Xuất CSV:** dùng lại N8. Chỉ cho phép khi đã tắt chế độ ẩn danh, và trước khi xuất phải xác nhận.

### P7. Nguồn dữ liệu và quyền riêng tư (cả hai vai trò)

Màn hình gồm:
- Trạng thái từng nguồn: LMS (CSDL cục bộ) và Portal (UP/DOWN, lần cập nhật gần nhất).
- **Danh sách trường ứng dụng dùng và KHÔNG dùng**, kèm lý do. Nêu rõ việc không tích hợp miễn giảm học phí.
- Thời gian giữ cache.

Hội đồng thường hỏi về bảo mật, nên màn hình này giúp trả lời trực quan.

### P8. Hoàn thiện tích hợp

- Mọi màn P có trạng thái loading, lỗi Portal (kèm nút thử lại) và chưa liên kết.
- Cache ở client: nếu N11 đã làm thì dùng chung cơ chế, xóa khi đổi vai trò.
- Thêm vào E2 (đo hiệu năng) hai số đo: thời gian gọi Portal khi chưa có cache và khi có cache.

## 5. Sơ đồ và so sánh (theo yêu cầu của giảng viên: chi tiết, tách riêng, có lợi ích)

Tạo thư mục `docs/diagrams/`. **Mỗi sơ đồ một file Mermaid `.mmd`, mỗi sơ đồ một ý**, khớp với code thật (tên controller, service, bảng, cổng). Không gộp nhiều sơ đồ vào một file.

| File | Nội dung |
| --- | --- |
| `01-context.mmd` | Sinh viên, giảng viên, Ứng dụng, Moodle LMS, Portal đào tạo (API thầy Hiếu). Ghi dữ liệu nào đi từ đâu |
| `02-components.mmd` | Nhóm màn hình Flutter → controller → service → repository / PortalClient → schema lms/app/derived và Portal |
| `03-deployment.mmd` | Máy local: Postgres 127.0.0.1:55432, backend 8081, emulator qua adb reverse, Internet → Portal |
| `04-seq-auth.mmd` | demo-login → JWT → PathIdentity → 200, 403, 401 (gồm cả lỗi ERROR dispatch đã sửa) |
| `05-seq-gpa-simulation.mmd` | Sinh viên mở P3: app → backend → cache/Portal → engine N1 → engine P3 → app |
| `06-dataflow-bridge.mmd` | Dữ liệu LMS + Portal → các engine (N1, N9, P2, P3, P6) → màn hình |
| `07-erd-app.mmd` | Schema `app` gồm cả các bảng V2, có khóa ngoại |
| `08-usecase-student.mmd`, `09-usecase-teacher.mmd` | Use case tách riêng cho từng vai trò |
| `10-activity-study-plan.mmd` | Thuật toán N6 |
| `11-activity-forecast.mmd` | Thuật toán N1 và P3 |

Nếu có `mmdc` thì render từng file ra SVG trong `docs/diagrams/out/`. Nếu không có thì chỉ để file `.mmd`, phiên cloud sẽ render.

Viết `docs/COMPARISON_FACTS.md`: với **mỗi chức năng của ứng dụng** (cũ, V2 và V3), ghi một dòng gồm nguồn dữ liệu (LMS / Portal / app), màn hình, endpoint, test và lợi ích cụ thể cho người dùng.
- **Không tự khẳng định "Moodle hay Portal không có chức năng X"**. Phiên cloud sẽ kiểm chứng rồi dựng bảng so sánh "Moodle web / Moodle App / Portal ĐT / Ứng dụng nhóm" cho báo cáo và slide.
- Viết `docs/FEATURES_V3.md` theo cùng mẫu với `FEATURES_V2.md`.

## 6. Báo cáo

- **HANDOFF:** dùng mẫu V2 cho P0–P8 và Sơ đồ. Riêng dòng Runtime ghi thêm: "Portal: thật / giả lập, số bản ghi".
- **TASK_BOARD:** thêm V3-P0 … V3-P8 và V3-DIAG.
- **Ảnh chụp:** `D:\DLU-LMS\Artifacts\v3\screens\pX-YY-….png`, ở chế độ ẩn danh (theo quy tắc 2.8).
- **Chỉ dừng hỏi owner khi:** cần chạy `Set-PortalConfig.ps1`, cần mật khẩu postgres, hoặc cần quyền admin.
