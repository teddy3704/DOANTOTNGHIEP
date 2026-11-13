package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.config.DataProfile;
import org.springframework.beans.factory.annotation.Autowired;

import com.dlu.lmsmobile.exception.ResourceNotFoundException;
import com.dlu.lmsmobile.repository.ForecastRepository;
import com.dlu.lmsmobile.repository.InsightsRepository;
import com.dlu.lmsmobile.repository.StudentRepository;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.*;

import static com.dlu.lmsmobile.service.Values.*;

/**
 * V2-N2: links a weak chapter (section) to what to review in that same chapter. Pure logic in
 * {@link #recommend}; formulas are documented in docs/FEATURES_V2.md.
 */
@Service
public class StudyRecommendationService {
    /** A class average is only used when at least this many students have a grade on the item. */
    public static final int MIN_CLASS_SIZE = 5;
    static final double CLASS_GAP_POINTS = 10.0;
    static final int MAX_SUGGESTIONS = 3, MAX_LIMIT = 10;
    static final double OVERDUE_WEIGHT = 20.0;
    static final Set<String> GRADED = Set.of("assign", "quiz");
    static final Set<String> DONE = Set.of("completed", "submitted");
    private static final DateTimeFormatter DAY = DateTimeFormatter.ofPattern("dd/MM/yyyy")
        .withZone(ZoneId.of("Asia/Ho_Chi_Minh"));

    /** Class figures for one graded activity. */
    public record ClassStat(double average, long gradedCount) {
    }

    private final StudentRepository students;
    private final ForecastRepository grades;
    private final InsightsRepository insights;
    private final Clock clock;
    private final boolean trackedOnly;

    public StudyRecommendationService(StudentRepository students, ForecastRepository grades,
                                      InsightsRepository insights, Clock clock) {
        this(students, grades, insights, clock, DataProfile.demo());
    }

    @Autowired
    public StudyRecommendationService(StudentRepository students, ForecastRepository grades,
                                      InsightsRepository insights, Clock clock, DataProfile profile) {
        // Real export: completion of ungraded material (resource, url, forum...) is unknown, so it is
        // never called "chưa hoàn thành"; only graded (tracked) activities are.
        this.trackedOnly = profile.handInsOnly();
        this.students = students;
        this.grades = grades;
        this.insights = insights;
        this.clock = clock;
    }

    public Map<String, Object> forCourse(Long userId, Long courseId) {
        if (!insights.isEnrolled(userId, courseId)) throw new ResourceNotFoundException("Student course not found");
        return courseResult(userId, courseId, null);
    }

    /** Weak chapters across every enrolled course, most severe first. */
    public Map<String, Object> overall(Long userId, Integer limit) {
        int max = limit == null ? 3 : Math.max(1, Math.min(MAX_LIMIT, limit));
        List<Map<String, Object>> all = new ArrayList<>();
        for (Map<String, Object> c : students.findCoursesByUserId(userId)) {
            Long courseId = lng(c.get("courseid"));
            Map<String, Object> r = courseResult(userId, courseId, str(c.get("course_name")));
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> chapters = (List<Map<String, Object>>) r.get("chapters");
            for (Map<String, Object> ch : chapters) {
                Map<String, Object> m = new LinkedHashMap<>(ch);
                m.put("courseId", courseId);
                m.put("courseName", r.get("courseName"));
                all.add(m);
            }
        }
        all.sort(Comparator.comparingDouble((Map<String, Object> m) -> -((Number) m.get("severity")).doubleValue()));
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("total", all.size());
        out.put("chapters", all.size() > max ? all.subList(0, max) : all);
        return out;
    }

    private Map<String, Object> courseResult(Long userId, Long courseId, String courseName) {
        List<Map<String, Object>> items = students.findLearningItemsByUserIdAndCourseId(userId, courseId);
        List<Map<String, Object>> myGrades = students.findGradesByUserIdAndCourseId(userId, courseId);
        Map<String, ClassStat> stats = new HashMap<>();
        for (Map<String, Object> r : grades.findClassItemStats(courseId)) {
            stats.put(key(str(r.get("activity_type")), lng(r.get("source_id"))),
                new ClassStat(num(r.get("average_percentage")), lng(r.get("graded_count"))));
        }
        double pass = passPercent(myGrades);
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("courseId", courseId);
        out.put("courseName", courseName != null ? courseName
            : items.isEmpty() ? null : str(items.get(0).get("course_name")));
        out.put("passPercent", pass);
        out.put("chapters", recommend(items, myGrades, stats, pass, clock.instant().getEpochSecond(), trackedOnly));
        return out;
    }

