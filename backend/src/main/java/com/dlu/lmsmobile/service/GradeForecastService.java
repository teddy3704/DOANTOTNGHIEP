package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.exception.ResourceNotFoundException;
import com.dlu.lmsmobile.repository.ForecastRepository;
import com.dlu.lmsmobile.repository.InsightsRepository;
import com.dlu.lmsmobile.repository.TeacherRepository;
import org.springframework.stereotype.Service;

import java.util.*;

import static com.dlu.lmsmobile.service.Values.*;

/**
 * Grade forecast ("what do I still need?"). The static methods are pure and carry all of the
 * arithmetic; the instance methods only load rows and check enrolment.
 *
 * <p>Model (documented in docs/FEATURES_V2.md): the runtime role reads grades only through
 * derived.student_grade_overview, which exposes each item's category and parent category but not
 * the category aggregation settings. Every category is therefore treated as "Mean of grades"
 * (Moodle aggregation 0, which is what the course data uses); an item weight ({@code coef}) is
 * honoured when supplied. The tree has at most two levels: root category → sub-category → item.
 */
@Service
public class GradeForecastService {
    public static final double DEFAULT_PASS_PERCENT = 50.0;
    static final double EPS = 1e-9;

    /** One gradable activity of the course. {@code coef} &gt; 0 makes its parent a weighted mean. */
    public record Item(long gradeItemId, String name, String activityType, Long sourceId,
                       Long categoryId, String categoryName, Long parentCategoryId,
                       Double grademax, Double gradepass, Double coef, boolean hidden,
                       Long dueTime, String moodlePath, Long courseModuleId) {
    }

    /** An item with its effective share of the final grade (all weights sum to 1). */
    public record Weighted(Item item, double weight, Double score) {
    }

    /** Result of the engine for one student. */
    public record Forecast(List<Weighted> items, Double current, double gradedContribution,
                           double remainingWeight, double passPercent, String passSource,
                           boolean approximation) {
        public double bestCase() {
            return gradedContribution + remainingWeight * 100.0;
        }

        public boolean hasRemaining() {
            return remainingWeight > EPS;
        }

        public long gradedCount() {
            return items.stream().filter(w -> w.score() != null).count();
        }
    }

    public enum Status { ACHIEVED, FEASIBLE, NOT_FEASIBLE, NO_REMAINING }

    /** Outcome for one target: {@code need} is the average % required on every ungraded item. */
    public record Need(Double need, Status status, boolean reached) {
    }

    private final ForecastRepository repository;
    private final InsightsRepository insights;
    private final TeacherRepository teachers;

    public GradeForecastService(ForecastRepository repository, InsightsRepository insights, TeacherRepository teachers) {
        this.repository = repository;
        this.insights = insights;
        this.teachers = teachers;
    }

    /** Most urgent band first in the teacher list. */
    static final List<String> BAND_ORDER = List.of("NOT_FEASIBLE", "HIGH_RISK", "EFFORT", "SAFE", "SURE_PASS", "NO_DATA");

    /** V2-N4: the N1 engine for every student on the teacher's roster of this course. */
    public Map<String, Object> teacherForecast(Long teacherId, Long courseId) {
        if (!teachers.hasCourse(teacherId, courseId)) throw new ResourceNotFoundException("Teacher course not found");
        List<Map<String, Object>> roster = teachers.findStudents(teacherId, courseId);
        List<Long> ids = roster.stream().map(s -> lng(s.get("userid"))).toList();
        return classJson(roster, classForecast(courseId, ids));
    }

