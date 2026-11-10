package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.exception.InvalidRequestException;
import com.dlu.lmsmobile.exception.ResourceNotFoundException;
import com.dlu.lmsmobile.repository.InsightsRepository;
import com.dlu.lmsmobile.repository.TeacherRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.DayOfWeek;
import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.TemporalAdjusters;
import java.util.*;

import static com.dlu.lmsmobile.service.Values.*;

/**
 * Class-level learning insights for a teacher. Access is limited to courses the teacher is
 * assigned to (same check as the monitoring endpoints). Output is aggregate plus a short list
 * of students with plain-language reasons; it never states a conclusion about ability.
 */
@Service
@Transactional(readOnly = true)
public class ClassInsightsService {
    static final int MIN_WEEKS = 4, MAX_WEEKS = 16;
    static final double LOW_COMPLETION_RATE = 50.0;
    static final int MAX_ATTENTION_STUDENTS = 10, MAX_LOW_ACTIVITIES = 5;

    private final TeacherRepository teachers;
    private final InsightsRepository insights;
    private final Clock clock;
    private final String dataMode;

    public ClassInsightsService(TeacherRepository teachers, InsightsRepository insights, Clock clock,
                                @Value("${app.data-source.mode:demo}") String dataMode) {
        this.teachers = teachers;
        this.insights = insights;
        this.clock = clock;
        this.dataMode = "live".equalsIgnoreCase(dataMode) ? "live" : "demo";
    }

