# Hướng dẫn sử dụng — ứng dụng hỗ trợ học tập LMS (DLU)

Ảnh minh họa là ảnh chụp màn hình thật trên emulator với DB demo. Thư mục: `v2` = `D:\DLU-LMS\Artifacts\v2\screens`,
`v3` = `D:\DLU-LMS\Artifacts\v3\screens`, `final` = `D:\DLU-LMS\Artifacts\final\screens`. Dữ liệu Portal trong ảnh là **dữ liệu
mô phỏng**. Nộp bài, làm quiz và chấm điểm chính thức vẫn thực hiện trên LMS; ứng dụng mở đúng trang LMS khi cần.

## Đăng nhập và đăng xuất
- **Mục đích:** vào đúng tài khoản của mình như trên LMS của trường; vai trò (sinh viên/giảng viên) do máy chủ xác định.
- **Cách dùng:** (1) mở app, nhập **mã số sinh viên** (giảng viên: tên đăng nhập) và **mật khẩu**; (2) bấm biểu tượng con mắt để
  xem lại mật khẩu nếu cần; (3) để **Ghi nhớ mã số** nếu muốn lần sau khỏi gõ lại (mật khẩu không bao giờ được lưu); (4) bấm
  **Đăng nhập**. Sai 5 lần liên tiếp thì tạm khóa 15 phút. **Đăng xuất**: biểu tượng cửa ra ở góc trái trang chủ.
- Lần đầu có 3 màn giới thiệu, bấm **Bỏ qua** hoặc **Tiếp**. Nút **Giao diện sáng/tối** ở góc phải màn Đăng nhập.
- **Ảnh:** final `login-01-man-dang-nhap.png`, `login-02-nhap-mssv.png`, `login-03-vao-sinh-vien.png`, `login-04-vao-giang-vien.png`,
  `login-05-khoa-tam.png`; v2 `n18-01-gioi-thieu-buoc-1.png`, `n18-02-che-do-toi.png`.

## Phần 1 — Sinh viên

### Trang chủ
- **Mục đích:** xem nhanh GPA, tiến độ, tình trạng học tập, việc hôm nay, phút học tập trung, lời nhắc của giảng viên.
- **Cách dùng:** (1) mở tab **Trang chủ**; (2) bấm vào thẻ bất kỳ để xem chi tiết; (3) kéo xuống để làm mới.
- **Ảnh:** v3 `p1-01-dashboard-the-gpa-du-lieu-mo-phong.png`, final `f2-00-trang-chu-sv.png`.

### Học vụ (Portal): Bảng điểm, Chương trình, Mô phỏng GPA, Rèn luyện, Quyết định
- **Mục đích:** xem bảng điểm và GPA, tiến độ chương trình đào tạo, học phần đủ điều kiện đăng ký, điểm rèn luyện, quyết định
  học vụ; thử "nếu tôi được…" để biết cần bao nhiêu cho xếp loại mong muốn.
- **Cách dùng:** (1) bấm thẻ **GPA tích lũy** ở trang chủ; (2) chọn tab cần xem; (3) ở **Mô phỏng GPA**, chọn điểm giả định cho
  từng môn đang học; (4) bấm **Nguồn dữ liệu** để xem trường nào được dùng.
- **Ảnh:** v3 `p1-02…p1-04`, `p2-01`, `p2-02`, `p3-01`, `p3-02`, `p4-01`, `p5-01`, `p7-01`.

### Tình trạng học tập (Xanh/Vàng/Đỏ)
- **Mục đích:** thấy mức theo dõi của từng khóa, lý do (ví dụ số ngày chưa vào khóa, bài quá hạn) và tối đa 3 việc giúp lên Xanh.
- **Cách dùng:** (1) bấm thẻ **Tình trạng học tập** ở trang chủ; (2) mở một khóa để xem lý do; (3) bấm việc gợi ý để làm ngay.
- **Ảnh:** v2 `n9-01-dashboard-o-tinh-trang.png`, `n9-02-chi-tiet-ly-do-hanh-dong.png`, `n9-03-khoa-hoc-o-tinh-trang.png`.

### Khóa học, Mô phỏng điểm, Vị trí trong lớp, Gợi ý ôn lại
- **Mục đích:** xem điểm từng hoạt động; tính còn cần bao nhiêu ở bài chưa chấm để qua môn; xem vị trí ẩn danh trong lớp
  (ẩn khi lớp dưới 5 SV); gợi ý chương nên ôn.
