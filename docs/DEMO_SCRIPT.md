## Bản 15 phút (13/11) — báo cáo hội đồng đợt 2, 14:00 13/11/2026

DB demo đã dời theo mốc 13/11 (`.\tools\Set-DemoDate.ps1 -TargetDate 2026-11-13`, shift_days = −7, hạn muộn nhất 18/11 20:47).
Buổi 15 phút (mốc tính từ đầu buổi): slide 0:00–8:05, demo 8:05–13:20, kết luận + dự phòng đến 15:00. Chỉ dùng bước 1–7 (SV) và 12–15, 17 (GV)
của kịch bản đầy đủ bên dưới; bỏ 8–11 và 16.

Đi thử 12/11/2026 trên emulator (11:30–11:52, Portal UP, prewarm 67/67), không lỗi. Cột "Thao tác đo" là thời gian bấm + chờ màn,
đo bằng công cụ tự động (mỗi lần dò giao diện thêm khoảng 1,5 s, nên số đo hơi cao hơn tay người bấm); bước 1 và 12 vào bằng
**Chế độ demo** vì mật khẩu demo chưa đặt lúc đó — đăng nhập thật cộng khoảng 15 s gõ mã số + mật khẩu. Cột "Giây" = kế hoạch khi
nói (thao tác + câu thuyết minh).

| # | Việc (xem chi tiết ở bảng đầy đủ) | Thao tác đo 12/11 | Giây | Mốc phải xong |
| --- | --- | ---: | ---: | ---: |
| 1 | Đăng nhập SV `2312005` | 15 s (+15 s gõ) | 35 | 8:40 |
| 2 | Thẻ GPA tích lũy | — (chỉ nhìn) | 10 | 8:50 |
| 3 | Thẻ GPA › tab Chương trình | 16 s | 20 | 9:10 |
| 4 | Tab Mô phỏng GPA | 8 s | 15 | 9:25 |
| 5 | Thẻ Tình trạng học tập | 15 s | 20 | 9:45 |
| 6 | Thẻ **Hôm nay: N việc** › Kế hoạch tuần (12/11 đo được: "Hôm nay: 1 việc · 45 phút") | 13 s | 20 | 10:05 |
| 7 | Mobile Application Development › Flashcards › ôn 1 thẻ › **Được** (12/11: 4 thẻ đến hạn) | 54 s | 45 | **10:50** — SV xong |
| 12 | Đăng xuất › đăng nhập `teacher02` (nói ngắn) | 23 s (+15 s gõ) | 40 | 11:30 |
| 13 | Lớp cố vấn ITK47A › **Ẩn danh** › **Cần quan tâm** (21 SV) | 15 s | 25 | 11:55 |
| 14 | Một SV trong danh sách cần quan tâm | 5 s | 15 | 12:10 |
| 15 | Hỗ trợ học tập số › Phân tích › cuộn tới **Dự báo qua môn** | ≈ 30 s | 35 | 12:45 |
| 17 | Xem SV cần theo dõi › Trần Minh Bảo › **Nhắc riêng** › mẫu "Lâu không truy cập" › **Hủy** (KHÔNG Gửi) | ≈ 35 s | 35 | **13:20** — GV xong |

Tổng demo ≈ 315 giây (SV 165 + GV 150). Kết luận 15 giây (câu kết ở cuối bảng đầy đủ) → 13:35; 1 phút 25 giây dự phòng.

**Trễ thì bỏ (theo thứ tự):**
1. Đến bước 3 sau 9:00 → bỏ bước 4 (Mô phỏng GPA), nói một câu khi đang ở tab Chương trình.
2. Đến bước 6 sau 10:00 → bỏ bước 5 (Tình trạng học tập).
3. 10:50 mà SV chưa xong → dừng bước 7 ngay sau khi lật thẻ (không cần bấm nút), chuyển sang GV.
4. Đến bước 13 sau 11:45 → bỏ bước 14 (chi tiết SV cố vấn).
5. Đến bước 15 sau 12:30 → bỏ bước 15, đi thẳng bước 17.
6. 13:20 mà GV chưa xong → nói câu kết luôn; bước 17 chỉ mở hộp nhắc rồi **Hủy**.
Portal DOWN → bỏ 2–4 và 13–14 (xem Nhánh dự phòng); lỗi app nặng → chiếu `DLU-LMS-Group_demo-quay-man-hinh_2026-11-11.mp4`.

