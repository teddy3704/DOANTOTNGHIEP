# DLU LMS GROUP — CONTINUOUS EXECUTION WITH DURABLE CHECKPOINTS

Đây là yêu cầu thực thi cho Claude Code native đang làm việc trên Windows tại `D:\DLU-LMS-Group`.
Tiếp tục dự án hiện có đến hết phạm vi đã duyệt; không scaffold lại, không audit lại từ đầu, không quay về stack cũ.
Mục tiêu là ứng dụng hỗ trợ học tập đáng tin cậy, có luồng sử dụng hoàn chỉnh và bằng chứng kiểm thử, không phải tăng số màn hình.

## 1. Đọc đúng trạng thái, nhận đúng việc

Trước khi sửa, chạy kiểm tra ngắn: OS/runner, cwd, git status, branch, HEAD, các tiến trình build/server/emulator liên quan, dung lượng C/D. Không in toàn bộ command line hoặc environment có thể chứa secret.

Đọc `CLAUDE.md`, `AGENTS.md`, AGENTS của backend/frontend, trạng thái hiện tại và các mục mới nhất của `docs/HANDOFF.md`, `docs/TASK_BOARD.md`, `docs/V2_FEATURES_PROMPT.md`, `docs/V2_FEATURES_PROMPT_PART_B.md`. Chỉ đọc thêm tài liệu/source liên quan đến việc đang làm. Không nạp lại toàn bộ lịch sử mỗi lần.

Snapshot đối chiếu ngày 10/11/2026, KHÔNG phải lệnh reset về snapshot:
- Workspace: `D:\DLU-LMS-Group`; branch quan sát được: `codex/group-stack-takeover`.
- HEAD quan sát được: `b751323`, N12 lịch tổng hợp và xuất .ics.
- N8/N15/N16/E2 đã có kết quả API/runtime trong tài liệu.
- N11 và N12 đã có gate code PASS; runtime vẫn NOT_RUN.
- Gate cuối được ghi: backend 259 tests, 0 failure, 0 error, 1 skipped; Flutter 289 pass.
- Backlog còn lại theo Part B: N13 → N14 → N17 → N18.

Nếu HEAD mới hơn hoặc có WIP mới, dùng thực tế làm nguồn sự thật. Không làm lại N8 chỉ vì transcript cũ dừng ở N8. Không xem các con số trên là kết quả do phiên này vừa chạy.

Chỉ một writer trên working copy. Nếu đây chính là phiên writer đang tiếp tục, giữ ownership. Nếu là phiên mới, xác minh phiên cũ không còn ghi/build và đọc bàn giao trước khi nhận. Không giành quyền ghi hoặc tắt tiến trình của người khác. Không suy ra quyền ghi chỉ từ một dòng HANDOFF cũ.

## 2. Trí nhớ bền vững: làm ngay từ đầu, không chờ hết usage

Tạo hoặc cập nhật `docs/RESUME_STATE.md` thành một checkpoint ngắn, ưu tiên dưới 120 dòng. Đây là trạng thái hiện tại, không phải bản sao toàn bộ transcript. Giữ lịch sử quan trọng trong HANDOFF hiện có.

Checkpoint phải có:
- Thời điểm +07; workspace; branch; HEAD; writer/session nếu biết thật.
- WIP và file đang sửa; milestone đang làm; việc cuối đã hoàn tất.
- CODE / TESTS / APK / RUNTIME / OWNER_VALIDATION tách riêng.
- Gate đã chạy: lệnh, exit code, tổng pass/fail/skip, log và phạm vi source được kiểm thử.
- Command/job đang chạy: PID hoặc job ID nếu có, thời điểm bắt đầu, log trên D, điều kiện nhận biết hoàn tất.
- Database target NAME ONLY; phạm vi đọc/ghi đã được duyệt. Không ghi host/URL/credential vào checkpoint.
- Artifact, SHA-256 đầy đủ, revision hoặc fingerprint source tương ứng.
- Dung lượng C/D; lỗi còn tồn tại; việc cần owner và lý do.
- `NEXT_ACTION`: đúng một bước nhỏ cụ thể có thể làm tiếp.
- `DO_NOT_REPEAT`: những việc đã PASS không cần làm lại.
- `NEXT_ACTION_IS_MUTATING`: yes/no; nếu yes, cách xác minh tác vụ chưa được thực hiện.

Cập nhật sau mỗi thay đổi nhỏ hoàn chỉnh, sau mỗi gate và TRƯỚC command dài. Ghi checkpoint bằng cách thay thế file nguyên vẹn, tránh ghi dở. Không đợi gần hết hạn mức: giới hạn có thể đến trước khi kịp ghi.