    // ------------------------------------------------------------------ pure

    static String key(String type, long sourceId) {
        return type + ":" + sourceId;
    }

    static double passPercent(List<Map<String, Object>> myGrades) {
        List<GradeForecastService.Item> items = new ArrayList<>();
        for (Map<String, Object> g : myGrades) {
            items.add(new GradeForecastService.Item(lng(g.get("grade_item_id")), null, null, null, null, null, null,
                num(g.get("grademax")), num(g.get("gradepass")), null, false, null, null, null));
        }
        return GradeForecastService.passPercent(items)[0];
    }

    /**
     * Weak chapters with up to three suggestions each. A chapter is weak when (a) the mean of its
     * graded activities is below the pass threshold, (b) it trails the class mean of the same
     * activities by ≥10 points (only activities with ≥5 graded students), or (c) it has an overdue
     * graded activity that is not finished.
     */
    public static List<Map<String, Object>> recommend(List<Map<String, Object>> items, List<Map<String, Object>> myGrades,
                                                      Map<String, ClassStat> stats, double pass, long now) {
        return recommend(items, myGrades, stats, pass, now, false);
    }

    public static List<Map<String, Object>> recommend(List<Map<String, Object>> items, List<Map<String, Object>> myGrades,
                                                      Map<String, ClassStat> stats, double pass, long now,
                                                      boolean trackedOnly) {
        Map<String, Double> mine = new HashMap<>();
        for (Map<String, Object> g : myGrades) {
            Double p = num(g.get("grade_percentage"));
            if (p != null) mine.put(key(str(g.get("activity_type")), lng(g.get("source_id"))), p);
        }
        Map<Object, List<Map<String, Object>>> sections = new LinkedHashMap<>();
        List<Map<String, Object>> ordered = new ArrayList<>(items);
        ordered.sort(Comparator.comparingLong((Map<String, Object> i) ->
                i.get("section_number") == null ? Long.MAX_VALUE : lng(i.get("section_number")))
            .thenComparingLong(i -> lng(i.get("coursemoduleid"))));
        for (Map<String, Object> i : ordered) {
            Object k = i.get("section_id") != null ? i.get("section_id") : "none";
            sections.computeIfAbsent(k, x -> new ArrayList<>()).add(i);
        }

        List<Map<String, Object>> out = new ArrayList<>();
        for (List<Map<String, Object>> section : sections.values()) {
            List<Double> myScores = new ArrayList<>(), classScores = new ArrayList<>();
            List<Map<String, Object>> overdue = new ArrayList<>(), unfinished = new ArrayList<>(), graded = new ArrayList<>();
            for (Map<String, Object> i : section) {
                String type = str(i.get("activity_type"));
                String k = key(type, lng(i.get("source_id")));
                Double score = mine.get(k);
                boolean done = lng(i.get("completionstate")) > 0 || in(DONE, str(i.get("task_status")));
                if (score != null) {
                    myScores.add(score);
                    graded.add(i);
                    ClassStat s = stats.get(k);
                    if (s != null && s.gradedCount() >= MIN_CLASS_SIZE) classScores.add(s.average());
                }
                if (!done && (!trackedOnly || lng(i.get("completion_tracking")) != 0)) unfinished.add(i);
                long due = lng(i.get("due_time"));
                if (in(GRADED, type) && !done && score == null && due > 0 && due < now) overdue.add(i);
            }
            Double avg = mean(myScores);
            // Class comparison only over activities whose class figure is allowed (≥5 graded).
            Double myComparable = null, classAvg = null;
            if (!classScores.isEmpty()) {
                List<Double> comparable = new ArrayList<>();
                for (Map<String, Object> i : graded) {
                    String k = key(str(i.get("activity_type")), lng(i.get("source_id")));
                    ClassStat s = stats.get(k);
                    if (s != null && s.gradedCount() >= MIN_CLASS_SIZE) comparable.add(mine.get(k));
                }
                myComparable = mean(comparable);
                classAvg = mean(classScores);
            }
            List<String> reasons = new ArrayList<>();
            double severity = 0;
            if (avg != null && avg < pass) {
                reasons.add("Trung bình chương " + pct(avg) + " dưới ngưỡng qua " + pct(pass));
                severity += pass - avg;
            }
            if (myComparable != null && classAvg != null && classAvg - myComparable >= CLASS_GAP_POINTS) {
                reasons.add("Thấp hơn trung bình lớp " + pct1(classAvg - myComparable).replace("%", "") + " điểm (lớp " + pct(classAvg) + ")");
                severity += classAvg - myComparable;
            }
            if (!overdue.isEmpty()) {
                reasons.add(overdue.size() + " bài tính điểm đã quá hạn, chưa hoàn thành");
                severity += OVERDUE_WEIGHT * overdue.size();
            }
            if (reasons.isEmpty()) continue;

            Map<String, Object> first = section.get(0);
            Map<String, Object> ch = new LinkedHashMap<>();
            ch.put("sectionId", first.get("section_id"));
            ch.put("sectionNumber", first.get("section_number"));
            ch.put("sectionName", str(first.get("section_name")));
            ch.put("severity", Math.round(severity * 10.0) / 10.0);
            ch.put("average", round1(avg));
            ch.put("classAverage", round1(classAvg));
            ch.put("overdueCount", overdue.size());
            ch.put("reasons", reasons);
            ch.put("suggestions", suggestions(unfinished, graded, overdue, mine, stats, now));
            out.add(ch);
        }
        out.sort(Comparator.comparingDouble((Map<String, Object> m) -> -((Number) m.get("severity")).doubleValue()));
        return out;
    }

