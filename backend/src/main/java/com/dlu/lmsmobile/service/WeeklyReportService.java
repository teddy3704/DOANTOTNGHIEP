package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.exception.InvalidRequestException;
import com.dlu.lmsmobile.repository.FlashcardReviewRepository;
import com.dlu.lmsmobile.repository.InsightsRepository;
import com.dlu.lmsmobile.repository.StudyPlanRepository;
import com.dlu.lmsmobile.repository.StudySessionRepository;
import org.springframework.stereotype.Service;

import java.time.*;
import java.time.temporal.TemporalAdjusters;
import java.util.*;

import static com.dlu.lmsmobile.service.Values.*;

/**
 * V2-N14 "Tuần của bạn": one student's week (Monday–Sunday, Asia/Ho_Chi_Minh) compared with the week before.
 * Every row comes from real data; a row whose source has nothing in either week is left out instead of
 * showing a made-up 0. New grades are not reported: grade rows carry no timestamp the app may read.
 */
@Service
public class WeeklyReportService {
    private final StudyPlanRepository plans;
    private final StudySessionRepository sessions;
    private final FlashcardReviewRepository reviews;
    private final InsightsRepository insights;
    private final Clock clock;

    public WeeklyReportService(StudyPlanRepository plans, StudySessionRepository sessions,
                               FlashcardReviewRepository reviews, InsightsRepository insights, Clock clock) {
        this.plans = plans;
        this.sessions = sessions;
        this.reviews = reviews;
        this.insights = insights;
        this.clock = clock;
    }

    /** Values of one week; null = source has no data for that week. */
    public record Week(Integer planDone, Integer planTotal, Long focusMinutes, Long cardsReviewed,
                       Long activitiesCompleted, Integer activeDays) {
    }

    public Map<String, Object> report(Long userId, String weekStart) {
        ZoneId zone = clock.getZone();
        LocalDate today = LocalDate.now(clock);
        LocalDate monday = parse(weekStart, today).with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
        LocalDate prev = monday.minusWeeks(1);
        Map<LocalDate, Long> events = new HashMap<>();
        for (Map<String, Object> r : insights.findStudentActivityByDay(userId,
                today.minusDays(400).atStartOfDay(zone).toEpochSecond())) {
            LocalDate d = date(r.get("day"));
            if (d != null) events.put(d, lng(r.get("events")));
        }
        List<Map<String, Object>> completions = insights.findStudentCompletionsByDay(userId);
        List<Map<String, Object>> planRows = plans.findRange(userId, prev, monday.plusDays(6));
        Week cur = week(userId, monday, zone, planRows, completions, events);
        Week last = week(userId, prev, zone, planRows, completions, events);
        Map<String, Object> out = summarize(monday, cur, last);
        Map<String, Object> streak = InsightsService.streak(events, today);
        if (lng(streak.get("longest_days")) > 0) out.put("streakDays", streak.get("current_days"));
        return out;
    }

    private Week week(Long userId, LocalDate monday, ZoneId zone, List<Map<String, Object>> planRows,
                      List<Map<String, Object>> completions, Map<LocalDate, Long> events) {
        LocalDate sunday = monday.plusDays(6);
        Instant from = monday.atStartOfDay(zone).toInstant(), to = monday.plusWeeks(1).atStartOfDay(zone).toInstant();
        int done = 0, total = 0;
        for (Map<String, Object> r : planRows) {
            LocalDate d = date(r.get("plan_date"));
            if (d == null || d.isBefore(monday) || d.isAfter(sunday) || "skipped".equals(str(r.get("status")))) continue;
            total++;
            if ("done".equals(str(r.get("status")))) done++;
        }
        long completed = 0;
        for (Map<String, Object> c : completions) {
            LocalDate d = date(c.get("day"));
            if (d != null && !d.isBefore(monday) && !d.isAfter(sunday)) completed += lng(c.get("completed"));
        }
        int active = 0;
        for (LocalDate d = monday; !d.isAfter(sunday); d = d.plusDays(1)) if (events.getOrDefault(d, 0L) > 0) active++;
        return new Week(total == 0 ? null : done, total == 0 ? null : total,
            sessions.totalMinutes(userId, null, from, to), reviews.countReviewedBetween(userId, from, to),
            completed, active);
    }

    /** Pure: rows shown only when this or last week has data; trend = current − previous. */
    static Map<String, Object> summarize(LocalDate monday, Week cur, Week last) {
        List<Map<String, Object>> rows = new ArrayList<>();
        if (cur.planTotal() != null || last.planTotal() != null) {
            Map<String, Object> m = row("plan", "Việc trong kế hoạch đã xong",
                cur.planDone() == null ? 0 : cur.planDone(), last.planDone() == null ? 0 : last.planDone());
            m.put("total", cur.planTotal() == null ? 0 : cur.planTotal());
            rows.add(m);
        }
        addIfAny(rows, "minutes", "Phút học tập trung", cur.focusMinutes(), last.focusMinutes());
        addIfAny(rows, "cards", "Thẻ ghi nhớ đã ôn", cur.cardsReviewed(), last.cardsReviewed());
        addIfAny(rows, "completed", "Hoạt động LMS hoàn thành", cur.activitiesCompleted(), last.activitiesCompleted());
        addIfAny(rows, "activeDays", "Ngày có vào học",
            cur.activeDays() == null ? null : (long) cur.activeDays(),
            last.activeDays() == null ? null : (long) last.activeDays());
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("weekStart", monday.toString());
        out.put("weekEnd", monday.plusDays(6).toString());
        out.put("rows", rows);
        return out;
    }

    private static void addIfAny(List<Map<String, Object>> rows, String key, String label, Long cur, Long last) {
        long c = cur == null ? 0 : cur, l = last == null ? 0 : last;
        if (c == 0 && l == 0) return;
        rows.add(row(key, label, c, l));
    }

    private static Map<String, Object> row(String key, String label, long cur, long last) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("key", key);
        m.put("label", label);
        m.put("value", cur);
        m.put("previous", last);
        m.put("trend", Long.compare(cur, last));
        return m;
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