    static Map<String, Object> classJson(List<Map<String, Object>> roster, Map<Long, Forecast> forecasts) {
        Map<String, Long> counts = new LinkedHashMap<>();
        for (String b : BAND_ORDER) counts.put(b, 0L);
        List<Map<String, Object>> students = new ArrayList<>();
        Double pass = null;
        for (Map<String, Object> s : roster) {
            long id = lng(s.get("userid"));
            Forecast f = forecasts.get(id);
            if (f == null) continue;
            pass = f.passPercent();
            String band = passBand(f);
            counts.merge(band, 1L, Long::sum);
            Need n = need(f, f.passPercent());
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("userid", id);
            m.put("fullname", s.get("fullname"));
            m.put("student_code", s.get("student_code"));
            m.put("band", band);
            m.put("current", round1(f.current()));
            m.put("worstCase", round1(f.gradedContribution()));
            m.put("bestCase", round1(f.bestCase()));
            m.put("need", n.need() == null ? null : round1(n.need()));
            m.put("gradedCount", f.gradedCount());
            m.put("remainingCount", f.items().size() - f.gradedCount());
            students.add(m);
        }
        students.sort(Comparator.comparingInt((Map<String, Object> m) -> BAND_ORDER.indexOf(m.get("band")))
            .thenComparing(m -> m.get("need") == null ? 0.0 : -((Number) m.get("need")).doubleValue())
            .thenComparing(m -> String.valueOf(m.get("fullname"))));
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("passPercent", pass == null ? DEFAULT_PASS_PERCENT : round1(pass));
        out.put("thresholds", Map.of("SAFE", 60, "EFFORT", 85, "HIGH_RISK", 100));
        out.put("counts", counts);
        out.put("students", students);
        return out;
    }

    // ------------------------------------------------------------------ pure engine

    /** Builds the weighted tree and the current/remaining figures. {@code scores}: gradeItemId → %. */
    public static Forecast forecast(List<Item> allItems, Map<Long, Double> scores) {
        List<Item> items = allItems.stream().filter(i -> !i.hidden()).toList();
        boolean approximation = false;

        // Root of each item: its parent category when it sits in a sub-category, else its own category.
        Set<Long> roots = new LinkedHashSet<>();
        for (Item i : items) roots.add(i.parentCategoryId() != null ? i.parentCategoryId() : i.categoryId());
        if (roots.size() > 1) approximation = true;

        // Root children: sub-categories (keyed by category id) and items placed directly in the root.
        Map<String, List<Item>> children = new LinkedHashMap<>();
        for (Item i : items) {
            String key = i.parentCategoryId() != null ? "c" + i.categoryId() : "i" + i.gradeItemId();
            children.computeIfAbsent(key, k -> new ArrayList<>()).add(i);
        }

        // A root child's coefficient: the item's own for an item placed in the root; unknown (null)
        // for a sub-category, whose aggregation coefficient the runtime role cannot read.
        List<Double> rootCoefs = new ArrayList<>();
        for (List<Item> group : children.values()) {
            rootCoefs.add(group.get(0).parentCategoryId() == null ? group.get(0).coef() : null);
        }
        double[] rootShares = shareOf(rootCoefs);
        if (partiallyWeighted(rootCoefs)) approximation = true;

        List<Weighted> weighted = new ArrayList<>();
        double gradedContribution = 0, remaining = 0;
        double currentNum = 0, currentDen = 0;
        int g = 0;
        for (List<Item> group : children.values()) {
            double rootShare = rootShares[g++];
            boolean isCategory = group.get(0).parentCategoryId() != null;
            double[] within = isCategory ? shares(group) : new double[] {1.0};
            if (isCategory && partiallyWeighted(group.stream().map(Item::coef).toList())) approximation = true;
            double groupNum = 0, groupDen = 0;
            for (int k = 0; k < group.size(); k++) {
                Item item = group.get(k);
                double w = rootShare * within[k];
                Double s = scores.get(item.gradeItemId());
                weighted.add(new Weighted(item, w, s));
                if (s != null) {
                    gradedContribution += w * s;
                    groupNum += within[k] * s;
                    groupDen += within[k];
                } else {
                    remaining += w;
                }
            }
            // Moodle "only graded": a category's value is the mean of its graded children; a category
            // with nothing graded is left out of its parent instead of counting as zero.
            if (groupDen > EPS) {
                currentNum += rootShare * (groupNum / groupDen);
                currentDen += rootShare;
            }
        }
        Double current = currentDen > EPS ? currentNum / currentDen : null;
        double[] pass = passPercent(items);
        return new Forecast(weighted, current, gradedContribution, remaining, pass[0],
            pass[1] > 0 ? "items" : "default", approximation);
    }

