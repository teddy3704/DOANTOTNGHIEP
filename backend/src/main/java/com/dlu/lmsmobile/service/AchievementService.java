package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.repository.AchievementRepository;
import com.dlu.lmsmobile.repository.StudyPlanRepository;
import com.dlu.lmsmobile.repository.StudySessionRepository;
import org.springframework.stereotype.Service;

import java.time.*;
import java.time.temporal.TemporalAdjusters;
import java.util.*;

import static com.dlu.lmsmobile.service.Values.*;

/**
 * V2-N17 achievements for ONE student, computed from real events (no table of their own). Every rule is
 * conservative: when the stored history cannot prove a badge, it is not awarded. Only the student sees them;
 * there is no ranking.
 */
@Service
public class AchievementService {
    public static final int ON_TIME_RUN = 3, REVIEW_DAYS = 7, STUDY_MINUTES = 300;
    public static final double PLAN_SHARE = 0.8;

    private final AchievementRepository facts;
    private final StudyPlanRepository plans;
    private final StudySessionRepository sessions;
    private final GoalService goals;
    private final LearningHealthService health;
    private final Clock clock;

    public AchievementService(AchievementRepository facts, StudyPlanRepository plans, StudySessionRepository sessions,
                              GoalService goals, LearningHealthService health, Clock clock) {
        this.facts = facts;
        this.plans = plans;
        this.sessions = sessions;
        this.goals = goals;
        this.health = health;
        this.clock = clock;
    }

    public record Badge(String key, String title, String description, boolean achieved, LocalDate achievedOn,
                        int progress, int target) {
        Map<String, Object> json() {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("key", key);
            m.put("title", title);
            m.put("description", description);
            m.put("achieved", achieved);
            m.put("achievedOn", achievedOn == null ? null : achievedOn.toString());
            m.put("progress", Math.min(progress, target));
            m.put("target", target);
            return m;
        }
    }

    /** Pure: longest run of on-time submissions among past deadlines, in due order; date = the 3rd of the first run. */
    static Badge onTime(List<Map<String, Object>> rows, Instant now, ZoneId zone) {
        int run = 0, best = 0;
        LocalDate on = null;
        for (Map<String, Object> r : rows) {
            long due = lng(r.get("due_time"));
            if (due <= 0 || Instant.ofEpochSecond(due).isAfter(now)) continue;   // not decided yet
            long sub = lng(r.get("submitted_at"));
            boolean ok = sub > 0 && sub <= due;
            run = ok ? run + 1 : 0;
            best = Math.max(best, run);
            if (run == ON_TIME_RUN && on == null) on = Instant.ofEpochSecond(sub).atZone(zone).toLocalDate();
        }
        return new Badge("on_time", "Đúng hạn 3 lần liền", "Nộp 3 bài tập liên tiếp trước hạn", best >= ON_TIME_RUN,
            on, best, ON_TIME_RUN);
    }

    /** Pure: longest run of consecutive days among the given (sorted, distinct) review days. */
    static Badge reviewStreak(List<LocalDate> days) {
        int run = 0, best = 0;
        LocalDate prev = null, on = null;
        for (LocalDate d : days) {
            run = prev != null && d.equals(prev.plusDays(1)) ? run + 1 : 1;
            best = Math.max(best, run);
            if (run == REVIEW_DAYS && on == null) on = d;
            prev = d;
        }
        return new Badge("review_streak", "Ôn thẻ 7 ngày liền", "Ôn thẻ ghi nhớ 7 ngày liên tiếp", best >= REVIEW_DAYS,
            on, best, REVIEW_DAYS);
    }

    /** Pure: first Monday–Sunday week with ≥ 80% of its (non-skipped) plan items done. Progress in %. */
    static Badge planWeek(List<Map<String, Object>> rows, LocalDate today) {
        Map<LocalDate, int[]> weeks = new TreeMap<>();
        for (Map<String, Object> r : rows) {
            LocalDate d = date(r.get("plan_date"));
            if (d == null || "skipped".equals(str(r.get("status")))) continue;
            int[] w = weeks.computeIfAbsent(d.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY)), k -> new int[2]);
            w[1]++;
            if ("done".equals(str(r.get("status")))) w[0]++;
        }
        int bestPct = 0;
        LocalDate on = null;
        for (Map.Entry<LocalDate, int[]> e : weeks.entrySet()) {
            int pct = (int) Math.floor(100.0 * e.getValue()[0] / e.getValue()[1]);
            bestPct = Math.max(bestPct, pct);
            if (on == null && e.getValue()[0] >= PLAN_SHARE * e.getValue()[1]) {
                LocalDate sunday = e.getKey().plusDays(6);
                on = sunday.isAfter(today) ? today : sunday;
            }
        }
        return new Badge("plan_week", "Tuần kế hoạch 80%", "Hoàn thành ít nhất 80% kế hoạch của một tuần",
            on != null, on, bestPct, 100);
    }

    /** Pure: cumulative focus minutes; date = the day the total reached 300. */
    static Badge minutes(List<Map<String, Object>> byDay) {
        Map<LocalDate, Long> perDay = new TreeMap<>();
        for (Map<String, Object> r : byDay) {
            LocalDate d = date(r.get("day"));
            if (d != null) perDay.merge(d, lng(r.get("minutes")), Long::sum);
        }
        long total = 0;
        LocalDate on = null;
        for (Map.Entry<LocalDate, Long> e : perDay.entrySet()) {
            total += e.getValue();
            if (on == null && total >= STUDY_MINUTES) on = e.getKey();
        }
        return new Badge("minutes_300", "300 phút tập trung", "Tích lũy 300 phút học tập trung", on != null, on,
            (int) Math.min(total, Integer.MAX_VALUE), STUDY_MINUTES);
    }

    public Map<String, Object> achievements(Long userId) {
        ZoneId zone = clock.getZone();
        LocalDate today = LocalDate.now(clock);
        List<Badge> badges = new ArrayList<>();
        badges.add(onTime(facts.findAssignmentSubmissions(userId), clock.instant(), zone));
        badges.add(reviewStreak(facts.findReviewDays(userId)));
        badges.add(planWeek(plans.findRange(userId, today.minusDays(366), today.plusDays(6)), today));
        badges.add(minutes(sessions.minutesByDayAndCourse(userId,
            today.minusDays(3650).atStartOfDay(zone).toInstant(), today.plusDays(1).atStartOfDay(zone).toInstant())));
        boolean goal = goals.list(userId).stream().anyMatch(g -> "completed".equals(g.get("status")));
        badges.add(new Badge("goal", "Đạt mục tiêu", "Hoàn thành một mục tiêu học tập", goal, null, goal ? 1 : 0, 1));
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> courses = (List<Map<String, Object>>) health.overview(userId)
            .getOrDefault("courses", List.of());
        long red = courses.stream().filter(c -> "RED".equals(c.get("level"))).count();
        boolean noRed = !courses.isEmpty() && red == 0;
        badges.add(new Badge("no_red", "Không còn khóa Đỏ", "Tất cả khóa học đều không ở mức Đỏ",
            noRed, null, courses.isEmpty() ? 0 : (int) (courses.size() - red), Math.max(1, courses.size())));
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("achieved", badges.stream().filter(Badge::achieved).count());
        out.put("badges", badges.stream().map(Badge::json).toList());
        return out;
    }
}