    /** Unfinished materials first, then overdue graded work, then the lowest graded scores. */
    static List<Map<String, Object>> suggestions(List<Map<String, Object>> unfinished, List<Map<String, Object>> graded,
                                                 List<Map<String, Object>> overdue, Map<String, Double> mine,
                                                 Map<String, ClassStat> stats, long now) {
        List<Map<String, Object>> out = new ArrayList<>();
        Set<Object> used = new HashSet<>();
        for (Map<String, Object> i : unfinished) {
            if (in(GRADED, str(i.get("activity_type")))) continue;
            add(out, used, i, "Chưa hoàn thành trong chương này");
        }
        for (Map<String, Object> i : overdue) {
            add(out, used, i, "Quá hạn từ " + DAY.format(Instant.ofEpochSecond(lng(i.get("due_time"))))
                + ", chưa hoàn thành");
        }
        List<Map<String, Object>> byScore = new ArrayList<>(graded);
        byScore.sort(Comparator.comparingDouble(i -> mine.get(key(str(i.get("activity_type")), lng(i.get("source_id"))))));
        for (Map<String, Object> i : byScore) {
            String k = key(str(i.get("activity_type")), lng(i.get("source_id")));
            ClassStat s = stats.get(k);
            String cls = s != null && s.gradedCount() >= MIN_CLASS_SIZE ? " (lớp " + pct(s.average()) + ")" : "";
            add(out, used, i, str(i.get("activity_name")) + ": " + pct(mine.get(k)) + cls);
        }
        return out.size() > MAX_SUGGESTIONS ? new ArrayList<>(out.subList(0, MAX_SUGGESTIONS)) : out;
    }

    private static void add(List<Map<String, Object>> out, Set<Object> used, Map<String, Object> i, String reason) {
        if (out.size() >= MAX_SUGGESTIONS || !used.add(i.get("coursemoduleid"))) return;
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("activityName", str(i.get("activity_name")));
        m.put("activityType", str(i.get("activity_type")));
        m.put("courseModuleId", i.get("coursemoduleid") == null ? null : lng(i.get("coursemoduleid")));
        m.put("moodlePath", str(i.get("moodle_path")));
        m.put("reason", reason);
        out.add(m);
    }

    /** Null-safe membership: Set.of(...).contains(null) throws. */
    static boolean in(Set<String> set, String value) {
        return value != null && set.contains(value);
    }

    static Double mean(List<Double> v) {
        return v.isEmpty() ? null : v.stream().mapToDouble(Double::doubleValue).average().orElse(0);
    }

    static String pct(double v) {
        return pct1(v);
    }

    static String pct1(double v) {
        return String.format(Locale.ROOT, "%.1f", v).replace('.', ',') + "%";
    }
}
