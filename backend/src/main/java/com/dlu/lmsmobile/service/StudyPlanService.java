package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.exception.InvalidRequestException;
import com.dlu.lmsmobile.exception.ResourceNotFoundException;
import com.dlu.lmsmobile.repository.FlashcardReviewRepository;
import com.dlu.lmsmobile.repository.StudentRepository;
import com.dlu.lmsmobile.repository.StudyPlanRepository;
import com.dlu.lmsmobile.service.StudyPlanner.*;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.*;

import static com.dlu.lmsmobile.service.Values.*;

/** V2-N6: builds the weekly plan from LMS tasks, due flashcards (N5) and suggestions (N2). */
@Service
public class StudyPlanService {
    static final Set<String> STATUSES = Set.of("planned", "done", "skipped");
    static final int SUGGESTIONS = 3;

    private final StudentRepository students;
    private final FlashcardReviewRepository cards;
    private final StudyRecommendationService recommendations;
    private final StudyPlanRepository plans;
    private final Clock clock;

    public StudyPlanService(StudentRepository students, FlashcardReviewRepository cards,
                            StudyRecommendationService recommendations, StudyPlanRepository plans, Clock clock) {
        this.students = students;
        this.cards = cards;
        this.recommendations = recommendations;
        this.plans = plans;
        this.clock = clock;
    }

    private LocalDate today() {
        return LocalDate.now(clock);
    }

    private ZoneId zone() {
        return clock.getZone();
    }

    /** Pending LMS tasks: not completed/submitted/finished, overdue or due within 14 days. */
    List<Task> lmsTasks(Long userId, LocalDate today) {
        List<Task> out = new ArrayList<>();
        LocalDate limit = today.plusDays(StudyPlanner.LOOKAHEAD_DAYS);
        for (Map<String, Object> r : students.findAllTasks(userId)) {
            String type = str(r.get("task_type"));
            String status = str(r.get("task_status"));
            boolean assign = "assignment".equals(type) || "assign".equals(type);
            boolean done = "completed".equals(status)
                || (assign && "submitted".equals(str(r.get("source_status"))))
                || ("quiz".equals(type) && "finished".equals(str(r.get("quiz_state"))));
            if (done || !("pending".equals(status) || "overdue".equals(status))) continue;
            long dueEpoch = lng(r.get("due_time"));
            if (dueEpoch <= 0) continue; // no deadline: nothing to plan against
            LocalDate due = Instant.ofEpochSecond(dueEpoch).atZone(zone()).toLocalDate();
            boolean overdue = Instant.ofEpochSecond(dueEpoch).isBefore(clock.instant());
            if (!overdue && due.isAfter(limit)) continue;
            String sourceType = assign ? "assign" : "quiz";
            out.add(new Task(sourceType, lng(r.get("source_id")), lng(r.get("courseid")), str(r.get("title")), due,
                overdue ? Kind.OVERDUE : Kind.DEADLINE, StudyPlanner.estimate(sourceType)));
        }
        return out;
    }

    @SuppressWarnings("unchecked")
    List<Task> suggestionTasks(Long userId) {
        List<Task> out = new ArrayList<>();
        Map<String, Object> r = recommendations.overall(userId, SUGGESTIONS);
        for (Map<String, Object> ch : (List<Map<String, Object>>) r.getOrDefault("chapters", List.of())) {
            List<Map<String, Object>> sug = (List<Map<String, Object>>) ch.getOrDefault("suggestions", List.of());
            if (sug.isEmpty()) continue;
            Map<String, Object> s = sug.get(0);
            Long moduleId = s.get("courseModuleId") instanceof Number n ? n.longValue() : null;
            out.add(new Task("resource", moduleId, ch.get("courseId") instanceof Number n ? n.longValue() : null,
                "Ôn lại: " + str(s.get("activityName")), null, Kind.SUGGESTION, StudyPlanner.RESOURCE_MINUTES));
        }
        return out;
    }