Giữ `CLAUDE.md` gọn: bảo toàn nội dung có sẵn, thêm chỉ dẫn đọc `docs/RESUME_STATE.md` lúc bắt đầu/tiếp tục nếu chưa có. Không chép nguyên prompt dài này vào mọi file nhớ; không tạo nhiều bộ checkpoint mâu thuẫn.

## 3. Khi hết usage, compact, mất kết nối hoặc khởi động lại

Phân biệt usage quota với context window. Compact không cấp thêm quota.

- Nếu client đã bật cơ chế chính thức tiếp tục sau reset: để client chờ theo giới hạn; không viết vòng lặp gửi request/prompt liên tục.
- Không mua extra usage, chuyển sang API trả tiền, đổi tài khoản hoặc dùng flag bỏ qua quyền để tiếp tục.
- Không tự hứa đánh thức phiên đã đóng hay chạy lúc máy ngủ. Kiểm chứng cơ chế của phiên hiện tại; nếu cần owner bật cài đặt, chỉ đưa đúng thao tác một lần.
- Nếu còn khả năng ghi checkpoint khi thấy cảnh báo, ghi `WAITING_FOR_USAGE_RESET`; nếu bị cắt đột ngột, phiên sau dùng checkpoint gần nhất cùng Git/process/log thực tế.
- Sau reset/resume: đọc checkpoint → đối chiếu HEAD/WIP/process/log → xác định thao tác cuối đã hoàn tất chưa → tiếp tục NEXT_ACTION còn thiếu.
- Không khởi chạy build/server/emulator trùng. Nếu job cũ đã kết thúc, đọc exit code/report; nếu không có bằng chứng thì ghi UNKNOWN/NOT_VERIFIED, không tự coi là PASS.
- Không chạy lại migration, generate-plan, gửi nhắc nhở hay ghi dữ liệu chỉ vì lệnh trước mất phản hồi. Kiểm tra kết quả và tính idempotent trước, tránh tác dụng phụ lặp.
- Khi toàn bộ phạm vi hoàn tất, kết thúc với báo cáo; không tự phát sinh vòng cải tiến vô hạn.

## 4. Ưu tiên hoàn thiện sản phẩm

Từ trạng thái THẬT, làm việc còn thiếu theo thứ tự:
1. Khắc phục lỗi đã biết có ảnh hưởng demo/độ tin cậy.
2. Hoàn tất runtime N11/N12 khi đủ storage và môi trường; nếu emulator bị chặn, ghi rõ và tiếp tục phần code/test độc lập, không bỏ mất gate runtime.
3. N13 tìm kiếm → N14 tuần của bạn → N17 thành tích → N18 polish theo specification Part B. Không viết lại phần đã xong.
4. Regression liên vai trò, artifact cuối, bằng chứng, runbook demo và bàn giao.

Mỗi chức năng cần trả lời được: người dùng đang gặp vấn đề gì → dữ liệu nào chứng minh → họ làm được hành động gì → trạng thái/kết quả thay đổi ra sao. Giữ liên kết tìm kiếm → nội dung/việc cần làm → kế hoạch/phiên học → tổng kết. Không chỉ thêm chart/card không hành động.

Không tự mở rộng sang chat, AI trả phí, backend mới, Supabase/Neon/Render, hoặc viết lại Moodle. Nộp bài, làm quiz, chấm điểm chính thức vẫn ở LMS. Flutter không kết nối trực tiếp PostgreSQL.

## 5. Các điểm phải kiểm tra cụ thể

### Lỗi hiện biết
- `Hoạt động gần nhất: -6 ngày trước`: xử lý ngày tương lai một cách trung thực, không abs() để biến nó thành quá khứ, không tự đổi đồng hồ hay sửa dữ liệu LMS cho đẹp. Có test cho quá khứ/hiện tại/tương lai.
- Nhãn trục biểu đồ bị xuống dòng; hộp chọn giờ còn tiếng Anh.
- HANDOFF có header cũ mâu thuẫn với lịch sử mới; COMPARISON_FACTS có trạng thái cũ. Cập nhật phần hiện trạng, giữ lịch sử có ngày.

### N11 offline
- Dữ liệu phải gắn đúng user + role + nguồn/API environment; không trộn tài khoản dù đổi nhanh khi request cũ còn đang chạy.
- Có thời điểm lưu/nhãn stale; không cache token/password; khóa write khi offline.
- Logout/đổi account phải xóa hoặc cô lập cache đúng; thử khởi động lại app.
- Không dùng cache để che lỗi 401/403 hoặc biến lỗi server thành dữ liệu giả. Retry/khôi phục online rõ ràng.
- Xem lại chính sách hết hạn cache; nếu thay đổi, nêu lý do và test. Không tuyên bố đã có TTL khi chưa implement.

