# RESUME_STATE — checkpoint hiện tại (thay nguyên file mỗi lần cập nhật)

Cập nhật: 2026-11-13 08:00 (+07) · Branch codex/group-stack-takeover · Writer: Claude Code (phiên duy nhất)
Nguồn việc: FINAL 13/11 (owner): chốt bản demo dữ liệu thật cho buổi báo cáo 14:00. Không push.
Luật: dữ liệu cá nhân thật (không commit/không copy vào docs/log/fixture/APK/HANDOFF); không đọc/gõ mật khẩu
(owner gõ trên emulator); không sửa demo/dev; không gọi lms.dlu.edu.vn; không bịa dữ liệu; không import hôm nay.

## Trạng thái
- KHÓA CODE từ 10:00 13/11: không sửa code, không build, không import, không đổi cấu hình. Lỗi làm hỏng demo:
  báo owner (lỗi, cách sửa, rủi ro) và chỉ sửa khi owner đồng ý.
- Commit cuối có code: 39c7a4e (trang chủ GV chỉ cộng khóa học kỳ hiện tại trên real, nhãn "· Học kỳ hiện tại").
- APK real đang cài: SHA-256 80e646fc410f189e34e6184526f61dcf9ffe91a85b76392c1a0eea22b6fe4ad0
  (D:\DLU-LMS\Artifacts\real\, SHA256.txt). Backend chạy bản 39c7a4e (Start-Demo, cửa sổ Backend).
- Test: mvn 327/0/0/1; flutter 345; analyze sạch.
- Không quay video (owner bỏ). Dự phòng: Start-Demo + đăng nhập lại; hết cách: ảnh slide.
- Kịch bản: D:\DLU-LMS\RealData\kich-ban-demo.txt (ngoài repo). Ảnh: D:\DLU-LMS\RealData\screens\slides\.
- Windows đang chờ khởi động lại: owner khởi động lại máy trước 13:00 rồi Start-Demo.

## Lịch
- 10:00–11:30 chạy thử cùng owner theo kịch bản (SV ~3', chuyển vai ~20", GV ~2,5'); chỉ sửa kịch bản.
- 13:30 owner Start-Demo (SẴN SÀNG), đăng nhập 2212472 ≤ 1 giờ trước giờ; agent kiểm 5 dòng DEMO_DAY_REAL.md §2.

NEXT_ACTION: chạy thử 10:00 cùng owner; không sửa code.
NEXT_ACTION_IS_MUTATING: no.

## DO_NOT_REPEAT
- Không làm lại REAL-DATA-1/2, không import lại, không chép dữ liệu vào repo, không chạy shift_demo_dates lên real. CẤM push.
- Không ghi đè D:\DLU-LMS\RealData\portal\2212472_bangdiem.csv / _renluyen.csv.
- Nhắc riêng / "Nhắc N SV" chỉ bấm Hủy; không tạo ghi chú/dữ liệu cho sinh viên thật.
- Không quay video.
