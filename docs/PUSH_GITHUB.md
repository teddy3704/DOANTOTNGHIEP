# Đưa mã nguồn lên GitHub — owner đã cho phép ngày 10/11/2026

Phiên cloud soạn. Owner cho phép push lên **https://github.com/teddy3704/DOANTOTNGHIEP**.

**Tình trạng repo trên GitHub** (phiên cloud đã clone kiểm tra ngày 10/11/2026):
- Nhánh `main` đang chứa **một dự án khác**: bản Flutter + Supabase cũ, commit `c773b7e`.
- Ngoài ra có 5 nhánh khác: `agents/restart-app-command`, `flutter-student-support-v1`, `innovation-perfection-hardening`, `innovation-study-planner-intervention`, `integration-api-render-staging`.

## Quy tắc tuyệt đối

1. **Không push vào `main`.** Không `--force`, không xóa hay ghi đè nhánh nào đang có trên GitHub.
2. Push lên **nhánh mới** `dlu-lms-group-bao-ve`. Tag `bao-ve-2026-11-20` chỉ push sau khi xong FINAL-F7.
3. Không đưa lên: `.local/`, file dump SQL, APK, JAR, log, ảnh hay video trong `D:\DLU-LMS\Artifacts`, API key, mật khẩu.
4. Push là thao tác ghi ra ngoài máy. Gặp bất kỳ dấu hiệu bí mật nào trong lịch sử git thì **DỪNG, không push**, báo owner. Xóa bí mật khỏi lịch sử là quyết định của owner.

## Các bước

1. **Kiểm tra cây đang commit**
   - `git status` phải sạch; việc đang làm dở thì commit trước.
   - `git ls-files` không được có: `.local/`, `.env*`, `*.sql` dump (file schema/migration/grants nhỏ thì được), `*.apk`, `*.jar`, `*.jks`, `*.keystore`, `*.log`.
   - `.gitignore` phải có các mẫu tương ứng.
2. **Quét bí mật trên toàn bộ lịch sử**
   - Chạy `git log --all -p` rồi tìm (không phân biệt hoa thường), chỉ in **tên file và số dòng**, không in giá trị:
     - `mk_dev_`, `X-API-KEY:` có giá trị theo sau, `"apiKey"\s*:\s*"[^"]`
     - `password\s*[:=]\s*\S`, `PGPASSWORD=`, `secret\s*[:=]\s*\S{8,}`
     - `BEGIN (RSA|OPENSSH|EC|PRIVATE) KEY`, `ghp_`, `github_pat_`
   - Dòng nào khớp mà là placeholder hoặc tài liệu (ví dụ `<key>`, `***`) thì ghi rõ lý do bỏ qua. Ngoài ra thì DỪNG.
3. **Kiểm tra file lớn**
   - `git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | sort -k3 -n | tail -20`
   - Có blob trên 50 MB thì DỪNG và báo owner. GitHub chặn file trên 100 MB.
4. **README cho nhánh mới.** `README.md` ở gốc phải có:
   - tên đề tài, kiến trúc (Flutter + Spring Boot + PostgreSQL + API Portal);
   - cách chạy (trỏ tới `docs/LOCAL_RUNBOOK.md` và `Start-Demo.ps1`);
   - ghi chú dữ liệu: LMS là dữ liệu mẫu tổng hợp, Portal là dữ liệu mô phỏng do thầy Hiếu cung cấp; không có dữ liệu sinh viên thật, không có secret;
   - danh sách chức năng, trỏ tới `docs/FEATURES_V2.md` và `docs/FEATURES_V3.md`.
   
   Thiếu thì bổ sung (chỉ sửa docs, không cần chạy gate), rồi commit.
5. **Thêm remote và push**
   - `git remote add github https://github.com/teddy3704/DOANTOTNGHIEP.git` (đã có remote này thì bỏ qua).
   - `git fetch github` (chỉ đọc).
   - `git push github HEAD:refs/heads/dlu-lms-group-bao-ve`, **không có** `--force`.
   - Git Credential Manager có thể mở cửa sổ đăng nhập GitHub. Báo owner đăng nhập. Không tự nhập token, không đọc credential.
   - Nếu xác thực lỗi thì DỪNG và đưa owner đúng một lệnh để tự chạy trong PowerShell của họ.
6. **Xác nhận**
   - Hash của `refs/heads/dlu-lms-group-bao-ve` trong `git ls-remote github` phải trùng `git rev-parse HEAD`.
   - Ghi vào HANDOFF và RESUME_STATE: tên nhánh, hash, thời gian (không ghi token).
7. **Push lần 2** sau khi xong FINAL-F7:
   - `git push github HEAD:refs/heads/dlu-lms-group-bao-ve` (fast-forward).
   - `git push github bao-ve-2026-11-20`.
   - Xác nhận lại như bước 6.

**Báo owner:** đường dẫn https://github.com/teddy3704/DOANTOTNGHIEP/tree/dlu-lms-group-bao-ve. Nhánh `main` giữ nguyên. Muốn đặt nhánh mới làm mặc định thì owner tự đổi trong GitHub, mục Settings → Default branch.
