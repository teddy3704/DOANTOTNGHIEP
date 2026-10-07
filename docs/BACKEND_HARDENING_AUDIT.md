# Backend hardening audit — 07/10/2026

Phạm vi: Fastify/TypeScript hiện có trên nhánh `innovation-perfection-hardening`, baseline `2e04089`. Không thay backend, không đọc/log credential, không ghi `lms.*`, không thay Render environment trong bước sửa code này.

## Findings và sửa thực tế

| Mức | Finding | Sửa / chứng minh |
| --- | --- | --- |
| HIGH | Assignment không có deadline (`duedate=0`) có thể thành epoch 1970 và được xếp quá hạn. | GROUP adapter dùng `to_timestamp(nullif(duedate,0))`; Assignment/TeachingWork `dueAt` nullable, giữ nguyên key/envelope. Ranking bỏ deadline unknown/epoch cũ. Test SQL projection + HTTP explicit null. |
| HIGH | Teacher roster không recheck thời hạn enrolment như attention; badge roster dùng rule cũ khác Inbox. | Dùng chung scope active enrolment + course-level student role; roster badge tính qua `rankAttention`, không tin `risk_level` thô. Đọc theo batch, không N+1 theo student. |
| MEDIUM | Course không có hoạt động tracking bị coi là tiến độ thấp. | `total_tracked_activities` chỉ dùng nội bộ; low-progress weight chỉ cộng khi denominator > 0. Không thêm field vào response public. Snapshot numeric hiện hữu không đổi. |
| MEDIUM | Reopen workflow đã kết thúc / race sau precheck. | Handled plan không reopen/reschedule; resolved intervention immutable, following_up không trở về open. Cả service và SQL update predicate kiểm tra; vẫn cho xử lý/xóa plan quá giờ và khép hồ sơ có lịch cũ quá giờ. |
| MEDIUM | Follow-up mới có thể hẹn trước thời điểm ghi nhận. | Chỉ validate date mới/rescheduled từ hiện tại; không reject legacy read hoặc thao tác close. Date null vẫn hợp lệ. |
| MEDIUM | Retry nhanh có thể append cùng follow-up hai lần. | Sau scoped parent row lock, identical note/outcome/snapshot/next-date trong 5 giây trả existing state, không append. Intentional khác nội dung/time vẫn là một follow-up mới. Plan và active intervention đã có uniqueness guard. |
| MEDIUM | Unsupported content type bị biến thành unexpected 500. | 415 `UNSUPPORTED_MEDIA_TYPE`, message an toàn, error envelope không đổi. 4xx log info; 5xx log error với request id/route/status/fixed failure code, không raw exception. |
| MEDIUM | SELECT 1 không chứng minh application schema sẵn sàng. | `/health` giữ JSON contract nhưng GROUP source kiểm tra essential relation-column surfaces bằng read-only LIMIT 0. `/health/live` riêng chỉ báo process sống, không dùng thay Render readiness. Startup verify readiness trước listen. |
| LOW | Startup/pool event dùng ad-hoc console output, policy dễ bị mở rộng thiếu redaction. | Fastify/Pino central status-only policy, fixed service binding, request/response/error serializers an toàn, redaction header/body/password/token/config. Startup/pool/shutdown events structured; bootstrap trước logger chỉ fixed JSON event. |
| LOW | Weight/threshold magic numbers trong ranking. | `domain/priority-rules.ts`: typed immutable heuristic names; các trọng số hiện có giữ nguyên, score và reasons cùng nhánh. |

## Boundary, null và thời gian

- Identity staging chỉ là alias allowlist synthetic, không phải DLU auth. Student owner/course/assignment visibility và Teacher owner/course/context/learner active enrolment được kiểm tra trong data layer trên từng operation. Forbidden/missing cùng 404 để tránh enumeration; không tự sửa thành 403 làm lộ record.
- Không có academic write, submission/grading endpoint hay production fixture fallback. Writer chỉ chứa reviewed `app.*` statements; driver detail không ra HTTP hoặc log.
- Deadline null không bằng zero, grade null không được dùng làm zero-grade signal. Missing engagement không được chuyển thành inactivity score trong engine. Progress mẫu numeric không đổi; denominator 0 không được xem là low-progress signal.
- API timestamps có timezone/absolute instant; PostgreSQL epoch nguồn → timestamptz → ISO/offset. Server so sánh epoch milliseconds; Flutter hiển thị giờ Việt Nam. Test qua mốc 00:00 +07:00 chứng minh không đổi ngày hai lần.
- Hai pending/overdue counts là hai tập trạng thái riêng, **không** giả định overdue <= pending.
- Derived monitoring duplicate identity bị fail closed; assignment duplicates identical được de-duplicate, conflicting status/assignment rows không tạo recommendation.
- Backward-compatible envelope/identity headers giữ nguyên. **Widening có chủ đích**: assignment và teaching work dueAt string → string|null. APK cũ không được coi là compatible với no-deadline record mới; 8 assignments candidate hiện tại có deadline nên rollback dataset không đổi payload. APK hardening xử lý null rõ ràng.

## Các kiểm tra đã chạy trong bước backend

```powershell
cd integration-api
node --experimental-strip-types --test test/hardening.test.ts test/innovation-domain.test.ts test/innovation-http.test.ts test/group-adapter.test.ts
node --experimental-strip-types --test test/hardening.test.ts test/innovation-store.test.ts
npm run typecheck
npm run build
npm run format:check
```

Targeted core/hardening: 36/36 PASS; final hardening/domain/store: 31/31 PASS, gồm mốc midnight +07:00. Typecheck, build, format PASS. Full suite/audit/staging/runtime được chốt một lần bởi final QA, không suy từ test doubles thành live PASS.

Skill PostgreSQL best practices ảnh hưởng đến cách sửa: giữ Teacher reads theo batch, reuse pool và transaction ngắn/timeout; transaction-scoped lock chặn retry trùng, không thêm index đoán hoặc gọi network trong write transaction.

## Giới hạn còn giữ đúng

- `/health` kiểm tra essential schema surfaces, không thay catalog audit/version history hoặc chứng minh mọi migration trong tương lai đã apply.
- Duplicate follow-up guard có phạm vi retry ngắn, không phải durable cross-client idempotency token. API success không được tạo ra fake academic outcome.
- Current numeric Teacher snapshot không biểu diễn đủ “unknown progress” trên public DTO; internal denominator guard ngăn false priority. Thay đổi DTO rộng hơn chỉ theo contract được phê duyệt.
- DLU Authentication/Web Services vẫn `TO_VERIFY_DLU`; heuristics không AI, không dự đoán trượt, không quyết định học vụ.