### N12 calendar
- Thử dữ liệu nhiều nguồn, tháng rỗng, biên tháng và timezone.
- .ics: UID ổn định, escape, UTC/TZID hợp lệ, nhắc theo N7; validate nội dung thực tế.
- Share sheet mở được không đồng nghĩa calendar đã import thành công. Ghi hai kết quả riêng; không gửi/upload dữ liệu ra tài khoản ngoài khi chưa được phép.
- Part B yêu cầu tuần và tháng; nếu còn thiếu tuần, triển khai hoặc đánh dấu PARTIAL, không đổi tiêu chí để tự PASS.

### N13 search
- Đúng phạm vi SV/GV, SQL tham số hóa, 2–100 ký tự, tối đa 20 kết quả theo yêu cầu.
- Tiếng Việt gồm dấu tổ hợp và đ/Đ; kiểm thử `nguyen`/`Nguyễn`, `dao`/`Đào`.
- Debounce và loại phản hồi cũ; loading/empty/error/retry; tap kết quả đi đúng màn.
- Injection/IDOR/ngoài roster phải bị chặn ở backend, không chỉ ẩn UI.

### N14 và N17
- Chỉ tính từ sự kiện thật trong database local/demo đã duyệt, phân biệt thiếu dữ liệu với số 0.
- Không cộng trùng sự kiện; biên tuần/tháng, timezone và trạng thái chưa chấm được test.
- Không suy ra ngày đạt huy hiệu hay “thoát mức đỏ” từ snapshot hiện tại nếu thiếu lịch sử. Với chỉ tiêu không đủ dữ kiện: giải thích giới hạn/ẩn hợp lý, đánh dấu PARTIAL; không tự tạo lịch sử giả hoặc DDL chưa duyệt.
- Chia sẻ báo cáo phải có preview và thao tác chủ động; không tự gửi cho bên thứ ba.

### N18
- Dark/light, textScale 1.3, chiều rộng 320/390, keyboard, semantics, empty/error/loading; không sửa test sang màn lớn chỉ để né overflow ở màn nhỏ.
- Onboarding dùng đúng luồng LOCAL hiện tại; không mở quyền chọn role trong production.
- Mọi nút hiện ra phải làm việc thật; không thêm placeholder, Snackbar “sắp có” hoặc dữ liệu tô đẹp.

## 6. Gate phải thuộc đúng bản code

KHÔNG sửa source của backend trong khi backend đang test/package; KHÔNG sửa source Flutter trong khi Flutter đang analyze/test/build. Log trước đã có JAR chứa lớp của milestone tiếp theo đang viết dở: không lặp lại.

Trước gate: kết thúc chỉnh sửa, ghi HEAD + trạng thái WIP/fingerprint của tập source thực sự được kiểm thử (gồm file mới). Format xong rồi lấy fingerprint để tránh nhầm thay đổi do format với tác vụ khác.
Trong gate: chỉ làm việc độc lập không ảnh hưởng input. Không cùng lúc chạy nhiều build nặng trên máy thiếu dung lượng.
Sau gate: kiểm source còn khớp, exit code/report/artifact/hash. Nếu input đã đổi, kết quả chỉ áp dụng snapshot cũ; rerun gate bị ảnh hưởng.

Dùng script hiện có sau khi đọc đúng tham số:
- `tools\Test-Backend.ps1 -Package` khi backend thay đổi.
- `tools\Test-Flutter.ps1` khi Flutter thay đổi.
- `tools\Test-Flutter.ps1 -BuildApk` khi cần artifact cho native-plugin thay đổi hoặc milestone runtime/final.

Không lặp full gate sau thay đổi docs-only. Với sửa nhỏ, chạy test liên quan trước rồi gate tổng hợp lúc chốt milestone. Không bỏ assertion/skip test mới chỉ để xanh. Test skip có sẵn phải ghi rõ.

Không báo RUNTIME_PASS từ unit/widget test. Không báo owner đã tự chạy demo nếu chỉ agent chạy. O1 owner validation sau khi đóng Claude vẫn cần đúng owner thực hiện.

## 7. Storage và môi trường