    /**
     * V2-N15 standalone engagement heatmap (students × weeks), the same computation as the heatmap inside
     * class insights, plus a 4-level intensity per cell. Roster students only; course not owned → 404.
     */
    public Map<String, Object> engagementHeatmap(Long teacherId, Long courseId, int requestedWeeks) {
        if (requestedWeeks < 1) throw new InvalidRequestException("Số tuần phải lớn hơn 0");
        if (!teachers.hasCourse(teacherId, courseId)) throw new ResourceNotFoundException("Teacher course not found");
        int weeks = Math.max(MIN_WEEKS, Math.min(MAX_WEEKS, requestedWeeks));
        LocalDate today = LocalDate.now(clock);
        LocalDate firstWeek = today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY)).minusWeeks(weeks - 1L);
        long since = firstWeek.atStartOfDay(clock.getZone()).toEpochSecond();
        List<Map<String, Object>> roster = teachers.findStudents(teacherId, courseId);
        Map<String, Object> heat = activityHeatmap(roster, insights.findStudentEventsByWeek(teacherId, courseId, since),
            firstWeek, today);
        long max = lng(heat.get("max_events"));
        for (Object o : (List<?>) heat.get("rows")) {
            @SuppressWarnings("unchecked") Map<String, Object> row = (Map<String, Object>) o;
            List<Integer> levels = new ArrayList<>();
            for (Object e : (List<?>) row.get("weekly_events")) levels.add(heatLevel(lng(e), max));
            row.put("levels", levels);
        }
        heat.put("level_count", 4);
        return heat;
    }

    /** Pure: 0 = no event; 1–4 = quarters of the class maximum (ceil), so any activity is at least level 1. */
    static int heatLevel(long events, long max) {
        if (events <= 0 || max <= 0) return 0;
        return (int) Math.max(1, Math.min(4, Math.ceil(4.0 * events / max)));
    }

    public Map<String, Object> getClassInsights(Long teacherId, Long courseId, int requestedWeeks) {
        if (requestedWeeks < 1) throw new InvalidRequestException("Số tuần phải lớn hơn 0");
        if (!teachers.hasCourse(teacherId, courseId)) throw new ResourceNotFoundException("Teacher course not found");
        int weeks = Math.max(MIN_WEEKS, Math.min(MAX_WEEKS, requestedWeeks));
        LocalDate today = LocalDate.now(clock);
        LocalDate firstWeek = today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY)).minusWeeks(weeks - 1L);
        long since = firstWeek.atStartOfDay(clock.getZone()).toEpochSecond();
        long nowEpoch = Instant.now(clock).getEpochSecond();

        List<Map<String, Object>> roster = teachers.findStudents(teacherId, courseId);
        List<Map<String, Object>> taskRows = insights.findClassTaskStatus(teacherId, courseId);
        List<Map<String, Object>> engagementRows = insights.findClassEngagementByWeek(teacherId, courseId, since);
        List<Map<String, Object>> completionRows = insights.findClassCompletionsByWeek(teacherId, courseId, since);
        List<Map<String, Object>> activities = new ArrayList<>(teachers.findActivities(teacherId, courseId, "assignment"));
        activities.addAll(teachers.findActivities(teacherId, courseId, "quiz"));

        Map<String, Object> groups = watchGroups(roster);
        List<Map<String, Object>> attention = attentionStudents(roster);
        List<Map<String, Object>> students = studentDetails(roster);
        attachTasks(students, insights.findClassTasks(teacherId, courseId));
        List<Map<String, Object>> studentWeeks = insights.findStudentEventsByWeek(teacherId, courseId, since);
        List<Map<String, Object>> notes = insights.findNoteFollowUps(teacherId, courseId);
        List<Map<String, Object>> lowActivities = lowCompletionActivities(activities, nowEpoch);
        Map<String, Object> tasks = taskDistribution(taskRows);
        Map<String, Object> weekly = weekly(engagementRows, completionRows, firstWeek, today, roster.size());

        Map<String, Object> summary = new LinkedHashMap<>();
        summary.put("student_count", roster.size());
        summary.put("average_progress", round1(mean(roster, "progress")));
        summary.put("average_grade_percentage", round1(mean(roster, "average_grade")));
        summary.put("average_attendance", round1(mean(roster, "attendance")));
        // Denominators, so the app can say what each average is taken over.
        summary.put("progress_student_count", roster.stream().filter(s -> num(s.get("progress")) != null).count());
        summary.put("graded_student_count", roster.stream().filter(s -> num(s.get("average_grade")) != null).count());
        summary.put("tracked_activities", roster.stream().mapToLong(s -> lng(s.get("total_tracked_activities"))).max().orElse(0));
        summary.put("watch_count", lng(groups.get("watch")) + lng(groups.get("needs_support")));
        summary.put("activity_view_tracking", insights.hasActivityViewLogs(courseId));

        Map<String, Object> out = new LinkedHashMap<>();
        out.put("teacher_id", teacherId);
        out.put("course_id", courseId);
        out.put("generated_at", Instant.now(clock).toString());
        out.put("timezone", clock.getZone().getId());
        out.put("weeks", weeks);
        out.put("range_start", firstWeek.toString());
        out.put("range_end", today.toString());
        out.put("data_mode", dataMode);
        out.put("data_notice", "demo".equals(dataMode)
            ? "Dữ liệu minh họa từ môi trường phát triển, không phải kết quả học tập thật." : null);
        out.put("summary", summary);
        out.put("progress_distribution", progressDistribution(roster));
        out.put("watch_groups", groups);
        out.put("watch_criteria", WATCH_CRITERIA);
        out.put("attention_students", attention);
        out.put("students", students);
        out.put("signal_counts", signalCounts(students));
        Map<String, Object> heatmap = activityHeatmap(students, studentWeeks, firstWeek, today);
        Map<String, Object> followUps = supportFollowUps(notes, nowEpoch);
        long weekAgo = nowEpoch - 7 * DAY;
        out.put("weekly_change", weeklyChange(students, insights.findStudentStateAt(teacherId, courseId, weekAgo),
            weekAgo, mean(roster, "progress")));
        out.put("action_items", actionItems(students, activities, heatmap, followUps, notes, nowEpoch));
        out.put("activity_heatmap", heatmap);
        out.put("support_followups", followUps);
        out.put("task_status", tasks);
        out.put("weekly_trend", weekly);
        out.put("low_completion_activities", lowActivities);
        out.put("suggested_interventions", interventions(groups, tasks, lowActivities));
        return out;
    }

    /** Mirrors the scoring in derived.student_risk_indicator so teachers can verify a label. */
    static final List<String> WATCH_CRITERIA = List.of(
        "Không hoạt động 7–13 ngày: +25 điểm; từ 14 ngày: +40 điểm",
        "1–2 việc quá hạn: +15 điểm; từ 3 việc: +30 điểm",
        "Tiến độ dưới 30%: +25 điểm; dưới 60%: +10 điểm",
        "Không có sự kiện học tập trong 7 ngày: +10 điểm",
        "Từ 30 điểm: cần theo dõi; từ 60 điểm: cần hỗ trợ sớm");

    static List<Map<String, Object>> progressDistribution(List<Map<String, Object>> roster) {
        String[] labels = {"0–24%", "25–49%", "50–74%", "75–100%"};
        long[] counts = new long[4];
        long noData = 0;
        for (Map<String, Object> s : roster) {
            Double p = num(s.get("progress"));
            if (p == null) {
                noData++;
                continue;
            }
            counts[p < 25 ? 0 : p < 50 ? 1 : p < 75 ? 2 : 3]++;
        }
        List<Map<String, Object>> out = new ArrayList<>();
        for (int i = 0; i < 4; i++) out.add(Map.of("label", labels[i], "students", counts[i]));
        if (noData > 0) out.add(Map.of("label", "Chưa có dữ liệu", "students", noData));
        return out;
    }

    static Map<String, Object> watchGroups(List<Map<String, Object>> roster) {
        long onTrack = 0, watch = 0, support = 0, unknown = 0;
        for (Map<String, Object> s : roster) {
            switch (str(s.get("risk_level")) == null ? "" : str(s.get("risk_level")).toUpperCase()) {
                case "LOW" -> onTrack++;
                case "MEDIUM" -> watch++;
                case "HIGH" -> support++;
                default -> unknown++;
            }
        }
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("on_track", onTrack);
        out.put("watch", watch);
        out.put("needs_support", support);
        out.put("unknown", unknown);
        out.put("unit", "sinh viên");
        return out;
    }

    static List<Map<String, Object>> attentionStudents(List<Map<String, Object>> roster) {
        List<Map<String, Object>> picked = new ArrayList<>();
        for (Map<String, Object> s : roster) {
            String risk = str(s.get("risk_level")) == null ? "" : str(s.get("risk_level")).toUpperCase();
            if (!risk.equals("MEDIUM") && !risk.equals("HIGH")) continue;
            List<String> reasons = new ArrayList<>(), actions = new ArrayList<>();
            long overdue = lng(s.get("overdue_tasks"));
            Double progress = num(s.get("progress"));
            Object inactive = s.get("days_since_last_activity");
            if (overdue > 0) {
                reasons.add(overdue + " bài đã quá hạn");
                actions.add("Nhắc sinh viên về các bài đã quá hạn và hỏi về khó khăn khi hoàn thành");
            }
            if (inactive instanceof Number n && n.intValue() >= 7) {
                reasons.add(n.intValue() + " ngày chưa hoạt động");
                actions.add("Liên hệ để biết sinh viên có gặp khó khăn khi truy cập khóa học không");
            }
            if (progress != null && progress < 30) {
                reasons.add("Tiến độ học tập dưới 30%");
                actions.add("Gợi ý nội dung hoặc tài liệu nên xem trước để theo kịp lớp");
            } else if (progress != null && progress < 60) {
                reasons.add("Tiến độ học tập còn thấp");
            }
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("userid", s.get("userid"));
            m.put("fullname", s.get("fullname"));
            m.put("student_code", s.get("student_code"));
            m.put("risk_level", risk);
            m.put("progress", num(s.get("progress")));
            m.put("overdue_tasks", overdue);
            m.put("days_since_last_activity", inactive);
            m.put("reasons", reasons);
            m.put("suggested_actions", actions);
            if (reasons.isEmpty()) {
                m.put("note", "Mức theo dõi do hệ thống tính; chưa xác định được nguyên nhân cụ thể từ dữ liệu hiện có.");
            }
            picked.add(m);
        }
        picked.sort(Comparator
            .comparingInt((Map<String, Object> m) -> "HIGH".equals(m.get("risk_level")) ? 0 : 1)
            .thenComparing(m -> -lng(m.get("overdue_tasks"))));
        return picked.size() > MAX_ATTENTION_STUDENTS ? new ArrayList<>(picked.subList(0, MAX_ATTENTION_STUDENTS)) : picked;
    }

    static String group(Object riskLevel) {
        return switch (str(riskLevel) == null ? "" : str(riskLevel).toUpperCase()) {
            case "LOW" -> "on_track";
            case "MEDIUM" -> "watch";
            case "HIGH" -> "needs_support";
            default -> "unknown";
        };
    }

    private static final List<String> GROUP_ORDER = List.of("needs_support", "watch", "unknown", "on_track");

    /**
     * Every enrolled student with the observable numbers behind the label, so a teacher can tap a
     * chart segment and see who is in it and why. Signals describe data; they never judge ability.
     */
    static List<Map<String, Object>> studentDetails(List<Map<String, Object>> roster) {
        List<Map<String, Object>> out = new ArrayList<>();
        for (Map<String, Object> s : roster) {
            Double progress = num(s.get("progress"));
            Double attendance = num(s.get("attendance"));
            Double grade = num(s.get("average_grade"));
            Object inactive = s.get("days_since_last_activity");
            long overdue = lng(s.get("overdue_tasks"));
            long completed = lng(s.get("completed_tasks"));
            long total = lng(s.get("total_tasks"));
            long marked = lng(s.get("marked_sessions"));
            long absent = lng(s.get("absent_sessions"));

            List<Map<String, Object>> signals = new ArrayList<>();
            List<String> actions = new ArrayList<>();
            if (marked > 0 && absent > 0) {
                double rate = absent * 100.0 / marked;
                signals.add(signal("ABSENCE", "Vắng " + absent + "/" + marked + " buổi (" + Math.round(rate) + "%)",
                    rate >= ABSENCE_RATE));
                if (rate >= ABSENCE_RATE) actions.add("Trao đổi về lý do vắng học và nhắc quy định chuyên cần");
            }
            if (inactive == null) {
                signals.add(signal("NEVER_ACCESSED", "Chưa từng truy cập môn học", true));
                actions.add("Kiểm tra sinh viên đã vào được khóa học trên LMS chưa");
            } else if (inactive instanceof Number n && n.intValue() >= INACTIVE_DAYS) {
                signals.add(signal("INACTIVE", n.intValue() + " ngày chưa truy cập", n.intValue() >= 14));
                actions.add("Liên hệ để biết sinh viên có gặp khó khăn khi truy cập khóa học không");
            }
            if (overdue > 0) {
                signals.add(signal("OVERDUE", total > 0 ? "Quá hạn " + overdue + "/" + total + " bài" : overdue + " bài quá hạn",
                    overdue >= 3));
                actions.add("Nhắc sinh viên về các bài đã quá hạn và hỏi về khó khăn khi hoàn thành");
            }
            if (progress != null && progress < 60) {
                signals.add(signal("LOW_PROGRESS", "Tiến độ " + Math.round(progress) + "%", progress < 30));
                if (progress < 30) actions.add("Gợi ý nội dung hoặc tài liệu nên xem trước để theo kịp lớp");
            }
            if (grade != null && grade < LOW_GRADE) {
                signals.add(signal("LOW_GRADE", "Điểm TB " + Math.round(grade) + "%", true));
                actions.add("Xem lại các bài có điểm thấp và gợi ý ôn tập");
            }

            Map<String, Object> m = new LinkedHashMap<>();
            m.put("userid", s.get("userid"));
            m.put("fullname", s.get("fullname"));
            m.put("student_code", s.get("student_code"));
            m.put("class_code", s.get("class_code"));
            m.put("group", group(s.get("risk_level")));
            m.put("risk_level", str(s.get("risk_level")) == null ? null : str(s.get("risk_level")).toUpperCase());
            m.put("risk_score", s.get("risk_score") instanceof Number n ? n.intValue() : null);
            m.put("progress", round1(progress));
            m.put("attendance", round1(attendance));
            m.put("marked_sessions", marked);
            m.put("absent_sessions", absent);
            m.put("days_since_last_activity", inactive);
            m.put("events_last_7_days", lng(s.get("events_last_7_days")));
            m.put("completed_tasks", completed);
            m.put("total_tasks", total);
            m.put("overdue_tasks", overdue);
            m.put("average_grade", round1(grade));
            m.put("graded_items", lng(s.get("graded_items")));
            m.put("completed_activities", lng(s.get("completed_activities")));
            m.put("total_tracked_activities", lng(s.get("total_tracked_activities")));
            m.put("score_breakdown", scoreBreakdown(inactive, overdue, progress, lng(s.get("events_last_7_days"))));
            m.put("signals", signals);
            m.put("suggested_actions", actions);
            out.add(m);
        }
        out.sort(Comparator
            .comparingInt((Map<String, Object> m) -> GROUP_ORDER.indexOf(m.get("group")))
            .thenComparing(m -> -lng(m.get("risk_score")))
            .thenComparing(m -> -lng(m.get("overdue_tasks")))
            .thenComparing(m -> str(m.get("fullname")) == null ? "" : str(m.get("fullname"))));
        return out;
    }

    /**
     * Why a student has their risk_score: the same four rules as derived.student_risk_indicator,
     * applied to the same columns, so the points shown add up to the stored score (capped at 100).
     */
    static List<Map<String, Object>> scoreBreakdown(Object inactive, long overdue, Double progress, long events7d) {
        // Shared with the student's own learning health (V2-N9) so both sides always agree.
        return RiskScore.breakdown(inactive, overdue, progress, events7d);
    }

    static final double ABSENCE_RATE = 20.0, LOW_GRADE = 50.0;
    static final int INACTIVE_DAYS = 7;

    /** How many students show each strong signal; drives the "theo tiêu chí" filter chips. */
    static Map<String, Object> signalCounts(List<Map<String, Object>> students) {
        Map<String, Object> out = new LinkedHashMap<>();
        for (String code : List.of("ABSENCE", "INACTIVE", "OVERDUE", "LOW_PROGRESS", "LOW_GRADE")) {
            long n = students.stream().filter(s -> hasSignal(s, code)).count();
            out.put(code, n);
        }
        return out;
    }

    /** INACTIVE also covers students who never opened the course; ABSENCE counts only from 20%. */
    @SuppressWarnings("unchecked")
    static boolean hasSignal(Map<String, Object> student, String code) {
        for (Map<String, Object> sig : (List<Map<String, Object>>) student.get("signals")) {
            String c = str(sig.get("code"));
            if (!code.equals(c) && !("INACTIVE".equals(code) && "NEVER_ACCESSED".equals(c))) continue;
            return !"ABSENCE".equals(code) || Boolean.TRUE.equals(sig.get("strong"));
        }
        return false;
    }

    private static Map<String, Object> signal(String code, String label, boolean strong) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("code", code);
        m.put("label", label);
        m.put("strong", strong);
        return m;
    }

    /**
     * Gives each student the names of their assignments/quizzes and each one's status, so a
     * "đã nộp" or "quá hạn" list can say which work it means rather than only how much.
     */
    static void attachTasks(List<Map<String, Object>> students, List<Map<String, Object>> rows) {
        Map<Long, List<Map<String, Object>>> byStudent = new HashMap<>();
        for (Map<String, Object> r : rows) {
            Map<String, Object> t = new LinkedHashMap<>();
            t.put("source_id", r.get("source_id"));
            t.put("title", r.get("title"));
            t.put("task_type", r.get("task_type"));
            t.put("status", r.get("task_status"));
            long due = lng(r.get("due_time"));
            long submitted = lng(r.get("submitted_at"));
            boolean done = "completed".equals(r.get("task_status"));
            t.put("due_time", due > 0 ? due : null);
            t.put("submitted_at", done && submitted > 0 ? submitted : null);
            t.put("late", done && due > 0 && submitted > due);
            t.put("viewed", Boolean.TRUE.equals(r.get("viewed")));
            t.put("graded", Boolean.TRUE.equals(r.get("graded")));
            t.put("grade_percentage", round1(num(r.get("grade_percentage"))));
            t.put("passed", r.get("passed"));
            byStudent.computeIfAbsent(lng(r.get("userid")), k -> new ArrayList<>()).add(t);
        }
        for (Map<String, Object> s : students) {
            s.put("tasks", byStudent.getOrDefault(lng(s.get("userid")), List.of()));
        }
    }

    static final long DAY = 86400;

    static String groupForScore(int score) {
        return RiskScore.group(score);
    }

    /**
     * The watch score a student had at {@code asOf}, rebuilt from Moodle history with the same
     * rules as derived.student_risk_indicator: last log event before then, assignments/quizzes
     * past due and not handed in by then, tracked activities completed by then, and events in
     * the 7 days before. Activity counts are today's, so it is an estimate, not a snapshot.
     */
    static int scoreAt(Map<String, Object> student, Map<String, Object> state, long asOf) {
        Object inactive = state != null && state.get("last_event") instanceof Number last
            ? (int) Math.floor((asOf - last.longValue()) / (double) DAY) : null;
        long overdue = overdueAt(student, asOf);
        long total = lng(student.get("total_tracked_activities"));
        double progress = total == 0 ? 0 : lng(state == null ? null : state.get("completed_activities")) * 100.0 / total;
        long events = lng(state == null ? null : state.get("events_7d"));
        int sum = scoreBreakdown(inactive, overdue, progress, events).stream()
            .mapToInt(p -> ((Number) p.get("points")).intValue()).sum();
        return Math.min(100, sum);
    }

    private static final List<String> URGENCY = List.of("needs_support", "watch", "on_track", "unknown");

    /** Compares each student's group now with the group rebuilt for 7 days ago. */
    static Map<String, Object> weeklyChange(List<Map<String, Object>> students, List<Map<String, Object>> stateRows,
                                            long asOf, Double currentAverageProgress) {
        Map<Long, Map<String, Object>> state = new HashMap<>();
        for (Map<String, Object> r : stateRows) state.put(lng(r.get("userid")), r);
        Map<String, Long> before = new LinkedHashMap<>(), now = new LinkedHashMap<>();
        for (String g : List.of("needs_support", "watch", "on_track")) {
            before.put(g, 0L);
            now.put(g, 0L);
        }
        List<Map<String, Object>> worse = new ArrayList<>(), better = new ArrayList<>();
        double progressSum = 0;
        long progressCount = 0, overdueBefore = 0, overdueNow = 0;
        for (Map<String, Object> s : students) {
            Map<String, Object> st = state.get(lng(s.get("userid")));
            int score = scoreAt(s, st, asOf);
            String was = groupForScore(score), is = str(s.get("group"));
            before.merge(was, 1L, Long::sum);
            if (now.containsKey(is)) now.merge(is, 1L, Long::sum);
            s.put("previous_group", was);
            s.put("previous_risk_score", score);
            long total = lng(s.get("total_tracked_activities"));
            if (total > 0 && st != null) {
                progressSum += lng(st.get("completed_activities")) * 100.0 / total;
                progressCount++;
            }
            if (lng(s.get("overdue_tasks")) > 0) overdueNow++;
            if (overdueAt(s, asOf) > 0) overdueBefore++;
            if (is == null || "unknown".equals(is) || is.equals(was)) continue;
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("userid", s.get("userid"));
            m.put("fullname", s.get("fullname"));
            m.put("from", was);
            m.put("to", is);
            m.put("score_before", score);
            m.put("score_now", s.get("risk_score"));
            (URGENCY.indexOf(is) < URGENCY.indexOf(was) ? worse : better).add(m);
        }
        Map<String, Object> prev = new LinkedHashMap<>(before), cur = new LinkedHashMap<>(now);
        prev.put("average_progress", progressCount == 0 ? null : round1(progressSum / progressCount));
        cur.put("average_progress", round1(currentAverageProgress));
        prev.put("overdue_students", overdueBefore);
        cur.put("overdue_students", overdueNow);
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("as_of", Instant.ofEpochSecond(asOf).toString());
        out.put("previous", prev);
        out.put("current", cur);
        out.put("worsened", worse);
        out.put("improved", better);
        return out;
    }

    /**
     * Assignments/quizzes already past due at {@code asOf} and not handed in by then. A completed
     * task without a hand-in time counts as done, since when it was done cannot be told.
     */
    private static long overdueAt(Map<String, Object> student, long asOf) {
        long n = 0;
        for (Object o : student.get("tasks") instanceof List<?> l ? l : List.of()) {
            if (!(o instanceof Map<?, ?> t)) continue;
            long due = lng(t.get("due_time"));
            if (due <= 0 || due >= asOf) continue;
            if (!"completed".equals(t.get("status"))
                || (t.get("submitted_at") != null && lng(t.get("submitted_at")) > asOf)) n++;
        }
        return n;
    }

    static final int DEADLINE_SOON_DAYS = 3, RECENT_OVERDUE_DAYS = 14, CONTACT_GAP_DAYS = 14, MAX_ACTION_ITEMS = 6;
    static final double REVIEW_LATE_RATE = 30.0, REVIEW_MISSING_RATE = 50.0;

    /**
     * This week's to-do list for the teacher, most urgent first. Each item carries the
     * students it concerns so the app can act on it (remind, open the list, open Moodle);
     * the wording is left to the app.
     */
    static List<Map<String, Object>> actionItems(List<Map<String, Object>> students, List<Map<String, Object>> activities,
                                                 Map<String, Object> heatmap, Map<String, Object> followUps,
                                                 List<Map<String, Object>> notes, long now) {
        Map<Long, Long> lastContact = new HashMap<>();
        for (Map<String, Object> n : notes) lastContact.merge(lng(n.get("student_id")), lng(n.get("note_epoch")), Math::max);
        java.util.function.Predicate<Long> notContactedRecently =
            id -> !lastContact.containsKey(id) || lastContact.get(id) < now - CONTACT_GAP_DAYS * DAY;

        List<Map<String, Object>> out = new ArrayList<>();
        for (Map<String, Object> a : activities) {
            long due = lng(a.get("due_time"));
            String type = str(a.get("task_type"));
            long sourceId = lng(a.get("source_id"));
            List<Long> missing = new ArrayList<>();
            long assigned = 0, late = 0;
            for (Map<String, Object> s : students) {
                for (Object o : s.get("tasks") instanceof List<?> l ? l : List.of()) {
                    if (!(o instanceof Map<?, ?> t) || lng(t.get("source_id")) != sourceId
                        || !Objects.equals(t.get("task_type"), type)) continue;
                    assigned++;
                    if (!"completed".equals(t.get("status"))) missing.add(lng(s.get("userid")));
                    else if (Boolean.TRUE.equals(t.get("late"))) late++;
                }
            }
            if (assigned == 0) continue;
            if (due > now && due <= now + DEADLINE_SOON_DAYS * DAY && !missing.isEmpty()) {
                out.add(item("DEADLINE_SOON", 1, "REMIND", missing, a, (due - now + DAY - 1) / DAY));
            } else if (due > 0 && due <= now && due >= now - RECENT_OVERDUE_DAYS * DAY && !missing.isEmpty()) {
                out.add(item("RECENTLY_OVERDUE", 2, "REMIND", missing, a, (now - due) / DAY));
            }
            if (due > 0 && due <= now) {
                double lateRate = late * 100.0 / assigned, missingRate = missing.size() * 100.0 / assigned;
                if (lateRate >= REVIEW_LATE_RATE || missingRate >= REVIEW_MISSING_RATE) {
                    Map<String, Object> m = item("REVIEW_ACTIVITY", 5, "REVIEW", missing, a, null);
                    m.put("late_rate", round1(lateRate));
                    m.put("missing_rate", round1(missingRate));
                    out.add(m);
                }
            }
        }

        Set<Long> listed = new HashSet<>();
        List<Long> stopped = new ArrayList<>();
        for (Object o : heatmap.get("rows") instanceof List<?> l ? l : List.of()) {
            if (o instanceof Map<?, ?> r && !"active".equals(r.get("status")) && notContactedRecently.test(lng(r.get("userid")))) {
                stopped.add(lng(r.get("userid")));
            }
        }
        if (!stopped.isEmpty()) {
            out.add(item("STOPPED_LEARNING", 3, "CONTACT", stopped, null, null));
            listed.addAll(stopped);
        }

        List<Long> retry = new ArrayList<>();
        for (Object o : followUps.get("items") instanceof List<?> l ? l : List.of()) {
            if (!(o instanceof Map<?, ?> f) || !"NO_CHANGE".equals(f.get("outcome"))) continue;
            long id = lng(f.get("student_id"));
            // Only when that note is still the latest contact with the student.
            long at = Instant.parse(str(f.get("noted_at"))).getEpochSecond();
            if (Objects.equals(lastContact.get(id), at) && !listed.contains(id) && !retry.contains(id)) retry.add(id);
        }
        if (!retry.isEmpty()) {
            out.add(item("NO_CHANGE_AFTER_SUPPORT", 4, "CONTACT", retry, null, null));
            listed.addAll(retry);
        }

        List<Long> uncontacted = new ArrayList<>();
        for (Map<String, Object> s : students) {
            long id = lng(s.get("userid"));
            if ("needs_support".equals(s.get("group")) && !listed.contains(id) && notContactedRecently.test(id)) {
                uncontacted.add(id);
            }
        }
        if (!uncontacted.isEmpty()) out.add(item("NEEDS_SUPPORT_UNCONTACTED", 4, "CONTACT", uncontacted, null, null));

        out.sort(Comparator
            .comparingInt((Map<String, Object> m) -> (Integer) m.get("priority"))
            .thenComparing(m -> -((List<?>) m.get("student_ids")).size()));
        return out.size() > MAX_ACTION_ITEMS ? new ArrayList<>(out.subList(0, MAX_ACTION_ITEMS)) : out;
    }

    private static Map<String, Object> item(String code, int priority, String action, List<Long> studentIds,
                                            Map<String, Object> activity, Long days) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("code", code);
        m.put("priority", priority);
        m.put("action", action);
        m.put("student_ids", studentIds);
        m.put("days", days);
        if (activity != null) {
            Map<String, Object> a = new LinkedHashMap<>();
            a.put("source_id", activity.get("source_id"));
            a.put("task_type", activity.get("task_type"));
            a.put("title", activity.get("title"));
            long due = lng(activity.get("due_time"));
            a.put("due_time", due > 0 ? due : null);
            a.put("coursemoduleid", activity.get("coursemoduleid"));
            a.put("moodle_path", activity.get("moodle_path"));
            m.put("activity", a);
        }
        return m;
    }

    /** Full weeks of silence (current week also silent) after which a student counts as having stopped. */
    static final int DROP_OFF_WEEKS = 2;

    /**
     * Student × week activity matrix for spotting who stopped learning and since when.
     * "dropped": active earlier in the range, but silent for the last {@link #DROP_OFF_WEEKS}
     * full weeks and so far this week. "never_active": no event in the whole range.
     */
    static Map<String, Object> activityHeatmap(List<Map<String, Object>> students, List<Map<String, Object>> rows,
                                               LocalDate firstWeek, LocalDate today) {
        List<LocalDate> weeks = new ArrayList<>();
        for (LocalDate w = firstWeek; !w.isAfter(today); w = w.plusWeeks(1)) weeks.add(w);
        Map<Long, long[]> byStudent = new HashMap<>();
        for (Map<String, Object> r : rows) {
            int i = weeks.indexOf(date(r.get("week_start")));
            if (i < 0) continue;
            byStudent.computeIfAbsent(lng(r.get("userid")), k -> new long[weeks.size()])[i] += lng(r.get("events"));
        }
        List<Map<String, Object>> out = new ArrayList<>();
        long max = 0, dropped = 0, never = 0;
        for (Map<String, Object> s : students) {
            long[] counts = byStudent.getOrDefault(lng(s.get("userid")), new long[weeks.size()]);
            long total = 0;
            int lastActive = -1;
            List<Long> series = new ArrayList<>();
            for (int i = 0; i < counts.length; i++) {
                series.add(counts[i]);
                total += counts[i];
                max = Math.max(max, counts[i]);
                if (counts[i] > 0) lastActive = i;
            }
            int silentFullWeeks = weeks.size() - 2 - lastActive;
            String status = total == 0 ? "never_active"
                : lastActive < weeks.size() - 1 && silentFullWeeks >= DROP_OFF_WEEKS ? "dropped" : "active";
            if (status.equals("dropped")) dropped++;
            if (status.equals("never_active")) never++;
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("userid", s.get("userid"));
            m.put("fullname", s.get("fullname"));
            m.put("student_code", s.get("student_code"));
            m.put("group", s.get("group"));
            m.put("weekly_events", series);
            m.put("total_events", total);
            m.put("status", status);
            m.put("last_active_week", lastActive >= 0 ? weeks.get(lastActive).toString() : null);
            m.put("dropped_since", status.equals("dropped") ? weeks.get(lastActive + 1).toString() : null);
            out.add(m);
        }
        Map<String, Integer> rank = Map.of("dropped", 0, "never_active", 1, "active", 2);
        out.sort(Comparator
            .comparingInt((Map<String, Object> m) -> rank.get(str(m.get("status"))))
            .thenComparing(m -> str(m.get("last_active_week")) == null ? "" : str(m.get("last_active_week")))
            .thenComparingLong(m -> lng(m.get("total_events"))));
        Map<String, Object> heat = new LinkedHashMap<>();
        heat.put("weeks", weeks.stream().map(LocalDate::toString).toList());
        heat.put("max_events", max);
        heat.put("dropped_count", dropped);
        heat.put("never_active_count", never);
        heat.put("drop_off_weeks", DROP_OFF_WEEKS);
        heat.put("rows", out);
        return heat;
    }

    static final int FOLLOW_UP_DAYS = 7;

    /**
     * Did students come back after the teacher recorded a support note? Compares log activity
     * in the 7 days before and after each note. It shows what changed, not what caused it.
     */
    static Map<String, Object> supportFollowUps(List<Map<String, Object>> notes, long nowEpoch) {
        List<Map<String, Object>> items = new ArrayList<>();
        long returned = 0, noChange = 0, waiting = 0, daysSum = 0, beforeSum = 0, afterSum = 0, evaluated = 0;
        for (Map<String, Object> n : notes) {
            long at = lng(n.get("note_epoch"));
            long before = lng(n.get("events_before")), after = lng(n.get("events_after"));
            long daysSince = Math.max(0, (nowEpoch - at) / 86400);
            String outcome = after > 0 ? "RETURNED" : daysSince >= FOLLOW_UP_DAYS ? "NO_CHANGE" : "WAITING";
            Long daysToReturn = n.get("first_return") instanceof Number f ? (f.longValue() - at) / 86400 : null;
            switch (outcome) {
                case "RETURNED" -> {
                    returned++;
                    if (daysToReturn != null) daysSum += daysToReturn;
                }
                case "NO_CHANGE" -> noChange++;
                default -> waiting++;
            }
            if (!outcome.equals("WAITING")) {
                evaluated++;
                beforeSum += before;
                afterSum += after;
            }
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", n.get("id"));
            m.put("student_id", n.get("student_id"));
            m.put("fullname", n.get("fullname"));
            m.put("student_code", n.get("student_code"));
            m.put("note", n.get("note"));
            m.put("kind", str(n.get("note")) != null && str(n.get("note")).startsWith(TeacherReminderService.NOTE_PREFIX)
                ? "reminder" : "note");
            m.put("noted_at", Instant.ofEpochSecond(at).toString());
            m.put("days_since", daysSince);
            m.put("events_before", before);
            m.put("events_after", after);
            m.put("outcome", outcome);
            m.put("days_to_return", outcome.equals("RETURNED") ? daysToReturn : null);
            items.add(m);
        }
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("window_days", FOLLOW_UP_DAYS);
        out.put("total", notes.size());
        out.put("returned", returned);
        out.put("no_change", noChange);
        out.put("waiting", waiting);
        out.put("return_rate", returned + noChange == 0 ? null : round1(returned * 100.0 / (returned + noChange)));
        out.put("average_days_to_return", returned == 0 ? null : round1(daysSum * 1.0 / returned));
        out.put("average_events_before", evaluated == 0 ? null : round1(beforeSum * 1.0 / evaluated));
        out.put("average_events_after", evaluated == 0 ? null : round1(afterSum * 1.0 / evaluated));
        out.put("items", items);
        return out;
    }

    static Map<String, Object> taskDistribution(List<Map<String, Object>> rows) {
        long completed = 0, pending = 0, overdue = 0;
        for (Map<String, Object> r : rows) {
            long n = lng(r.get("tasks"));
            switch (str(r.get("task_status")) == null ? "" : str(r.get("task_status"))) {
                case "completed" -> completed += n;
                case "overdue" -> overdue += n;
                case "pending" -> pending += n;
                default -> {
                }
            }
        }
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("total", completed + pending + overdue);
        out.put("completed", completed);
        out.put("pending", pending);
        out.put("overdue", overdue);
        out.put("unit", "lượt giao bài (sinh viên × bài tập/bài kiểm tra)");
        return out;
    }

    static Map<String, Object> weekly(List<Map<String, Object>> engagement, List<Map<String, Object>> completions,
                                      LocalDate firstWeek, LocalDate today, int studentCount) {
        Map<LocalDate, Map<String, Object>> eng = new HashMap<>();
        for (Map<String, Object> r : engagement) {
            LocalDate d = date(r.get("week_start"));
            if (d != null) eng.put(d, r);
        }
        Map<LocalDate, Long> comp = new HashMap<>();
        for (Map<String, Object> r : completions) {
            LocalDate d = date(r.get("week_start"));
            if (d != null) comp.merge(d, lng(r.get("completed_activities")), Long::sum);
        }
        List<Map<String, Object>> points = new ArrayList<>();
        long totalEvents = 0, totalCompleted = 0;
        for (LocalDate w = firstWeek; !w.isAfter(today); w = w.plusWeeks(1)) {
            Map<String, Object> e = eng.get(w);
            long active = e == null ? 0 : lng(e.get("active_students"));
            long events = e == null ? 0 : lng(e.get("events"));
            long done = comp.getOrDefault(w, 0L);
            totalEvents += events;
            totalCompleted += done;
            Map<String, Object> p = new LinkedHashMap<>();
            p.put("week_start", w.toString());
            p.put("active_students", active);
            p.put("events", events);
            p.put("completed_activities", done);
            points.add(p);
        }
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("student_count", studentCount);
        out.put("engagement_available", totalEvents > 0);
        out.put("completion_available", totalCompleted > 0);
        out.put("engagement_unit", "số sinh viên có hoạt động trong tuần");
        out.put("completion_unit", "số hoạt động được hoàn thành trong tuần");
        out.put("points", points);
        return out;
    }

    static List<Map<String, Object>> lowCompletionActivities(List<Map<String, Object>> activities, long nowEpoch) {
        List<Map<String, Object>> out = new ArrayList<>();
        for (Map<String, Object> a : activities) {
            long students = lng(a.get("student_count"));
            if (students <= 0) continue;
            double rate = lng(a.get("done_count")) * 100.0 / students;
            if (rate >= LOW_COMPLETION_RATE) continue;
            long due = lng(a.get("due_time"));
            boolean duePassed = due > 0 && due < nowEpoch;
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("source_id", a.get("source_id"));
            m.put("task_type", a.get("task_type"));
            m.put("title", a.get("title"));
            m.put("due_time", due > 0 ? due : null);
            m.put("due_passed", duePassed);
            m.put("student_count", students);
            m.put("done_count", lng(a.get("done_count")));
            m.put("completion_rate", round1(rate));
            m.put("coursemoduleid", a.get("coursemoduleid"));
            m.put("moodle_path", a.get("moodle_path"));
            m.put("note", duePassed ? null : "Chưa đến hạn nên tỷ lệ thấp có thể là bình thường.");
            out.add(m);
        }
        out.sort(Comparator
            .comparingInt((Map<String, Object> m) -> Boolean.TRUE.equals(m.get("due_passed")) ? 0 : 1)
            .thenComparingDouble(m -> num(m.get("completion_rate"))));
        return out.size() > MAX_LOW_ACTIVITIES ? new ArrayList<>(out.subList(0, MAX_LOW_ACTIVITIES)) : out;
    }

    static List<Map<String, Object>> interventions(Map<String, Object> groups, Map<String, Object> tasks,
                                                   List<Map<String, Object>> lowActivities) {
        List<Map<String, Object>> out = new ArrayList<>();
        long support = lng(groups.get("needs_support")), watch = lng(groups.get("watch"));
        if (support > 0) {
            out.add(intervention("CONTACT_SUPPORT_GROUP", "Liên hệ " + support + " sinh viên cần hỗ trợ sớm",
                "Các sinh viên này đạt từ 60 điểm theo tiêu chí theo dõi. Mở danh sách để xem lý do từng người."));
        }
        if (watch > 0) {
            out.add(intervention("CHECK_IN_WATCH_GROUP", "Hỏi thăm " + watch + " sinh viên cần theo dõi",
                "Có dấu hiệu chậm tiến độ ở mức vừa; một lời nhắc ngắn thường là đủ."));
        }
        if (lng(tasks.get("overdue")) > 0) {
            out.add(intervention("REMIND_OVERDUE", "Nhắc cả lớp về " + lng(tasks.get("overdue")) + " lượt bài quá hạn",
                "Số lượt giao bài đã quá hạn nhưng chưa nộp hoặc chưa hoàn tất."));
        }
        for (Map<String, Object> a : lowActivities) {
            if (Boolean.TRUE.equals(a.get("due_passed"))) {
                out.add(intervention("REVIEW_LOW_ACTIVITY", "Xem lại \"" + a.get("title") + "\"",
                    "Chỉ " + a.get("completion_rate") + "% sinh viên hoàn thành sau hạn; có thể cần giải thích lại yêu cầu."));
                break;
            }
        }
        return out;
    }

    private static Map<String, Object> intervention(String code, String title, String reason) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("code", code);
        m.put("title", title);
        m.put("reason", reason);
        m.put("created_at", Instant.now().toString());
        return m;
    }

    private static Double mean(List<Map<String, Object>> rows, String column) {
        double sum = 0;
        int n = 0;
        for (Map<String, Object> r : rows) {
            Double v = num(r.get(column));
            if (v != null) {
                sum += v;
                n++;
            }
        }
        return n == 0 ? null : sum / n;
    }
}