Sau buổi 13/11, trước buổi 20/11: `.\tools\Set-DemoDate.ps1 -TargetDate 2026-11-20` (trả DB demo về mốc 20/11).

---

# Kịch bản demo 10 phút — bảo vệ 20/11/2026

Dữ liệu: DB `lms_mobile_group_demo` (bản sao LMS đã dời ngày theo mốc 20/11/2026) + Portal Online DLU Proxy (**dữ liệu mô
phỏng**, không phải dữ liệu thật của Trường). Sinh viên demo: userId 205 "Hoang Giang"; giảng viên demo: userId 102 "Tran Thanh Hoa".

Chuẩn bị (trước giờ, 5 phút): `.\tools\Start-Demo.ps1` → thấy **Tóm tắt demo** với `Portal : UP`. Mở app → màn
**Đăng nhập**. Mật khẩu demo do owner đặt một lần bằng `.\tools\Set-DemoPasswords.ps1` (không ghi trong tài liệu).
Điện thoại thật: `.\tools\Start-Demo.ps1 -PhysicalDevice` (xem `LOCAL_RUNBOOK.md`).

Quy ước: **Bấm** = thao tác; **Mã** = chức năng; **Nói** = một câu thuyết minh. Đã đi thử toàn bộ trên emulator ngày 10/11/2026
(ảnh `D:\DLU-LMS\Artifacts\final\screens\demo-*.png`).

## A. Sinh viên 205 (khoảng 6 phút)

| # | Bấm | Mã | Nói | Giây |
| --- | --- | --- | --- | ---: |
| 1 | Màn **Đăng nhập**: gõ MSSV `2312005` + mật khẩu demo (owner đặt bằng `Set-DemoPasswords.ps1`) › **Đăng nhập** | LOGIN | "Đăng nhập bằng mã số sinh viên như LMS của trường; máy chủ quyết định vai trò, sai 5 lần thì khóa tạm 15 phút." | 35 |
| 2 | Trang chủ: nhìn thẻ **GPA tích lũy** (đầu trang) | P1 | "GPA và tín chỉ lấy từ Portal Đào tạo, cùng một màn với dữ liệu học trên LMS." | 10 |
| 3 | Bấm thẻ GPA › tab **Chương trình** | P2 | "Tiến độ chương trình đào tạo: tín chỉ bắt buộc đã đạt, học phần đủ điều kiện đăng ký." | 20 |
| 4 | Tab **Mô phỏng GPA** | P3 + N1 | "GPA dự kiến dùng điểm hiện tại trên LMS của các môn đang học; app cho biết cần bao nhiêu để đạt Giỏi." | 15 |
| 5 | Quay lại › thẻ **Tình trạng học tập** (Đỏ/Vàng/Xanh) | N9 | "Sinh viên thấy đúng điểm theo dõi giảng viên thấy, kèm lý do và việc cần làm để lên Xanh." | 20 |
| 6 | Quay lại › thẻ **Hôm nay: N việc** › Kế hoạch tuần | N6 | "Hạn nộp thật được xếp thành lịch từng ngày vừa quỹ thời gian; bài dài tách hai phần; quá tải thì cảnh báo." | 20 |
| 7 | Tab **Khóa học** › **Mobile Application Development** › **Flashcards** › **Bắt đầu ôn tập** › chạm lật thẻ › **Được** (nút ghi "không có thẻ đến hạn" thì bấm **Thêm thẻ**, tạo 1 thẻ — thẻ mới đến hạn ngay) | N5 | "Ôn tập ngắt quãng SM-2: mỗi nút ghi rõ bao lâu nữa gặp lại thẻ." | 45 |
| 8 | Quay lại khóa › tab **Điểm** › **Mô phỏng điểm** | N1 | "Thử 'nếu bài X được Y điểm' và xem còn cần bao nhiêu ở các bài chưa chấm để qua môn." | 30 |
| 9 | Trang chủ › biểu tượng **Lịch** › **Tuần** | N12 | "Hạn nộp, kế hoạch và buổi học trên một lịch; xuất .ics sang Google Calendar." | 30 |
| 10 | Biểu tượng **chuông** (Cài đặt nhắc) | N7 | "Nhắc trước hạn nộp và nhắc ôn hằng ngày ngay cả khi app đã đóng; quyền thông báo chỉ xin khi người dùng bật." | 20 |
| 11 | Biểu tượng **kính lúp** › gõ `ho tro hoc` (không dấu) | N13 | "Tìm không dấu, kết quả mở thẳng đúng khóa." | 20 |

