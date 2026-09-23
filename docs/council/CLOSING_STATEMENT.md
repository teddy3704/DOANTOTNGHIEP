# Lời kết khi bảo vệ

## Khoảng 30 giây

“Nhóm không xây dựng lại LMS của Trường Đại học Đà Lạt. Nhóm phân tích mô hình Moodle theo hướng Database First, tạo lớp dữ liệu và API cho Mobile, rồi triển khai trải nghiệm hỗ trợ sinh viên và giảng viên. Bản staging với dữ liệu mẫu đã chạy và được kiểm thử. Nộp bài, làm quiz, chấm điểm và quản trị học phần vẫn ở LMS chính thức; tích hợp tài khoản và Web Services production cần Nhà trường phê duyệt.”

## Khoảng 60 giây

“Giá trị nhóm hướng đến là giảm thao tác khi người học cần xem nhanh khóa học, việc đến hạn và tiến độ, đồng thời giúp giảng viên nhìn tổng quan lớp và nhóm cần hỗ trợ trên điện thoại. Nhóm chọn Database First để hiểu đúng quan hệ Moodle, rồi tách ba lớp `lms`, `app`, `derived` và một API Fastify thay vì cho Flutter truy cập PostgreSQL. Student và Teacher ở bản staging cùng dùng dữ liệu mẫu và API chỉ đọc, với phạm vi đã kiểm thử. Nút nộp bài và chấm bài dẫn về LMS DLU vì đó là nguồn nghiệp vụ chính thức. Chúng em không nhận rằng đây là dữ liệu hay xác thực production của Trường; phần đó còn cần quyền và Web Services được xác minh. Với phạm vi đã được kiểm chứng, sản phẩm thể hiện một cách mở rộng trải nghiệm Mobile mà vẫn tôn trọng LMS hiện hữu.”
