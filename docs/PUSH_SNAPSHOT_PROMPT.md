# Push GitHub theo cách (b): một commit ảnh chụp, không mang lịch sử cũ

Owner chọn cách (b) ngày 10/11/2026. File này thay bước 5–7 của `PUSH_GITHUB.md`. Quy tắc tuyệt đối 1–4 của file đó vẫn giữ
nguyên: không push main, không `--force`, không đưa `.local/`, APK, JAR, log, key, mật khẩu.

Đã biết (phiên cloud kiểm tra lúc 22:59): repo GitHub là public; nhánh main trên GitHub không có hai file cũ.

Không làm: không viết lại hay xóa lịch sử cục bộ; không đổi hash các commit đã ghi trong RELEASE_NOTES/HANDOFF; không cài công cụ mới.

Thứ tự: kiểm tra 2212001 → bước 1 → bước 2 → F7 (tag cục bộ, Stop-Demo, tổng kết) → bước 3 → 4 → 5.

## 1. Gỡ hai đoạn khỏi cây hiện tại (commit cục bộ bình thường)

- Trước khi sửa, đọc vào biến trong bộ nhớ để dùng khi quét: hai mật khẩu demo cũ (bảng ở dòng 76–79 của
  `backend/docs/authentication_mvp.md`); hai chuỗi hash trong `backend/db/auth/002_seed_demo_auth.sql`. Không in ra, không ghi ra file.
- Tìm chỗ tham chiếu: `git grep -n -e 002_seed_demo_auth -e authentication_mvp`. Nếu có script, test hoặc build nào dùng file SQL
  thì DỪNG và báo, không xóa.
- Sửa: `backend/db/auth/002_seed_demo_auth.sql`: `git rm`. `backend/docs/authentication_mvp.md`: thay bảng mật khẩu bằng một dòng
  "Bảng tài khoản demo của bản cũ đã được gỡ. Hệ đăng nhập hiện tại: docs/FEATURES_V3.md, mục LOGIN." Giữ nguyên phần còn lại.
  `README.md`: thêm dòng "Nhánh này là ảnh chụp mã nguồn bản bảo vệ 20/11/2026; lịch sử phát triển đầy đủ được lưu tại máy của nhóm."
- Đếm số lần xuất hiện của từng mật khẩu và hash cũ trên toàn cây làm việc (`git grep -c -F`, chỉ in số đếm): phải ra 0.
- Commit kèm `docs/PUSH_GITHUB.md` và file này. Không cần gate (file SQL nằm ngoài đường build).

## 2. Kiểm tra DB cục bộ (chỉ đọc, làm trước Stop-Demo)

Trên `lms_mobile_group_dev` và `lms_mobile_group_demo`: `SELECT to_regclass('app.auth_account');`. Nếu bảng tồn tại, đếm số dòng có
login student205 hoặc teacher102. Ghi kết quả vào HANDOFF. Không sửa DB. Thiếu quyền đọc thì ghi "không kiểm tra được".

## 3. Tạo commit ảnh chụp (sau F7)

```powershell
$snap = git commit-tree 'HEAD^{tree}' -m 'DLU LMS Group: defense snapshot 2026-11-20 (single commit; full development history kept locally)'
git rev-list --count $snap        # phải là 1
git rev-parse "$snap^{tree}"      # phải trùng git rev-parse 'HEAD^{tree}'
```

Không tạo nhánh cục bộ, không đổi HEAD. Quét cây `$snap` theo các mẫu ở bước 2 của PUSH_GITHUB và theo các mật khẩu, hash cũ
đang giữ trong bộ nhớ: phải ra 0. `git ls-tree -r --name-only $snap` không được có `.local/`, `.env*`, `*.apk`, `*.jar`, `*.jks`,
`*.keystore`, `*.log`.

## 4. Push

```powershell
git remote add github https://github.com/teddy3704/DOANTOTNGHIEP.git   # đã có thì bỏ qua
git ls-remote github                                                     # chỉ đọc, KHÔNG fetch
git push github "${snap}:refs/heads/dlu-lms-group-bao-ve"
git push github "${snap}:refs/tags/bao-ve-2026-11-20"
```

Nếu ls-remote cho thấy nhánh `dlu-lms-group-bao-ve` hoặc tag `bao-ve-2026-11-20` đã có trên GitHub thì DỪNG, không ghi đè.
CẤM: `git push github bao-ve-2026-11-20`, `git push github HEAD…`, `--tags`, `--all`, `--mirror` (tag và HEAD cục bộ trỏ vào lịch sử
đầy đủ, sẽ đẩy cả commit 6f8c0ab); `--force`. Git Credential Manager mở cửa sổ đăng nhập thì báo owner tự đăng nhập, không tự nhập
token. Xác thực lỗi thì DỪNG, đưa owner đúng một lệnh để tự chạy, ghi SHA dạng chữ, không dùng biến.

## 5. Xác nhận và ghi lại

`git ls-remote github`: cả `refs/heads/dlu-lms-group-bao-ve` lẫn `refs/tags/bao-ve-2026-11-20` đều bằng `$snap`. HANDOFF và
RESUME_STATE ghi: tên nhánh; SHA snapshot; "cùng cây với commit cục bộ <HEAD>"; thời gian push (không ghi token). Báo owner
https://github.com/teddy3704/DOANTOTNGHIEP/tree/dlu-lms-group-bao-ve. Nhánh main giữ nguyên.

Cập nhật GitHub về sau (chỉ khi owner yêu cầu): `git commit-tree 'HEAD^{tree}' -p <SHA snapshot trước> -m '...'`, push
fast-forward vào nhánh; tag trên GitHub giữ nguyên.