## B. Giảng viên 102 (khoảng 4 phút)

| # | Bấm | Mã | Nói | Giây |
| --- | --- | --- | --- | ---: |
| 12 | Trang chủ SV › nút **Đăng xuất** (góc trái) › đăng nhập `teacher02` + mật khẩu demo | LOGIN | "Đăng xuất xóa token, dữ liệu lưu ngoại tuyến và lịch nhắc của tài khoản trước; vai trò GV do máy chủ xác định." | 55 |
| 13 | Trang chủ GV: thẻ **Lớp cố vấn ITK47A** › bật **Ẩn danh** › **Cần quan tâm** | P6 | "Kết quả cả lớp cố vấn từ Portal; bật ẩn danh khi trình chiếu, tên thành 'SV 01'." | 25 |
| 14 | Một SV trong danh sách cần quan tâm (mở ngay: Start-Demo đã làm nóng cache Portal, bảng SẴN SÀNG báo `prewarm N/N`) | P6 + N9 | "Nếu SV cũng học khóa của thầy cô trên LMS, app hiện thêm tín hiệu học tập ở đó." | 15 |
| 15 | Quay lại › tab **Khóa học** › **Hỗ trợ học tập số** › tab **Phân tích** › cuộn xuống phần **Dự báo qua môn** | N4 | "Engine mô phỏng điểm chạy cho cả lớp: ai đã chắc qua, ai cần cố gắng, ai không còn khả thi." | 35 |
| 16 | Cuộn tiếp tới **Phân tích bài kiểm tra** (MVP3 - Quiz 5.1: "Quá khó", "Nhiều sinh viên bỏ") | N16 | "Câu nào quá khó, nhiều SV bỏ, hay làm quá nhanh — để chỉnh đề." | 20 |
| 17 | Quay lại khóa › **Xem sinh viên cần theo dõi** › Trần Minh Bảo › **Nhắc riêng** (mẫu "Lâu không truy cập") › **Hủy** (KHÔNG bấm Gửi) | N8 | "Mẫu nhắc dựng từ lý do thật như số ngày chưa vào khóa; ngoài danh sách lớp thì server từ chối." | 40 |


**Bấm giờ (POLISH-5, 11/11/2026):** tổng ≈ 455 giây (≈ 7 phút 35 giây) + 15 giây kết luận. Đã tập trọn 17 bước trên emulator (DB demo, Portal UP, cache đã làm nóng). Cột "Giây" = thao tác đo trên emulator (1,5 s mỗi lần bấm, gồm thời gian tải màn) + thời gian nói câu thuyết minh (3 tiếng/giây) + 15 giây gõ mã số và mật khẩu ở bước 1 và 12; bước 15–16 tính theo cuộn tay (~10 s) thay vì công cụ dò chữ tự động.

Kết (15 giây): "Ứng dụng không thay Moodle; nó gom dữ liệu LMS và Portal, giải thích, và chuyển thành việc làm cụ thể trên điện thoại."

## Nhánh dự phòng

- **Trước giờ:** đợi bảng **SẴN SÀNG** của Start-Demo báo `prewarm 67/67` (khoảng 1–2 phút sau khi backend UP). Cache Portal khi demo
  giữ 6 giờ. Chuyển giao diện sáng/tối: menu Tài khoản (góc trái trang chủ).

- **Portal DOWN** (Tóm tắt ghi `Portal : DOWN` hoặc thẻ GPA không hiện): bỏ bước 2–4 và 13–14. Nói: "Phần Portal dùng API
  mô phỏng của Trường đang không phản hồi; phần học tập trên LMS vẫn chạy độc lập." Thay bằng bước 5 và 15 dài hơn.
