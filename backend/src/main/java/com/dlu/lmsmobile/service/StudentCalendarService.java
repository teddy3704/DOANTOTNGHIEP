package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.exception.InvalidRequestException;
import com.dlu.lmsmobile.repository.StudentDetailRepository;
import com.dlu.lmsmobile.repository.StudentRepository;
import com.dlu.lmsmobile.repository.StudyPlanRepository;
import org.springframework.stereotype.Service;

import java.time.*;
import java.util.*;

import static com.dlu.lmsmobile.service.Values.*;

/**
 * V2-N12 calendar: deadlines (derived.unified_tasks), study plan items (N6, app.study_plan_items) and
 * attendance sessions (lms.attendance_sessions of enrolled courses) of ONE student in [from, to].
 * Each event has a stable uid so an exported .ics updates instead of duplicating.
 */
@Service
public class StudentCalendarService {
    public static final int MAX_DAYS = 62;

    private final StudentRepository students;
    private final StudentDetailRepository details;
    private final StudyPlanRepository plans;
    private final Clock clock;

    public StudentCalendarService(StudentRepository students, StudentDetailRepository details, StudyPlanRepository plans,
                                  Clock clock) {
        this.students = students;
        this.details = details;
        this.plans = plans;
        this.clock = clock;
    }

    public Map<String, Object> calendar(Long userId, String from, String to) {
        LocalDate today = LocalDate.now(clock);
        LocalDate f = parse(from, today.withDayOfMonth(1));
        LocalDate t = parse(to, f.plusMonths(1).minusDays(1));
        if (t.isBefore(f) || t.toEpochDay() - f.toEpochDay() >= MAX_DAYS) {
            throw new InvalidRequestException("Khoảng ngày không hợp lệ");
        }
        List<Map<String, Object>> courses = students.findCoursesByUserId(userId);
        Map<Long, List<Map<String, Object>>> sessions = new LinkedHashMap<>();
        for (Map<String, Object> c : courses) {
            long id = lng(c.get("courseid"));
            sessions.put(id, details.findAttendanceSessions(userId, id));
        }
        List<Map<String, Object>> events = assemble(f, t, clock.getZone(), students.findAllTasks(userId),
            plans.findRange(userId, f, t), courses, sessions);
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("from", f.toString());
        out.put("to", t.toString());
        out.put("timeZone", clock.getZone().getId());
        out.put("events", events);
        return out;
    }

    /** Pure: rows → events inside [from, to] (local days), sorted by start. */
    static List<Map<String, Object>> assemble(LocalDate from, LocalDate to, ZoneId zone,
                                              List<Map<String, Object>> tasks, List<Map<String, Object>> planRows,
                                              List<Map<String, Object>> courses,
                                              Map<Long, List<Map<String, Object>>> sessionsByCourse) {
        Map<Long, String> names = new HashMap<>();
        for (Map<String, Object> c : courses) names.put(lng(c.get("courseid")), str(c.get("course_name")));
        Instant start = from.atStartOfDay(zone).toInstant();
        Instant end = to.plusDays(1).atStartOfDay(zone).toInstant();
        List<Map<String, Object>> out = new ArrayList<>();

        for (Map<String, Object> r : tasks) {
            long due = lng(r.get("due_time"));
            if (due <= 0) continue;
            Instant at = Instant.ofEpochSecond(due);
            if (at.isBefore(start) || !at.isBefore(end)) continue;
            String type = "assignment".equals(str(r.get("task_type"))) ? "assign" : str(r.get("task_type"));
            Long course = r.get("courseid") instanceof Number n ? n.longValue() : null;
            Map<String, Object> e = event("deadline-" + type + "-" + lng(r.get("source_id")), "deadline",
                str(r.get("title")), course, firstNonNull(str(r.get("course_name")), names.get(course)), at, null, false);
            e.put("done", "completed".equals(str(r.get("task_status"))));
            e.put("moodlePath", r.get("moodle_path"));
            e.put("courseModuleId", r.get("coursemoduleid") instanceof Number n ? n.longValue() : null);
            out.add(e);
        }
        for (Map<String, Object> r : planRows) {
            LocalDate d = date(r.get("plan_date"));
            if (d == null || d.isBefore(from) || d.isAfter(to)) continue;
            Long course = r.get("course_id") instanceof Number n ? n.longValue() : null;
            Map<String, Object> e = event("plan-" + lng(r.get("id")), "plan", str(r.get("title")), course,
                names.get(course), d.atStartOfDay(zone).toInstant(), null, true);
            e.put("date", d.toString());
            e.put("minutes", (int) lng(r.get("planned_minutes")));
            e.put("done", "done".equals(str(r.get("status"))));
            if ("skipped".equals(str(r.get("status")))) continue;
            out.add(e);
        }
        for (Map.Entry<Long, List<Map<String, Object>>> c : sessionsByCourse.entrySet()) {
            for (Map<String, Object> s : c.getValue()) {
                long sess = lng(s.get("sessdate"));
                if (sess <= 0) continue;
                Instant at = Instant.ofEpochSecond(sess);
                if (at.isBefore(start) || !at.isBefore(end)) continue;
                long duration = lng(s.get("duration"));
                String title = "Điểm danh: " + firstNonNull(str(s.get("attendance_name")), "Buổi học");
                Map<String, Object> e = event("attendance-" + lng(s.get("session_id")), "attendance", title,
                    c.getKey(), names.get(c.getKey()), at, duration > 0 ? at.plusSeconds(duration) : null, false);
                e.put("marked", s.get("acronym") != null || s.get("status_description") != null);
                out.add(e);
            }
        }
        out.sort(Comparator.comparing((Map<String, Object> e) -> str(e.get("start")))
            .thenComparing(e -> str(e.get("uid"))));
        return out;
    }

    private static Map<String, Object> event(String key, String type, String title, Long courseId, String courseName,
                                             Instant start, Instant end, boolean allDay) {
        Map<String, Object> e = new LinkedHashMap<>();
        e.put("uid", key + "@dlu-lms-group");
        e.put("type", type);
        e.put("title", title == null ? "" : title);
        e.put("courseId", courseId);
        e.put("courseName", courseName);
        e.put("start", start.toString());
        e.put("end", end == null ? null : end.toString());
        e.put("allDay", allDay);
        return e;
    }

    private static String firstNonNull(String a, String b) {
        return a != null ? a : b;
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
