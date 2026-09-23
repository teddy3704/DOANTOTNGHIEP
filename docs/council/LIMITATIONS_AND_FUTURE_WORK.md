# Giới hạn đã công bố và đường triển khai

| Giới hạn | Đã có | Vì sao chưa thể gọi production/PASS | Bước tiếp theo hợp lệ |
|---|---|---|---|
| DLU Authentication `TO_VERIFY_DLU` | Staging chọn identity mẫu, kiểm tra scope server-side | Chưa có contract đăng nhập/capability Mobile được DLU xác nhận | DLU xác nhận identity flow; tạo adapter và test bằng account được cấp |
| DLU Web Services `TO_VERIFY_DLU` | LMS public và link chính thức đã kiểm chứng; API staging riêng đã chạy | Chưa có dịch vụ/chức năng/permission chính thức cho app | DLU phê duyệt Web Services hoặc integration tương đương; thử read-only theo least privilege |
| Thông báo Android `NOT_VERIFIED` | Quyền thông báo và logic/persistence đã test; màn nhắc việc chạy | Dataset cuối không có hạn nộp tương lai phù hợp để chờ fire 1–2 phút | Thử với dữ liệu/hạn nộp test được phép, không sửa lịch học vụ staging để tạo chứng cứ giả |
| Dữ liệu staging | Mô hình 39/20, Student + Teacher cùng nguồn mẫu | Không phải hồ sơ hay CSDL production DLU | Ánh xạ sang nguồn LMS được cho phép; xác minh chất lượng/ownership |
| Render Free | Endpoint staging hoạt động | Cold start có thể làm request đầu chậm | Warm `/health` 5–10 phút trước demo, retry một lần; lưu ảnh/contract offline |
| Giám sát và bảo mật triển khai | Secret scan, GET-only, 401/404 isolation tests | Chưa phải vận hành production có threat review, monitoring, rate policy hoàn chỉnh | Review với DLU/đơn vị vận hành trước rollout |
| Phê duyệt Nhà trường | Kiến trúc sẵn lớp adapter | Quyền tích hợp, branding, account và dữ liệu thật không thể tự cấp | Xin phép DLU/GVHD, không yêu cầu mật khẩu admin |

Không gọi các giới hạn này là lỗi đã “khắc phục” bằng mock. Demo phải nói rõ nguồn staging và chuyển thao tác chính thức về LMS.
