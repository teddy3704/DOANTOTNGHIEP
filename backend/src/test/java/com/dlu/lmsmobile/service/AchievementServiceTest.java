package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.repository.AchievementRepository;
import com.dlu.lmsmobile.repository.StudyPlanRepository;
import com.dlu.lmsmobile.repository.StudySessionRepository;
import com.dlu.lmsmobile.service.AchievementService.Badge;
import org.junit.jupiter.api.Test;

import java.sql.Date;
import java.time.*;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class AchievementServiceTest {
    static final ZoneId VN = ZoneId.of("Asia/Ho_Chi_Minh");
    static final Instant NOW = ZonedDateTime.of(2026, 11, 20, 12, 0, 0, 0, VN).toInstant();

    static long day(int d, int h) {
        return ZonedDateTime.of(2026, 11, d, h, 0, 0, 0, VN).toEpochSecond();
    }

    static Map<String, Object> sub(long due, Long submitted) {
        Map<String, Object> m = new HashMap<>();
        m.put("due_time", due);
        m.put("submitted_at", submitted);
        return m;
    }

    @Test
    void onTimeNeedsThreeConsecutiveSubmissionsBeforeTheirDeadlines() {
        Badge late = AchievementService.onTime(List.of(sub(day(1, 23), day(1, 20)),
            sub(day(3, 23), day(4, 8)),                        // late breaks the run
            sub(day(5, 23), day(5, 9)), sub(day(7, 23), day(7, 9))), NOW, VN);
        assertFalse(late.achieved());
        assertEquals(2, late.progress());
        Badge ok = AchievementService.onTime(List.of(sub(day(1, 23), day(1, 9)), sub(day(3, 23), day(3, 9)),
            sub(day(5, 23), day(5, 22)), sub(day(30, 23), null)), NOW, VN);   // future deadline: not decided
        assertTrue(ok.achieved());
        assertEquals(LocalDate.of(2026, 11, 5), ok.achievedOn());
        Badge missing = AchievementService.onTime(List.of(sub(day(1, 23), null), sub(day(3, 23), day(3, 9))), NOW, VN);
        assertEquals(1, missing.progress());
    }

    @Test
    void reviewStreakCountsConsecutiveDistinctDays() {
        List<LocalDate> days = new ArrayList<>();
        for (int d = 1; d <= 6; d++) days.add(LocalDate.of(2026, 11, d));
        days.add(LocalDate.of(2026, 11, 8));
        Badge six = AchievementService.reviewStreak(days);
        assertFalse(six.achieved());
        assertEquals(6, six.progress());
        days.add(6, LocalDate.of(2026, 11, 7));
        Badge seven = AchievementService.reviewStreak(days);
        assertTrue(seven.achieved());
        assertEquals(LocalDate.of(2026, 11, 7), seven.achievedOn());
        assertEquals(0, AchievementService.reviewStreak(List.of()).progress());
    }

    static Map<String, Object> plan(String date, String status) {
        return Map.of("plan_date", Date.valueOf(date), "status", status);
    }

    @Test
    void planWeekNeedsEightyPercentOfNonSkippedItems() {
        LocalDate today = LocalDate.of(2026, 11, 20);
        Badge no = AchievementService.planWeek(List.of(plan("2026-11-09", "done"), plan("2026-11-10", "done"),
            plan("2026-11-11", "done"), plan("2026-11-12", "planned"), plan("2026-11-13", "skipped")), today);
        assertFalse(no.achieved());
        assertEquals(75, no.progress());
        Badge yes = AchievementService.planWeek(List.of(plan("2026-11-16", "done"), plan("2026-11-17", "done"),
            plan("2026-11-18", "done"), plan("2026-11-19", "done"), plan("2026-11-20", "planned")), today);
        assertTrue(yes.achieved());
        assertEquals(today, yes.achievedOn());   // current week: today, not a future Sunday
    }

    @Test
    void minutesBadgeDateIsTheDayTheTotalReached300() {
        Badge b = AchievementService.minutes(List.of(
            Map.of("day", Date.valueOf("2026-11-10"), "minutes", 200L),
            Map.of("day", Date.valueOf("2026-11-12"), "minutes", 50L),
            Map.of("day", Date.valueOf("2026-11-12"), "minutes", 60L),
            Map.of("day", Date.valueOf("2026-11-15"), "minutes", 25L)));
        assertTrue(b.achieved());
        assertEquals(LocalDate.of(2026, 11, 12), b.achievedOn());
        assertEquals(300, b.json().get("progress"));   // capped at the target
        assertFalse(AchievementService.minutes(List.of()).achieved());
    }

    @Test
    void sixBadgesGoalAndNoRedAreStateBadgesWithoutDate() {
        AchievementRepository facts = mock(AchievementRepository.class);
        StudyPlanRepository plans = mock(StudyPlanRepository.class);
        StudySessionRepository sessions = mock(StudySessionRepository.class);
        GoalService goals = mock(GoalService.class);
        LearningHealthService health = mock(LearningHealthService.class);
        when(facts.findAssignmentSubmissions(205L)).thenReturn(List.of());
        when(facts.findReviewDays(205L)).thenReturn(List.of());
        when(plans.findRange(eq(205L), any(), any())).thenReturn(List.of());
        when(sessions.minutesByDayAndCourse(eq(205L), any(), any())).thenReturn(List.of());
        when(goals.list(205L)).thenReturn(List.of(Map.of("status", "completed")));
        when(health.overview(205L)).thenReturn(Map.of("courses",
            List.of(Map.of("level", "GREEN"), Map.of("level", "RED"), Map.of("level", "YELLOW"))));
        var service = new AchievementService(facts, plans, sessions, goals, health, Clock.fixed(NOW, VN));
        Map<String, Object> out = service.achievements(205L);
        @SuppressWarnings("unchecked") List<Map<String, Object>> b = (List<Map<String, Object>>) out.get("badges");
        assertEquals(List.of("on_time", "review_streak", "plan_week", "minutes_300", "goal", "no_red"),
            b.stream().map(x -> x.get("key")).toList());
        assertEquals(true, b.get(4).get("achieved"));
        assertNull(b.get(4).get("achievedOn"));
        assertEquals(false, b.get(5).get("achieved"));
        assertEquals(2, b.get(5).get("progress"));
        assertEquals(3, b.get(5).get("target"));
        assertEquals(1L, out.get("achieved"));
    }
}
