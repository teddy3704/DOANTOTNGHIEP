# Bộ SQL trình diễn Database First

Mô hình PostgreSQL **development/staging** của nhóm dựa trên cấu trúc Moodle, không phải CSDL production của DLU. Catalog cuối đã xác minh: 3 schema (`lms`, `app`, `derived`), 39 bảng vật lý (35 + 4), 20 view, 39 PK, 38 FK và 548 cột vật lý.

- `lms.*`: thực thể học tập Moodle-oriented, dữ liệu mẫu; không khẳng định trùng schema production của Trường.
- `app.*`: 4 bảng hỗ trợ thuộc ứng dụng; không phải nguồn điểm/bài nộp chính thức. Lời nhắc Mobile đang cục bộ, chưa đồng bộ vào `app.*` staging.
- `derived.*`: 20 read model/analytics. Chỉ báo risk là rule-based, không AI.

Trong bộ cuối: `lms_mobile_learning_schema.sql` là bản sao DDL gốc (chỉ đọc, không chứa credential), `mock_data_sanitized.sql` là bản seed đã vô hiệu hóa mật khẩu mẫu (không dùng để login), `01_verify_database_baseline.sql` và `02_council_database_demo.sql` là truy vấn trình diễn chỉ đọc. Không restore khi demo; chỉ chạy SELECT trên candidate đã lưu/được phép. Không đổi cấu hình database của Render.