- **Cách dùng:** (1) tab **Khóa học** › chọn khóa; (2) bấm **Mô phỏng điểm**, kéo thanh điểm của bài chưa chấm; (3) xem mục
  "Nên ôn lại".
- **Ảnh:** v2 `n1-01…n1-03`, `n3-02-bieu-do-vi-tri-lop.png`, `n2-02-khoa-hoc-nen-on-lai.png`.

### Thẻ ghi nhớ và ôn tập SM-2
- **Mục đích:** ôn đúng thẻ đến hạn; mỗi lần trả lời, app xếp lịch gặp lại.
- **Cách dùng:** (1) bấm chip **Hôm nay cần ôn N thẻ** hoặc khóa › **Flashcards** › **Bắt đầu ôn tập**; (2) chạm để lật thẻ;
  (3) chọn **Quên / Khó / Được / Dễ** (nút ghi rõ "1 ngày", "6 ngày"…); (4) xem tổng kết phiên.
- **Ảnh:** v2 `n5-01-phien-on-mat-truoc.png`, `n5-02-lat-the-4-nut.png`, `n5-03-tong-ket-phien.png`.

### Kế hoạch tuần
- **Mục đích:** biến hạn nộp thật thành lịch học 7 ngày vừa quỹ thời gian mỗi ngày.
- **Cách dùng:** (1) bấm thẻ **Hôm nay: N việc**; (2) chọn quỹ phút/ngày, bấm **Lập kế hoạch**; (3) đánh dấu **Xong** hoặc
  **Bỏ qua**; (4) mục "Quá tải" cho biết việc nào không xếp kịp.
- **Ảnh:** v2 `n6-01…n6-05`.

### Học tập trung (Pomodoro)
- **Mục đích:** đếm giờ học cho một việc trong kế hoạch, lưu phút học, xem biểu đồ 7 ngày và mục tiêu phút.
- **Cách dùng:** (1) bấm thẻ **Học tập trung** hoặc nút bắt đầu ở một mục kế hoạch; (2) **Bắt đầu**; (3) khi xong bấm **Lưu**.
- **Ảnh:** v2 `n10-01…n10-06`.

### Lịch học (tháng/tuần) và xuất Google Calendar
- **Mục đích:** hạn nộp, kế hoạch và buổi học trên một lịch.
- **Cách dùng:** (1) biểu tượng **Lịch** trên trang chủ; (2) chọn **Tháng** hoặc **Tuần**, dùng mũi tên để chuyển; (3) bấm một
  ngày để xem việc; (4) nút **chia sẻ** xuất tệp .ics để mở bằng Google Calendar.
- **Ảnh:** v2 `n12-01-lich-hoc-thang.png`, `n12-02-xuat-ics.png`; final `f2-07-lich-thang.png`.

### Cài đặt nhắc
- **Mục đích:** nhận thông báo trước hạn nộp và nhắc ôn/kế hoạch hằng ngày, kể cả khi đã đóng app.
- **Cách dùng:** (1) biểu tượng **chuông** trên trang chủ; (2) bật/tắt từng loại nhắc, chọn số giờ trước hạn và giờ nhắc hằng ngày;
  (3) bấm **Gửi thử thông báo** — lần đầu Android hỏi quyền, chọn **Allow**; (4) nếu đã từ chối, bấm **Mở cài đặt thông báo**.
- **Ảnh:** final `f2-01…f2-06`; v2 `n7-01…n7-04`.

### Tìm kiếm
- **Mục đích:** tìm khóa, việc, tài liệu, thẻ ghi nhớ, gõ không dấu vẫn ra.
- **Cách dùng:** (1) biểu tượng **kính lúp**; (2) gõ ít nhất 2 ký tự; (3) bấm kết quả để mở khóa tương ứng.
- **Ảnh:** v2 `n13-01-tim-kiem-khong-dau.png`.

### Phân tích, Tuần của bạn, Thành tích
- **Mục đích:** xem nhịp học theo tuần, so sánh tuần này với tuần trước, chuỗi ngày học; huy hiệu tính từ sự kiện thật.
- **Cách dùng:** (1) tab **Phân tích**; (2) thẻ **Tuần của bạn** › nút chia sẻ để xem trước và gửi ảnh; (3) mục **Thành tích** để
  xem tiến độ từng huy hiệu.
- **Ảnh:** v2 `n14-01-tuan-cua-ban-thanh-tich.png`, `n17-01-thanh-tich.png`.