- **Emulator treo/màn đen:** đóng cửa sổ "DLU Demo - Emulator", chạy lại `.\tools\Start-Demo.ps1` (bước đã chạy được dùng lại).
  Trong lúc chờ (~1 phút), chiếu video `D:\DLU-LMS\Artifacts\final\video\` của đoạn đang nói.
- **App báo không kết nối máy chủ:** `adb reverse tcp:8081 tcp:8081` rồi kéo để làm mới; nếu backend tắt, banner "Đang ngoại tuyến"
  vẫn cho xem trang chủ, việc, kế hoạch (N11) — có thể nói luôn về chức năng này.
- **Mất token (401):** Đăng xuất rồi đăng nhập lại.
- **Quên/khóa mật khẩu demo:** chờ hết thời gian khóa (15 phút) hoặc dùng nút nhỏ **Chế độ demo** dưới form (đăng nhập
  thử nghiệm, chỉ có ở bản build local) để vào thẳng vai trò.
- **Ngày demo khác 20/11:** dữ liệu đã dời theo 20/11; trước ngày đó một số mốc hiện "sau hôm nay N ngày". Đó là cách app hiển thị
  trung thực mốc ở tương lai, không phải lỗi.

## 8 câu hội đồng dễ hỏi

1. **Khác Moodle ở đâu?** Ứng dụng không thay Moodle: nộp bài, làm quiz, chấm điểm vẫn ở LMS (mọi việc có nút "Mở trên LMS").
   Giá trị thêm là gom LMS + Portal vào một màn trên điện thoại, giải thích con số (điểm còn cần, lý do mức Đỏ) và biến thành hành
   động (kế hoạch tuần, nhắc, ôn thẻ SM-2, nhắc riêng của GV). Nhóm không khẳng định Moodle thiếu chức năng nào khi chưa đối chiếu
   đúng phiên bản Moodle của Trường.
2. **Dữ liệu lấy từ đâu, có thật không?** LMS: bản sao CSDL Moodle được cung cấp cho đồ án, đọc qua role chỉ đọc; bản demo được
   dời ngày theo 20/11 để hạn nộp nằm ở tương lai. Portal: API Portal Online DLU Proxy trả **dữ liệu mô phỏng**. Ứng dụng không ghi
   vào Moodle, chỉ ghi dữ liệu riêng (kế hoạch, thẻ, phiên học, nhắc) vào schema `app`.
3. **Bảo mật đăng nhập và MSSV?** Đăng nhập bằng MSSV/tên tài khoản + mật khẩu; máy chủ so BCrypt, trả một thông báo
   chung khi sai, khóa tạm sau 5 lần sai trong 15 phút, không ghi login/mật khẩu vào log; app chỉ nhớ mã số, không nhớ mật khẩu.
   Bản thật bật `MoodleTokenProvider` (đăng nhập bằng chính tài khoản LMS của Trường, như app Moodle) khi được Trường cho phép.
   Token JWT ký HMAC-256, hết hạn tối đa 24 giờ (mặc định 1 giờ). Mọi đường dẫn có userId được so
   với userId trong token, sai → 403 (`PathIdentityAuthorizationManager`); dữ liệu ngoài khóa/roster → 404. Người dùng không nhập
   MSSV để xem dữ liệu người khác: Portal được gọi theo tài khoản đã đăng nhập, vì API Portal chỉ xác thực bằng key. Key Portal chỉ
   ở backend, không vào APK.
4. **SM-2 hoạt động thế nào?** Bốn nút Quên/Khó/Được/Dễ (q = 1/3/4/5). Quên → gặp lại sau 1 ngày; nhớ → 1 ngày, 6 ngày, rồi nhân
   với hệ số dễ EF (bắt đầu 2,5, tối thiểu 1,3, thay đổi theo q). Trả "Được" liên tục: 1 → 6 → 15 → 38 → 95 ngày (`Sm2.next`).
5. **GPA dự kiến tính ra sao?** GPA dự kiến = (G × C + Σ TC × điểm hệ 4 dự kiến) / (C + Σ TC). G, C là GPA và tín chỉ chính thức từ
   Portal; điểm dự kiến của môn đang học lấy từ mô phỏng điểm LMS (%) → hệ 10 → điểm chữ → hệ 4 theo bảng quy đổi suy từ chính bảng
   điểm của SV. Điểm cần cho một xếp loại: need = (band × (C + R) − G × C) / R. Đây là dự kiến, không phải điểm chính thức.
6. **Vì sao không dùng API miễn giảm học phí?** Dữ liệu miễn giảm cho biết đối tượng chính sách hoặc dân tộc — dữ liệu cá nhân nhạy
   cảm theo Nghị định 13/2023/NĐ-CP — và không cần cho học tập, nên ứng dụng không gọi endpoint đó (tối thiểu hóa dữ liệu).
7. **Đã kiểm thử thế nào?** Backend JUnit 290 test (1 test schema tắt có chủ đích), Flutter 333 test kể cả cỡ chữ 1.3, màn 320–390 dp,
   chế độ tối; test bảo mật 403/404, injection trong tìm kiếm. Mỗi chức năng chạy thật trên emulator với DB demo, có ảnh chụp; đo
   hiệu năng 12 endpoint × 200 lần: p95 3–29 ms, 0 lỗi. Số liệu cuối: `docs/RELEASE_NOTES.md`.
8. **Triển khai thật cần gì?** (a) bật `MoodleTokenProvider` trỏ vào LMS của Trường (cần văn bản cho phép), MSSV lấy từ tài
   khoản đã xác thực; (b) kết nối chỉ đọc tới CSDL hoặc API
   Moodle thật thay bản sao; (c) key Portal thật, bật ẩn danh mặc định; (d) chạy backend trên máy chủ của Trường với HTTPS, đổi mật
   khẩu role ứng dụng (`tools\Rotate-AppRolePassword.ps1`); (e) ký APK bản phát hành; (f) đối chiếu ngưỡng xếp loại với quy chế
   đào tạo của Trường ĐH Đà Lạt.

## Câu hỏi bổ sung (POLISH-6, đã đối chiếu với code)

9. **Đăng nhập bằng MSSV an toàn ra sao?** Máy chủ so mật khẩu bằng BCrypt cost 12 (`LocalCredentialProvider`); sai 5 lần trong
   15 phút cho cùng mã số và địa chỉ thì khóa tạm (429 kèm thời gian chờ, `LoginAttemptLimiter`); sai mật khẩu hay mã số không tồn tại
   đều nhận một thông báo chung "Mã số hoặc mật khẩu không đúng" và cùng thời gian xử lý. App không lưu mật khẩu; "Ghi nhớ mã số" chỉ
   lưu mã số; token JWT chỉ giữ trong bộ nhớ, đăng xuất là xóa. Vai trò sinh viên/giảng viên do máy chủ quyết định, app không gửi vai trò.
   Log chỉ ghi kết quả, userId và độ dài mã số.
10. **Vì sao chưa đăng nhập bằng tài khoản LMS thật?** `MoodleTokenProvider` đã viết sẵn theo đúng cách ứng dụng Moodle chính thức
    đăng nhập (`login/token.php` rồi `core_webservice_get_site_info`) và đã kiểm thử bằng máy chủ giả lập (3 test). Gọi thật vào
    lms.dlu.edu.vn cần văn bản cho phép của Trường, nên provider đang TẮT; bật thì chỉ cần cấu hình địa chỉ https.
11. **Vì sao GitHub chỉ có vài commit ảnh chụp?** Lịch sử phát triển ban đầu có bảng mật khẩu demo của bản trước (nằm trong bản mã nguồn nhóm
    nhận). Nhóm không đưa lịch sử đó lên repo công khai mà đưa ảnh chụp sạch của mã nguồn bản bảo vệ (bản 20/11 và bản r2 sau khi hoàn thiện) (đã quét bí mật và file cấm
    trước khi đẩy). Lịch sử đầy đủ nằm trên máy của nhóm: hơn 40 commit cục bộ từ 09/11/2026 (khi nhận bản nguồn), xem bằng `git log`.
12. **Dữ liệu Portal có lưu xuống đĩa không?** Không. Phản hồi Portal chỉ nằm trong cache bộ nhớ của backend: 6 giờ khi chạy demo
    (dữ liệu mô phỏng không đổi, có làm nóng sẵn lớp cố vấn), 10 phút khi triển khai thật; app giữ thêm 5 phút trong bộ nhớ và xóa khi
    đăng xuất. Không ghi vào CSDL, không ghi file; log chỉ có endpoint, mã trạng thái, thời gian, số bản ghi.
13. **Mất mạng thì sao?** Hai trường hợp:
    - *Máy demo mất internet:* backend, CSDL và emulator đều chạy trên máy nên toàn bộ phần LMS (trang chủ, khóa học, kế hoạch, ôn thẻ,
      dự báo, nhắc riêng…) vẫn chạy. Chỉ phần Portal bị ảnh hưởng: lớp cố vấn vẫn mở được nếu cache đã làm nóng (6 giờ); thẻ GPA và
      Học vụ của sinh viên báo "Portal đào tạo đang không phản hồi". Xử lý: bỏ bước 2–4 (xem "Nhánh dự phòng"), nói rõ phần LMS độc lập.
    - *Điện thoại mất kết nối tới backend:* app hiện banner "Đang ngoại tuyến · dữ liệu lúc …" và vẫn cho xem trang chủ, việc cần làm,
      khóa học, kế hoạch, thẻ đến hạn đã tải (N11); thao tác ghi bị khóa. Xử lý: chạy lại `adb reverse tcp:8081 tcp:8081` rồi kéo để làm mới.