    static double[] shares(List<Item> siblings) {
        return shareOf(siblings.stream().map(Item::coef).toList());
    }

    /**
     * Normalised coefficients when every sibling has one (&gt; 0); otherwise equal shares
     * ("Mean of grades"). Mixed cases fall back to equal shares and are flagged by the caller.
     */
    static double[] shareOf(List<Double> coefs) {
        double[] out = new double[coefs.size()];
        boolean all = !coefs.isEmpty();
        double total = 0;
        for (Double c : coefs) {
            if (c == null || c <= 0) all = false;
            else total += c;
        }
        for (int k = 0; k < out.length; k++) out[k] = all ? coefs.get(k) / total : 1.0 / coefs.size();
        return out;
    }

    static boolean partiallyWeighted(List<Double> coefs) {
        long weightedCount = coefs.stream().filter(c -> c != null && c > 0).count();
        return weightedCount > 0 && weightedCount < coefs.size();
    }

    /** {pass %, 1 if taken from the items' gradepass/grademax, 0 if the 50% default}. */
    static double[] passPercent(List<Item> items) {
        Double common = null;
        for (Item i : items) {
            if (i.grademax() == null || i.grademax() <= 0 || i.gradepass() == null || i.gradepass() <= 0) {
                return new double[] {DEFAULT_PASS_PERCENT, 0};
            }
            double r = i.gradepass() / i.grademax() * 100.0;
            if (common == null) common = r;
            else if (Math.abs(common - r) > 0.01) return new double[] {DEFAULT_PASS_PERCENT, 0};
        }
        return common == null ? new double[] {DEFAULT_PASS_PERCENT, 0} : new double[] {common, 1};
    }

    /** need = (target − Σ wᵢ·sᵢ graded) / Σ wⱼ ungraded. */
    public static Need need(Forecast f, double target) {
        if (!f.hasRemaining()) {
            boolean reached = f.gradedContribution() + EPS >= target;
            return new Need(null, Status.NO_REMAINING, reached);
        }
        double need = (target - f.gradedContribution()) / f.remainingWeight();
        if (need <= EPS) return new Need(need, Status.ACHIEVED, true);
        return new Need(need, need <= 100 + EPS ? Status.FEASIBLE : Status.NOT_FEASIBLE, false);
    }

    /** Teacher-facing class bands for the pass target. Thresholds are in docs/FEATURES_V2.md. */
    public static String passBand(Forecast f) {
        if (f.items().isEmpty()) return "NO_DATA";
        Need n = need(f, f.passPercent());
        if (n.status() == Status.NO_REMAINING) return n.reached() ? "SURE_PASS" : "NOT_FEASIBLE";
        if (n.status() == Status.ACHIEVED) return "SURE_PASS";
        if (n.status() == Status.NOT_FEASIBLE) return "NOT_FEASIBLE";
        if (n.need() <= 60 + EPS) return "SAFE";
        if (n.need() <= 85 + EPS) return "EFFORT";
        return "HIGH_RISK";
    }

    // ------------------------------------------------------------------ row mapping

