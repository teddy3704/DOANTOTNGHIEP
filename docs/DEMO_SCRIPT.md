# Kịch bản demo 10 phút — bảo vệ 20/11/2026

Dữ liệu: DB `lms_mobile_group_demo` (bản sao LMS đã dời ngày theo mốc 20/11/2026) + Portal Online DLU Proxy (**dữ liệu mô
phỏng**, không phải dữ liệu thật của Trường). Sinh viên demo: userId 205 "Hoang Giang"; giảng viên demo: userId 102 "Tran Thanh Hoa".

Chuẩn bị (trước giờ, 5 phút): `.\tools\Start-Demo.ps1` → thấy **Tóm tắt demo** với `Portal : UP`. Mở app → màn
**Đăng nhập**. Mật khẩu demo do owner đặt một lần bằng `.\tools\Set-DemoPasswords.ps1` (không ghi trong tài liệu).
Điện thoại thật: `.\tools\Start-Demo.ps1 -PhysicalDevice` (xem `LOCAL_RUNBOOK.md`).

Quy ước: **Bấm** = thao tác; **Mã** = chức năng; **Nói** = một câu thuyết minh. Đã đi thử toàn bộ trên emulator ngày 10/11/2026
(ảnh `D:\DLU-LMS\Artifacts\final\screens\demo-*.png`).

## A. Sinh viên 205 (khoảng 6 phút)

| # | Bấm | Mã | Nói |
| --- | --- | --- | --- |
| 1 | Màn **Đăng nhập**: gõ MSSV `2312005` + mật khẩu demo (owner đặt bằng `Set-DemoPasswords.ps1`) › **Đăng nhập** | LOGIN | "Đăng nhập bằng mã số sinh viên như LMS của trường; máy chủ quyết định vai trò, sai 5 lần thì khóa tạm 15 phút." |
| 2 | Trang chủ: nhìn thẻ **GPA tích lũy** (đầu trang) | P1 | "GPA và tín chỉ lấy từ Portal Đào tạo, cùng một màn với dữ liệu học trên LMS." |
| 3 | Bấm thẻ GPA › tab **Chương trình** | P2 | "Tiến độ chương trình đào tạo: tín chỉ bắt buộc đã đạt, học phần đủ điều kiện đăng ký." |
| 4 | Tab **Mô phỏng GPA** | P3 + N1 | "GPA dự kiến dùng điểm hiện tại trên LMS của các môn đang học; app cho biết cần bao nhiêu để đạt Giỏi." |
| 5 | Quay lại › thẻ **Tình trạng học tập** (Đỏ/Vàng/Xanh) | N9 | "Sinh viên thấy đúng điểm theo dõi giảng viên thấy, kèm lý do và việc cần làm để lên Xanh." |
| 6 | Quay lại › thẻ **Hôm nay: N việc** › Kế hoạch tuần | N6 | "Hạn nộp thật được xếp thành lịch từng ngày vừa quỹ thời gian; bài dài tách hai phần; quá tải thì cảnh báo." |
| 7 | Tab **Khóa học** › **Mobile Application Development** › **Flashcards** › **Bắt đầu ôn tập** › chạm lật thẻ › **Được** (nút ghi "không có thẻ đến hạn" thì bấm **Thêm thẻ**, tạo 1 thẻ — thẻ mới đến hạn ngay) | N5 | "Ôn tập ngắt quãng SM-2: mỗi nút ghi rõ bao lâu nữa gặp lại thẻ." |
| 8 | Quay lại khóa › tab **Điểm** › **Mô phỏng điểm** | N1 | "Thử 'nếu bài X được Y điểm' và xem còn cần bao nhiêu ở các bài chưa chấm để qua môn." |
| 9 | Trang chủ › biểu tượng **Lịch** › **Tuần** | N12 | "Hạn nộp, kế hoạch và buổi học trên một lịch; xuất .ics sang Google Calendar." |
| 10 | Biểu tượng **chuông** (Cài đặt nhắc) | N7 | "Nhắc trước hạn nộp và nhắc ôn hằng ngày ngay cả khi app đã đóng; quyền thông báo chỉ xin khi người dùng bật." |
| 11 | Biểu tượng **kính lúp** › gõ `ho tro hoc` (không dấu) | N13 | "Tìm không dấu, kết quả mở thẳng đúng khóa." |