    public Map<String, Object> generate(Long userId, Object dailyMinutes) {
        int budget = budget(dailyMinutes);
        LocalDate today = today();
        List<Task> tasks = new ArrayList<>(lmsTasks(userId, today));
        int due = cards.findDue(userId, null, clock.instant()).size();
        if (due > 0) {
            tasks.add(new Task("flashcards", null, null, "Ôn " + due + " thẻ ghi nhớ", today, Kind.FLASHCARDS,
                StudyPlanner.flashcardMinutes(due)));
        }
        tasks.addAll(suggestionTasks(userId));

        // Items already done stay; their minutes count against the day and against the task.
        Map<LocalDate, Integer> used = new HashMap<>();
        Map<String, Integer> doneMinutes = new HashMap<>();
        for (Map<String, Object> r : plans.findRange(userId, today.minusDays(StudyPlanner.LOOKAHEAD_DAYS),
                today.plusDays(StudyPlanner.HORIZON_DAYS - 1L))) {
            if (!"done".equals(str(r.get("status")))) continue;
            int m = (int) lng(r.get("planned_minutes"));
            LocalDate d = date(r.get("plan_date"));
            if (d != null && !d.isBefore(today)) used.merge(d, m, Integer::sum);
            // Flashcard review is a daily task: only today's done review counts against today's review
            // (otherwise regenerating would add a second "Ôn N thẻ" next to the one already ticked).
            boolean cards = "flashcards".equals(str(r.get("source_type")));
            if (!cards || today.equals(d)) {
                doneMinutes.merge(str(r.get("source_type")) + ":" + r.get("source_id"), m, Integer::sum);
            }
        }
        Plan plan = StudyPlanner.plan(today, budget, tasks, used, doneMinutes);
        List<StudyPlanRepository.NewItem> rows = new ArrayList<>();
        for (Item i : plan.items()) {
            String title = i.parts() > 1 ? i.title() + " (phần " + i.part() + "/" + i.parts() + ")" : i.title();
            rows.add(new StudyPlanRepository.NewItem(i.courseId(), i.date(), i.sourceType(), i.sourceId(),
                truncate(title), i.minutes()));
        }
        plans.replacePlanned(userId, today, rows);
        Map<String, Object> out = week(userId, today, today.plusDays(StudyPlanner.HORIZON_DAYS - 1L), budget);
        out.put("overloaded", plan.overloaded().stream().map(o -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("title", o.title());
            m.put("courseId", o.courseId());
            m.put("sourceType", o.sourceType());
            m.put("due", o.due() == null ? null : o.due().toString());
            m.put("minutes", o.minutes());
            return m;
        }).toList());
        out.put("deferred", plan.deferred());
        return out;
    }

    public Map<String, Object> get(Long userId, String from, String to) {
        LocalDate f = parse(from, today());
        LocalDate t = parse(to, f.plusDays(StudyPlanner.HORIZON_DAYS - 1L));
        if (t.isBefore(f) || t.toEpochDay() - f.toEpochDay() > 31) throw new InvalidRequestException("Khoảng ngày không hợp lệ");
        return week(userId, f, t, null);
    }

    public Map<String, Object> setStatus(Long userId, Long id, Object status) {
        if (!(status instanceof String s) || !STATUSES.contains(s)) {
            throw new InvalidRequestException("status phải là một trong " + STATUSES);
        }
        if (plans.updateStatus(userId, id, s) == 0) throw new ResourceNotFoundException("Plan item not found");
        return item(plans.findOwned(userId, id).get(0));
    }

    /** Days from..to with items and used minutes; budget inferred when not given (smallest option ≥ busiest day). */
    Map<String, Object> week(Long userId, LocalDate from, LocalDate to, Integer budget) {
        Map<LocalDate, List<Map<String, Object>>> byDay = new TreeMap<>();
        for (LocalDate d = from; !d.isAfter(to); d = d.plusDays(1)) byDay.put(d, new ArrayList<>());
        for (Map<String, Object> r : plans.findRange(userId, from, to)) {
            LocalDate d = date(r.get("plan_date"));
            if (d != null && byDay.containsKey(d)) byDay.get(d).add(item(r));
        }
        int busiest = 0;
        List<Map<String, Object>> days = new ArrayList<>();
        for (Map.Entry<LocalDate, List<Map<String, Object>>> e : byDay.entrySet()) {
            int planned = 0, done = 0;
            for (Map<String, Object> i : e.getValue()) {
                if ("skipped".equals(i.get("status"))) continue;
                int m = (int) i.get("minutes");
                planned += m;
                if ("done".equals(i.get("status"))) done += m;
            }
            busiest = Math.max(busiest, planned);
            Map<String, Object> d = new LinkedHashMap<>();
            d.put("date", e.getKey().toString());
            d.put("plannedMinutes", planned);
            d.put("doneMinutes", done);
            d.put("items", e.getValue());
            days.add(d);
        }
        if (budget == null) {
            final int b = busiest;
            budget = StudyPlanner.BUDGETS.stream().filter(x -> x >= b).findFirst().orElse(StudyPlanner.BUDGETS.get(3));
        }
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("from", from.toString());
        out.put("to", to.toString());
        out.put("today", today().toString());
        out.put("dailyMinutes", budget);
        out.put("days", days);
        return out;
    }

    private static Map<String, Object> item(Map<String, Object> r) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", lng(r.get("id")));
        m.put("date", String.valueOf(date(r.get("plan_date"))));
        m.put("courseId", r.get("course_id") instanceof Number n ? n.longValue() : null);
        m.put("sourceType", str(r.get("source_type")));
        m.put("sourceId", r.get("source_id") instanceof Number n ? n.longValue() : null);
        m.put("title", str(r.get("title")));
        m.put("minutes", (int) lng(r.get("planned_minutes")));
        m.put("status", str(r.get("status")));
        return m;
    }

    static int budget(Object v) {
        if (v instanceof Integer i && StudyPlanner.BUDGETS.contains(i)) return i;
        throw new InvalidRequestException("dailyMinutes phải là một trong " + StudyPlanner.BUDGETS);
    }

    private static LocalDate parse(String s, LocalDate fallback) {
        if (s == null || s.isBlank()) return fallback;
        try {
            return LocalDate.parse(s);
        } catch (RuntimeException e) {
            throw new InvalidRequestException("Ngày phải theo dạng yyyy-MM-dd");
        }
    }

    private static String truncate(String s) {
        if (s == null) return "Việc học";
        return s.length() <= 255 ? s : s.substring(0, 252) + "...";
    }
}