    static List<Item> items(List<Map<String, Object>> rows) {
        List<Item> out = new ArrayList<>();
        for (Map<String, Object> r : rows) {
            out.add(new Item(lng(r.get("grade_item_id")), str(r.get("activity_name")), str(r.get("activity_type")),
                r.get("source_id") == null ? null : lng(r.get("source_id")),
                r.get("category_id") == null ? null : lng(r.get("category_id")), str(r.get("category_name")),
                r.get("parent_category_id") == null ? null : lng(r.get("parent_category_id")),
                num(r.get("grademax")), num(r.get("gradepass")), null,
                !Boolean.TRUE.equals(r.get("module_visible")),
                r.get("due_time") == null || lng(r.get("due_time")) <= 0 ? null : lng(r.get("due_time")),
                str(r.get("moodle_path")),
                r.get("coursemoduleid") == null ? null : lng(r.get("coursemoduleid"))));
        }
        return out;
    }

    /** userId → (gradeItemId → %), for graded rows only. */
    static Map<Long, Map<Long, Double>> scoresByUser(List<Map<String, Object>> rows) {
        Map<Long, Map<Long, Double>> out = new HashMap<>();
        for (Map<String, Object> r : rows) {
            Double p = num(r.get("grade_percentage"));
            if (p == null) continue;
            out.computeIfAbsent(lng(r.get("userid")), k -> new HashMap<>()).put(lng(r.get("grade_item_id")), p);
        }
        return out;
    }

    static Map<String, Object> toJson(Forecast f) {
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("current", round1(f.current()));
        out.put("passPercent", round1(f.passPercent()));
        out.put("passSource", f.passSource());
        out.put("approximation", f.approximation());
        out.put("aggregation", "MEAN_OF_GRADES_ASSUMED");
        out.put("gradedContribution", round4(f.gradedContribution()));
        out.put("remainingWeight", round4(f.remainingWeight()));
        out.put("worstCase", round1(f.gradedContribution()));
        out.put("bestCase", round1(f.bestCase()));
        out.put("gradedCount", f.gradedCount());
        Need pass = need(f, f.passPercent());
        Map<String, Object> passOut = new LinkedHashMap<>();
        passOut.put("need", pass.need() == null ? null : round1(pass.need()));
        passOut.put("status", pass.status().name());
        passOut.put("reached", pass.reached());
        out.put("pass", passOut);
        List<Map<String, Object>> list = new ArrayList<>();
        for (Weighted w : f.items()) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("gradeItemId", w.item().gradeItemId());
            m.put("name", w.item().name());
            m.put("activityType", w.item().activityType());
            m.put("sourceId", w.item().sourceId());
            m.put("category", w.item().categoryName());
            m.put("scorePercent", w.score() == null ? null : round1(w.score()));
            m.put("weight", round4(w.weight()));
            m.put("dueTime", w.item().dueTime());
            m.put("moodlePath", w.item().moodlePath());
            m.put("courseModuleId", w.item().courseModuleId());
            list.add(m);
        }
        out.put("items", list);
        return out;
    }

    static Double round4(Double v) {
        return v == null ? null : Math.round(v * 10000.0) / 10000.0;
    }

    // ------------------------------------------------------------------ data access

    public Map<String, Object> studentForecast(Long userId, Long courseId) {
        if (!insights.isEnrolled(userId, courseId)) throw new ResourceNotFoundException("Student course not found");
        List<Item> items = items(repository.findCourseGradeItems(courseId));
        Map<Long, Double> mine = scoresByUser(repository.findCourseGrades(courseId, userId))
            .getOrDefault(userId, Map.of());
        return toJson(forecast(items, mine));
    }

    /** Forecast for every student of a teacher's course; the caller has already checked the roster. */
    public Map<Long, Forecast> classForecast(Long courseId, Collection<Long> studentIds) {
        List<Item> items = items(repository.findCourseGradeItems(courseId));
        Map<Long, Map<Long, Double>> scores = scoresByUser(repository.findCourseGrades(courseId, null));
        Map<Long, Forecast> out = new LinkedHashMap<>();
        for (Long id : studentIds) out.put(id, forecast(items, scores.getOrDefault(id, Map.of())));
        return out;
    }
}