### Thông báo và lời nhắc của giảng viên
- **Mục đích:** đọc lời nhắc riêng của giảng viên và thông báo khác.
- **Cách dùng:** (1) bấm banner **Giảng viên … vừa nhắc bạn** hoặc tab **Thông báo**; (2) bấm để đánh dấu đã đọc.
- **Ảnh:** v2 `n8-06-sv-nhan-nhac-rieng.png`.

### Khi mất mạng
- **Mục đích:** vẫn xem trang chủ, việc, khóa, kế hoạch, thẻ đến hạn đã tải trước đó.
- **Cách dùng:** khi mất kết nối, banner **Đang ngoại tuyến · dữ liệu lúc …** hiện; thao tác ghi bị khóa đến khi có mạng.
- **Ảnh:** v2 `n11-01-ngoai-tuyen-du-lieu-luu.png`.

## Phần 2 — Giảng viên

### Trang chủ giảng viên
- **Mục đích:** việc cần làm tuần này, hoạt động sắp đến hạn, biểu đồ lớp, lối vào lớp cố vấn.
- **Cách dùng:** (1) mở tab **Trang chủ**; (2) bấm thẻ để đi tới khóa/sinh viên liên quan.
- **Ảnh:** v2 `recheck-01-gv-trang-chu-db-demo.png`, v3 `p6-01-trang-chu-gv-lop-co-van-du-lieu-mo-phong.png`.

### Lớp cố vấn học tập (Portal)
- **Mục đích:** kết quả học tập cả lớp cố vấn, phân bố xếp loại, sinh viên cần quan tâm, kèm tín hiệu học tập trên LMS của SV
  trong khóa do chính giảng viên dạy.
- **Cách dùng:** (1) bấm thẻ **Lớp cố vấn**; (2) chọn học kỳ; (3) bật **Ẩn danh** khi trình chiếu; (4) bấm một SV để xem chi tiết;
  xuất CSV chỉ khi đã tắt ẩn danh và xác nhận.
- **Ảnh:** v3 `p6-02…p6-07`, v2 `recheck-02-p6-lop-co-van-du-lieu-mo-phong.png`.

### Khóa học: Sinh viên, Bài tập, Bài kiểm tra
- **Mục đích:** danh sách SV có lọc và điểm theo dõi kèm lý do; ai chưa nộp bài, chưa làm quiz.
- **Cách dùng:** (1) tab **Khóa học** › chọn khóa; (2) tab **Sinh viên** / **Bài tập** / **Bài kiểm tra**; (3) bấm một SV để xem
  tiến độ, điểm, điểm danh.
- **Ảnh:** v2 `n4-03-mo-chi-tiet-sinh-vien.png`.

### Phân tích: Dự báo qua môn, Phân tích bài kiểm tra, Bản đồ nhiệt
- **Mục đích:** nhóm SV theo khả năng qua môn; tìm câu hỏi quá khó, bị bỏ, làm quá nhanh; xem tuần/ngày lớp ít hoạt động.
- **Cách dùng:** (1) trong khóa › tab **Phân tích**; (2) lọc nhóm "Nguy cơ cao"; (3) mở bài kiểm tra có cờ; (4) xem bản đồ nhiệt.
- **Ảnh:** v2 `n4-01-du-bao-qua-mon-lop.png`, `n4-02-loc-nguy-co-cao.png`, `n16-01…n16-03`, `n15-01-ban-do-nhiet-4-muc.png`.

### Nhắc riêng một sinh viên và xuất danh sách cần hỗ trợ
- **Mục đích:** gửi lời nhắc soạn sẵn theo lý do thật (quá hạn, lâu không vào khóa, điểm thấp); xuất CSV nhóm cần hỗ trợ.
- **Cách dùng:** (1) bấm **Nhắc riêng** ở một SV; (2) chọn mẫu, sửa nội dung; (3) bấm **Gửi**; (4) ở tab Phân tích, bấm **Xuất CSV**
  để mở màn chia sẻ.
- **Ảnh:** v2 `n8-01…n8-05`.

### Tìm kiếm
- **Mục đích:** tìm SV trong lớp mình theo tên không dấu hoặc MSSV, tìm bài tập, bài kiểm tra.
- **Cách dùng:** (1) biểu tượng **kính lúp** ở trang chủ; (2) gõ ít nhất 2 ký tự; (3) bấm SV để mở chi tiết theo dõi.
- **Ảnh:** v2 `n13-01-tim-kiem-khong-dau.png` (giao diện chung).
