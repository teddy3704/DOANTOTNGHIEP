package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.config.DataProfile;
import org.springframework.beans.factory.annotation.Autowired;

import com.dlu.lmsmobile.exception.ResourceNotFoundException;
import com.dlu.lmsmobile.repository.LearningHealthRepository;
import org.springframework.stereotype.Service;

import java.util.*;

import static com.dlu.lmsmobile.service.Values.*;

/**
 * V2-N9 "my learning health": the same watch score and reasons a teacher sees, shown to the
 * student about themself only, plus up to three concrete actions that lower the score.
 */
@Service
public class LearningHealthService {
    static final int MAX_ACTIONS = 3;

    private final LearningHealthRepository repository;
    private final boolean handInsOnly;

    public LearningHealthService(LearningHealthRepository repository) {
        this(repository, DataProfile.demo());
    }

    @Autowired
    public LearningHealthService(LearningHealthRepository repository, DataProfile profile) {
        this.repository = repository;
        this.handInsOnly = profile.handInsOnly();
    }

    public Map<String, Object> overview(Long userId) {
        Map<Long, Map<String, Object>> next = nextByCourse(userId);
        List<Map<String, Object>> courses = new ArrayList<>();
        for (Map<String, Object> row : repository.findRiskRows(userId, null)) {
            courses.add(course(row, next.get(lng(row.get("courseid"))), handInsOnly));
        }
        courses.sort(Comparator.comparingInt((Map<String, Object> c) -> -((Number) c.get("score")).intValue())
            .thenComparing(c -> lng(c.get("courseId"))));
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("level", courses.isEmpty() ? null : courses.get(0).get("level"));
        out.put("counts", counts(courses));
        out.put("courses", courses);
        return out;
    }

    public Map<String, Object> forCourse(Long userId, Long courseId) {
        List<Map<String, Object>> rows = repository.findRiskRows(userId, courseId);
        if (rows.isEmpty()) throw new ResourceNotFoundException("Student course not found");
        return course(rows.get(0), nextByCourse(userId).get(courseId), handInsOnly);
    }

    private Map<Long, Map<String, Object>> nextByCourse(Long userId) {
        Map<Long, Map<String, Object>> out = new HashMap<>();
        for (Map<String, Object> r : repository.findNextActivities(userId)) out.put(lng(r.get("courseid")), r);
        return out;
    }

    // ------------------------------------------------------------------ pure

    /** GREEN / YELLOW / RED from the shared cut-offs (on_track / watch / needs_support). */
    static String level(int score) {
        return switch (RiskScore.group(score)) {
            case "needs_support" -> "RED";
            case "watch" -> "YELLOW";
            default -> "GREEN";
        };
    }

    static Map<String, Object> course(Map<String, Object> row, Map<String, Object> nextActivity) {
        return course(row, nextActivity, false);
    }

    static Map<String, Object> course(Map<String, Object> row, Map<String, Object> nextActivity, boolean handInsOnly) {
        Object inactive = row.get("days_since_last_activity");
        long overdue = lng(row.get("overdue_tasks"));
        Double progress = num(row.get("progress_percentage"));
        long events = lng(row.get("events_last_7_days"));
        List<Map<String, Object>> reasons = RiskScore.breakdown(inactive, overdue, progress, events, handInsOnly);
        int score = RiskScore.total(reasons);

        Map<String, Object> out = new LinkedHashMap<>();
        out.put("courseId", lng(row.get("courseid")));
        out.put("courseName", str(row.get("course_name")));
        out.put("score", score);
        // The stored score from the view, kept beside the recomputed one so any drift is visible.
        out.put("storedScore", row.get("risk_score") instanceof Number n ? n.intValue() : null);
        out.put("level", level(score));
        out.put("reasons", reasons);
        out.put("actions", actions(reasons, score, overdue, progress, lng(row.get("completed_activities")),
            lng(row.get("total_tracked_activities")), nextActivity, lng(row.get("courseid")), handInsOnly));
        Map<String, Object> metrics = new LinkedHashMap<>();
        metrics.put("daysSinceLastActivity", inactive);
        metrics.put("overdueTasks", overdue);
        metrics.put("progress", round1(progress));
        metrics.put("eventsLast7Days", events);
        out.put("metrics", metrics);
        return out;
    }