- Source hiện tại: `D:\DLU-LMS-Group`; toolchains/cache/artifacts nằm trong `D:\DLU-LMS`.
- Dot-source `tools\Use-LocalToolchain.ps1` trong process cần dùng. Dùng log path tuyệt đối trên D; đừng redirect theo TEMP cũ trước khi script đổi TEMP.
- Kiểm C/D trước/sau download, build, chạy emulator. C <15 GiB: dừng tác vụ nặng, ghi STORAGE_BLOCKED, tiếp tục việc nhẹ an toàn.
- Trước emulator tuân thủ runbook hiện hành (đang yêu cầu khoảng C >=22 GiB vì đã quan sát tăng pagefile 5–6 GiB). Không hạ gate cho qua.
- Không tự sửa pagefile, nâng quyền, đổi global TEMP, di chuyển toolchain đang chạy hoặc xóa file ngoài phạm vi đã xác minh.
- Cache Dart/Gradle/SDK trên C có junction sang D: không xóa nhầm đích D, không “dọn” junction để giải phóng C.
- Không chạy lại script cleanup một lần ở `D:\DLU-LMS\Artifacts\Storage-Maintenance-2026-11-09`.
- Nếu cần dọn thêm, chỉ đề xuất hoặc xử lý cache tái tạo được trong quyền đã có, kiểm exact path/process/reparse; giữ source, DB, báo cáo và artifact mới nhất.

## 8. Database, secret và quyền

Tuân thủ AGENTS hiện tại. Dùng đúng cấu hình local hiện có, không đọc secret vào hội thoại/log/screenshot/export. Chỉ ghi tên database và kết quả đã làm sạch.

`lms`/`derived` đọc; chỉ ghi dữ liệu app qua luồng đã duyệt trên database demo/local đã xác nhận. Không restore lại, đổi target, DDL/GRANT/role/password, sửa server config hoặc đụng production khi chưa có phê duyệt riêng.

Không lấy credential từ ứng dụng/tài khoản khác. Không bypass SSO/MFA/UAC hoặc dùng `--dangerously-skip-permissions`. Lỗi credential/quyền: dừng phần đó, mô tả một thao tác owner cần làm, tiếp tục các phần độc lập được phép.

## 9. Git, bằng chứng và nhận xét học thuật

Giữ branch/worktree thực tế, không reset/rewrite/rebase hoặc đổi remote. Không push. Commit cục bộ theo từng milestone trong quyền đã duyệt; review/stage file tường minh và secret-scan trước commit. Không git add toàn bộ cây mù quáng; không commit env, SQL dump, APK, cache, log thô hoặc dữ liệu cá nhân.

Mỗi milestone cập nhật TASK_BOARD/HANDOFF/FEATURES và tài liệu liên quan, tách CODE/TEST/APK/RUNTIME. Final artifact có full SHA-256 và source revision; screenshot/video chỉ từ màn thật. Không dùng APK cũ để chứng minh source mới.

Không khẳng định “Moodle không có chức năng X” nếu chưa đối chiếu phiên bản/phạm vi và nguồn chính thức. Ghi giá trị bổ sung cụ thể: tổng hợp nhiều nguồn, cá nhân hóa, giải thích và hành động tiện trên mobile. Giả định mô phỏng điểm không phải điểm chính thức; dữ liệu demo/Portal mô phỏng không phải dữ liệu DLU live.

## 10. Tiết kiệm usage, tiếp tục có kiểm soát

- Ưu tiên code/test/runtime; không viết báo cáo dài sau từng lệnh.
- Đọc diff và đoạn source liên quan; tránh dump hàng nghìn dòng log rồi đọc lại.
- Chỉ thêm abstraction/dependency khi có nhu cầu cụ thể, kiểm version đang cài và tài liệu thật.
- Tối đa một subagent độc lập read-only khi giúp giảm công việc; không mở nhiều writer trên cùng working copy để “chạy nhanh”.
- Không hỏi “có muốn tiếp tục không” sau mỗi milestone. Tiếp tục backlog đã duyệt; hỏi đúng lúc cần quyền mới, lựa chọn có hậu quả, hoặc thiếu dữ kiện không thể tự xác định.
- Sau mỗi milestone, trả tiến độ ngắn: kết quả mới / bằng chứng / việc kế tiếp, rồi tiếp tục.

## 11. Điểm kết thúc và bàn giao

Phạm vi hoàn tất khi các mục đã duyệt có implementation và gate tương ứng, runtime thực tế hoặc blocker được ghi rõ, Start/Stop-Demo dùng được, artifact cuối đúng source, docs thống nhất. Không gọi toàn bộ PASS nếu còn runtime/owner check chưa chạy.

Bàn giao cuối: STATUS; HEAD/branch; chức năng CODE+RUNTIME đã xong; NOT_RUN/PARTIAL; tests thực chạy; APK/JAR+SHA256; screenshot/video; dung lượng; giới hạn dữ liệu; bước owner còn thiếu; NEXT_ACTION.

BẮT ĐẦU: đọc checkpoint thực tế, tạo/cập nhật RESUME_STATE ngắn, xác định đúng bước chưa xong rồi thực hiện. Không chỉ trả lại kế hoạch. Nếu hiện đang bị quota chặn, dùng cơ chế chờ chính thức; khi có lượt trở lại, tiếp tục từ checkpoint, không bắt đầu lại.
