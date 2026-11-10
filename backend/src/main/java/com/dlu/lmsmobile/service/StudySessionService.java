package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.exception.InvalidRequestException;
import com.dlu.lmsmobile.exception.ResourceNotFoundException;
import com.dlu.lmsmobile.repository.InsightsRepository;
import com.dlu.lmsmobile.repository.StudentRepository;
import com.dlu.lmsmobile.repository.StudyPlanRepository;
import com.dlu.lmsmobile.repository.StudySessionRepository;
import org.springframework.stereotype.Service;

import java.time.*;
import java.util.*;

import static com.dlu.lmsmobile.service.Values.*;

/** V2-N10 focus sessions (Pomodoro): validated writes and per-day/per-course summaries. */
@Service
public class StudySessionService {
    public static final int MAX_FOCUS = 180;
    /** Tolerated client clock drift for "not in the future". */
    public static final Duration CLOCK_SKEW = Duration.ofMinutes(1);
    /** A session may be saved late (app killed, offline), but not invented for last month. */
    public static final Duration MAX_AGE = Duration.ofDays(2);
    public static final int MAX_RANGE_DAYS = 62;

    private final StudySessionRepository sessions;
    private final StudyPlanRepository plans;
    private final InsightsRepository insights;
    private final StudentRepository students;
    private final Clock clock;

    public StudySessionService(StudySessionRepository sessions, StudyPlanRepository plans, InsightsRepository insights,
                               StudentRepository students, Clock clock) {
        this.sessions = sessions;
        this.plans = plans;
        this.insights = insights;
        this.clock = clock;
        this.students = students;
    }

    /**
     * Pure validation. Returns null when valid, otherwise the message.
     * focus ≤ (ended − started) in whole minutes + 1, both instants not in the future, not older than 2 days.
     */
    static String validate(Instant started, Instant ended, Integer focus, Instant now) {
        if (started == null || ended == null) return "Thiếu thời điểm bắt đầu/kết thúc";
        if (focus == null || focus < 1 || focus > MAX_FOCUS) return "focusMinutes phải từ 1 đến " + MAX_FOCUS;
        if (!ended.isAfter(started)) return "Thời điểm kết thúc phải sau thời điểm bắt đầu";
        if (ended.isAfter(now.plus(CLOCK_SKEW))) return "Không ghi phiên học ở tương lai";
        if (started.isBefore(now.minus(MAX_AGE))) return "Phiên học quá cũ";
        long span = Duration.between(started, ended).toMinutes();
        if (focus > span + 1) return "Số phút tập trung vượt quá thời lượng phiên";
        return null;
    }

    public Map<String, Object> record(Long userId, Map<String, Object> body) {
        if (body == null) throw new InvalidRequestException("Thiếu nội dung phiên học");
        Instant started = instantOf(body.get("startedAt"));
        Instant ended = instantOf(body.get("endedAt"));
        Integer focus = body.get("focusMinutes") instanceof Integer i ? i : null;
        String error = validate(started, ended, focus, clock.instant());
        if (error != null) throw new InvalidRequestException(error);
        Long courseId = idOf(body.get("courseId"), "courseId");
        Long planItemId = idOf(body.get("planItemId"), "planItemId");
        boolean markDone = Boolean.TRUE.equals(body.get("markPlanItemDone"));
        if (markDone && planItemId == null) throw new InvalidRequestException("Thiếu planItemId");
        if (courseId != null && !insights.isEnrolled(userId, courseId)) {
            throw new ResourceNotFoundException("Course not found");
        }
        if (planItemId != null && plans.findOwned(userId, planItemId).isEmpty()) {
            throw new ResourceNotFoundException("Plan item not found");
        }
        long id = sessions.insert(userId, courseId, planItemId, started, ended, focus);
        if (markDone) plans.updateStatus(userId, planItemId, "done");
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("id", id);
        out.put("courseId", courseId);
        out.put("planItemId", planItemId);
        out.put("startedAt", started.toString());
        out.put("endedAt", ended.toString());
        out.put("focusMinutes", focus);
        out.put("planItemDone", markDone);
        return out;
    }