    /**
     * Up to three actions, biggest score reduction first. Each names its numbers and the screen
     * it opens: TASKS (course task list), OPEN_LMS (next unfinished activity), RECOMMENDATIONS (N2).
     */
    static List<Map<String, Object>> actions(List<Map<String, Object>> reasons, int score, long overdue, Double progress,
                                             long completed, long total, Map<String, Object> next, long courseId) {
        return actions(reasons, score, overdue, progress, completed, total, next, courseId, false);
    }

    /**
     * {@code handInsOnly} (real export): only a hand-in lowers the inactivity points, so the action
     * asks for one and only links an assignment/quiz, never a page or forum that would not change the score.
     */
    static List<Map<String, Object>> actions(List<Map<String, Object>> reasons, int score, long overdue, Double progress,
                                             long completed, long total, Map<String, Object> next, long courseId,
                                             boolean handInsOnly) {
        if (handInsOnly && next != null && !Set.of("assign", "quiz").contains(str(next.get("activity_type")))) next = null;
        List<Map<String, Object>> out = new ArrayList<>();
        if (score < RiskScore.WATCH) return out;
        List<Map<String, Object>> sorted = new ArrayList<>(reasons);
        sorted.sort(Comparator.comparingInt(r -> -((Number) r.get("points")).intValue()));
        for (Map<String, Object> r : sorted) {
            int pts = ((Number) r.get("points")).intValue();
            Map<String, Object> a = new LinkedHashMap<>();
            switch (String.valueOf(r.get("code"))) {
                case "OVERDUE" -> {
                    a.put("code", "CLEAR_OVERDUE");
                    a.put("title", "Hoàn thành " + overdue + " bài quá hạn");
                    a.put("target", "TASKS");
                }
                case "INACTIVE", "NO_RECENT_EVENTS" -> {
                    if (out.stream().anyMatch(x -> "VISIT_COURSE".equals(x.get("code")))) {
                        // One visit fixes both; merge the points instead of listing it twice.
                        out.stream().filter(x -> "VISIT_COURSE".equals(x.get("code"))).findFirst()
                            .ifPresent(x -> x.put("scoreDrop", ((Number) x.get("scoreDrop")).intValue() + pts));
                        continue;
                    }
                    a.put("code", "VISIT_COURSE");
                    if (handInsOnly) {
                        a.put("title", next == null ? "Nộp bài hoặc làm bài kiểm tra trên LMS"
                            : "Nộp bài hoặc làm bài: " + str(next.get("activity_name")));
                    } else {
                        a.put("title", next == null ? "Vào khóa học trên LMS hôm nay"
                            : "Vào học tiếp: " + str(next.get("activity_name")));
                    }
                    // Real export without a graded activity to open: lead to the course's task list instead
                    // of a disabled LMS button.
                    a.put("target", handInsOnly && next == null ? "TASKS" : "OPEN_LMS");
                    if (next != null) {
                        a.put("moodlePath", str(next.get("moodle_path")));
                        a.put("courseModuleId", lng(next.get("coursemoduleid")));
                    }
                }
                case "LOW_PROGRESS" -> {
                    double threshold = progress != null && progress < 30 ? 30 : 60;
                    long needed = total <= 0 ? 0 : Math.max(1, (long) Math.ceil(threshold * total / 100.0) - completed);
                    a.put("code", "RAISE_PROGRESS");
                    a.put("title", total > 0
                        ? "Hoàn thành thêm " + needed + " hoạt động để đạt " + Math.round(threshold) + "% tiến độ"
                        : "Hoàn thành thêm hoạt động của khóa học");
                    a.put("target", "RECOMMENDATIONS");
                }
                default -> {
                    continue;
                }
            }
            a.put("scoreDrop", pts);
            a.put("courseId", courseId);
            out.add(a);
        }
        // Merge first, then rank: a merged visit can outrank an action that came earlier.
        out.sort(Comparator.comparingInt(x -> -((Number) x.get("scoreDrop")).intValue()));
        return out.size() > MAX_ACTIONS ? new ArrayList<>(out.subList(0, MAX_ACTIONS)) : out;
    }

    static Map<String, Object> counts(List<Map<String, Object>> courses) {
        Map<String, Object> out = new LinkedHashMap<>();
        for (String l : List.of("RED", "YELLOW", "GREEN")) {
            out.put(l, courses.stream().filter(c -> l.equals(c.get("level"))).count());
        }
        return out;
    }
}