## B. Giảng viên 102 (khoảng 4 phút)

| # | Bấm | Mã | Nói |
| --- | --- | --- | --- |
| 12 | Trang chủ SV › nút **Đăng xuất** (góc trái) › đăng nhập `teacher02` + mật khẩu demo | LOGIN | "Đăng xuất xóa token, dữ liệu lưu ngoại tuyến và lịch nhắc của tài khoản trước; vai trò GV do máy chủ xác định." |
| 13 | Trang chủ GV: thẻ **Lớp cố vấn ITK47A** › bật **Ẩn danh** › **Cần quan tâm** | P6 | "Kết quả cả lớp cố vấn từ Portal; bật ẩn danh khi trình chiếu, tên thành 'SV 01'." |
| 14 | Một SV trong danh sách cần quan tâm (lần mở đầu có thể chờ 20–30 s vì server tải lịch sử nhiều học kỳ từ Portal; nói câu thuyết minh trong lúc chờ) | P6 + N9 | "Nếu SV cũng học khóa của thầy cô trên LMS, app hiện thêm tín hiệu học tập ở đó." |
| 15 | Quay lại › tab **Khóa học** › **Hỗ trợ học tập số** › tab **Phân tích** › cuộn xuống phần **Dự báo qua môn** | N4 | "Engine mô phỏng điểm chạy cho cả lớp: ai đã chắc qua, ai cần cố gắng, ai không còn khả thi." |
| 16 | Cuộn tiếp tới **Phân tích bài kiểm tra** (MVP3 - Quiz 5.1: "Quá khó", "Nhiều sinh viên bỏ") | N16 | "Câu nào quá khó, nhiều SV bỏ, hay làm quá nhanh — để chỉnh đề." |
| 17 | Tab **Sinh viên** › một SV › **Nhắc riêng** › chọn mẫu › **Hủy** (KHÔNG bấm Gửi) | N8 | "Mẫu nhắc dựng từ lý do thật như số ngày chưa vào khóa; ngoài danh sách lớp thì server từ chối." |

Kết (15 giây): "Ứng dụng không thay Moodle; nó gom dữ liệu LMS và Portal, giải thích, và chuyển thành việc làm cụ thể trên điện thoại."

## Nhánh dự phòng

- **Mẹo trước giờ (giảm chờ ở bước 14):** sau Start-Demo, đăng nhập GV, mở Lớp cố vấn và một SV một lần rồi quay về màn chọn
  vai trò. Cache Portal ở server giữ 10 phút.

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
7. **Đã kiểm thử thế nào?** Backend JUnit 284 test (1 test schema tắt có chủ đích), Flutter 329 test kể cả cỡ chữ 1.3, màn 320–390 dp,
   chế độ tối; test bảo mật 403/404, injection trong tìm kiếm. Mỗi chức năng chạy thật trên emulator với DB demo, có ảnh chụp; đo
   hiệu năng 12 endpoint × 200 lần: p95 3–29 ms, 0 lỗi. Số liệu cuối: `docs/RELEASE_NOTES.md`.
8. **Triển khai thật cần gì?** (a) bật `MoodleTokenProvider` trỏ vào LMS của Trường (cần văn bản cho phép), MSSV lấy từ tài
   khoản đã xác thực; (b) kết nối chỉ đọc tới CSDL hoặc API
   Moodle thật thay bản sao; (c) key Portal thật, bật ẩn danh mặc định; (d) chạy backend trên máy chủ của Trường với HTTPS, đổi mật
   khẩu role ứng dụng (`tools\Rotate-AppRolePassword.ps1`); (e) ký APK bản phát hành; (f) đối chiếu ngưỡng xếp loại với quy chế
   đào tạo của Trường ĐH Đà Lạt.