    /** Minutes per day (every day of the range, zero when no session) and per course. Default: last 7 days. */
    public Map<String, Object> summary(Long userId, String from, String to) {
        ZoneId zone = clock.getZone();
        LocalDate today = LocalDate.now(clock);
        LocalDate t = parse(to, today);
        LocalDate f = parse(from, t.minusDays(6));
        if (t.isBefore(f) || t.toEpochDay() - f.toEpochDay() >= MAX_RANGE_DAYS) {
            throw new InvalidRequestException("Khoảng ngày không hợp lệ");
        }
        List<Map<String, Object>> rows = sessions.minutesByDayAndCourse(userId, f.atStartOfDay(zone).toInstant(),
            t.plusDays(1).atStartOfDay(zone).toInstant());
        return summarize(f, t, rows, courseNames(userId));
    }

    /** Pure aggregation of repository rows. */
    static Map<String, Object> summarize(LocalDate from, LocalDate to, List<Map<String, Object>> rows,
                                         Map<Long, String> names) {
        Map<LocalDate, long[]> days = new TreeMap<>();
        for (LocalDate d = from; !d.isAfter(to); d = d.plusDays(1)) days.put(d, new long[2]);
        Map<Long, long[]> courses = new LinkedHashMap<>();
        long total = 0, count = 0;
        for (Map<String, Object> r : rows) {
            LocalDate d = date(r.get("day"));
            if (d == null || !days.containsKey(d)) continue;
            long m = lng(r.get("minutes")), n = lng(r.get("sessions"));
            days.get(d)[0] += m;
            days.get(d)[1] += n;
            Long c = r.get("course_id") instanceof Number x ? x.longValue() : null;
            courses.computeIfAbsent(c, k -> new long[2]);
            courses.get(c)[0] += m;
            courses.get(c)[1] += n;
            total += m;
            count += n;
        }
        List<Map<String, Object>> dayList = new ArrayList<>();
        days.forEach((d, v) -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("date", d.toString());
            m.put("minutes", v[0]);
            m.put("sessions", v[1]);
            dayList.add(m);
        });
        List<Map<String, Object>> courseList = new ArrayList<>();
        courses.entrySet().stream().sorted((a, b) -> Long.compare(b.getValue()[0], a.getValue()[0])).forEach(e -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("courseId", e.getKey());
            m.put("courseName", e.getKey() == null ? null : names.get(e.getKey()));
            m.put("minutes", e.getValue()[0]);
            m.put("sessions", e.getValue()[1]);
            courseList.add(m);
        });
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("from", from.toString());
        out.put("to", to.toString());
        out.put("totalMinutes", total);
        out.put("sessions", count);
        out.put("days", dayList);
        out.put("courses", courseList);
        return out;
    }

    private Map<Long, String> courseNames(Long userId) {
        Map<Long, String> names = new HashMap<>();
        for (Map<String, Object> c : students.findCoursesByUserId(userId)) {
            Object name = c.containsKey("course_name") ? c.get("course_name") : c.get("fullname");
            names.put(lng(c.get("courseid")), str(name));
        }
        return names;
    }

    private static Instant instantOf(Object v) {
        if (!(v instanceof String s) || s.isBlank()) return null;
        try {
            return OffsetDateTime.parse(s).toInstant();
        } catch (DateTimeException e) {
            throw new InvalidRequestException("Thời điểm phải theo ISO-8601 có múi giờ");
        }
    }

    private static Long idOf(Object v, String name) {
        if (v == null) return null;
        if (v instanceof Integer || v instanceof Long) return ((Number) v).longValue();
        throw new InvalidRequestException(name + " không hợp lệ");
    }

    private static LocalDate parse(String s, LocalDate fallback) {
        if (s == null || s.isBlank()) return fallback;
        try {
            return LocalDate.parse(s);
        } catch (DateTimeException e) {
            throw new InvalidRequestException("Ngày phải theo dạng yyyy-MM-dd");
        }
    }
}
