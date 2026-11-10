package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.repository.FlashcardReviewRepository;
import com.dlu.lmsmobile.repository.InsightsRepository;
import com.dlu.lmsmobile.repository.StudyPlanRepository;
import com.dlu.lmsmobile.repository.StudySessionRepository;
import com.dlu.lmsmobile.service.WeeklyReportService.Week;
import org.junit.jupiter.api.Test;

import java.sql.Date;
import java.time.*;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class WeeklyReportServiceTest {
    static final ZoneId VN = ZoneId.of("Asia/Ho_Chi_Minh");

    @Test
    void rowsWithoutDataInEitherWeekAreHiddenNotZero() {
        Map<String, Object> out = WeeklyReportService.summarize(LocalDate.of(2026, 11, 16),
            new Week(null, null, 0L, 0L, 3L, 2), new Week(null, null, 0L, 0L, 1L, 4));
        @SuppressWarnings("unchecked") List<Map<String, Object>> rows = (List<Map<String, Object>>) out.get("rows");
        assertEquals(List.of("completed", "activeDays"), rows.stream().map(r -> r.get("key")).toList());
        assertEquals(1, rows.get(0).get("trend"));
        assertEquals(-1, rows.get(1).get("trend"));
        assertEquals("2026-11-22", out.get("weekEnd"));
    }

    @Test
    void planRowShowsDoneOfTotalAndStaysWhenOnlyLastWeekHadAPlan() {
        Map<String, Object> out = WeeklyReportService.summarize(LocalDate.of(2026, 11, 16),
            new Week(null, null, 50L, 0L, 0L, 0), new Week(2, 3, 0L, 0L, 0L, 0));
        @SuppressWarnings("unchecked") List<Map<String, Object>> rows = (List<Map<String, Object>>) out.get("rows");
        assertEquals("plan", rows.get(0).get("key"));
        assertEquals(0L, rows.get(0).get("value"));
        assertEquals(0, rows.get(0).get("total"));
        assertEquals(2L, rows.get(0).get("previous"));
        assertEquals("minutes", rows.get(1).get("key"));
        assertEquals(50L, rows.get(1).get("value"));
    }

    @Test
    void reportUsesMondayToSundayLocalWeeksAndTheStreak() {
        StudyPlanRepository plans = mock(StudyPlanRepository.class);
        StudySessionRepository sessions = mock(StudySessionRepository.class);
        FlashcardReviewRepository reviews = mock(FlashcardReviewRepository.class);
        InsightsRepository insights = mock(InsightsRepository.class);
        Clock clock = Clock.fixed(ZonedDateTime.of(2026, 11, 19, 10, 0, 0, 0, VN).toInstant(), VN); // Thursday
        when(insights.findStudentActivityByDay(eq(205L), anyLong())).thenReturn(List.of(
            Map.of("day", Date.valueOf("2026-11-17"), "events", 3L),
            Map.of("day", Date.valueOf("2026-11-18"), "events", 1L),
            Map.of("day", Date.valueOf("2026-11-19"), "events", 2L),
            Map.of("day", Date.valueOf("2026-11-10"), "events", 5L)));
        when(insights.findStudentCompletionsByDay(205L)).thenReturn(List.of(
            Map.of("day", Date.valueOf("2026-11-16"), "courseid", 14L, "completed", 2L),
            Map.of("day", Date.valueOf("2026-11-23"), "courseid", 14L, "completed", 9L)));   // next week
        when(plans.findRange(205L, LocalDate.of(2026, 11, 9), LocalDate.of(2026, 11, 22))).thenReturn(List.of(
            Map.of("plan_date", Date.valueOf("2026-11-17"), "status", "done"),
            Map.of("plan_date", Date.valueOf("2026-11-18"), "status", "planned"),
            Map.of("plan_date", Date.valueOf("2026-11-18"), "status", "skipped")));
        Instant mon = ZonedDateTime.of(2026, 11, 16, 0, 0, 0, 0, VN).toInstant();
        when(sessions.totalMinutes(eq(205L), isNull(), eq(mon), any())).thenReturn(75L);
        when(reviews.countReviewedBetween(eq(205L), eq(mon), any())).thenReturn(4L);
        var service = new WeeklyReportService(plans, sessions, reviews, insights, clock);
        Map<String, Object> out = service.report(205L, null);
        assertEquals("2026-11-16", out.get("weekStart"));
        assertEquals(3, out.get("streakDays"));
        @SuppressWarnings("unchecked") List<Map<String, Object>> rows = (List<Map<String, Object>>) out.get("rows");
        Map<String, Object> plan = rows.get(0);
        assertEquals(1L, plan.get("value"));
        assertEquals(2, plan.get("total"));
        Map<String, Map<String, Object>> byKey = new HashMap<>();
        for (Map<String, Object> r : rows) byKey.put((String) r.get("key"), r);
        assertEquals(75L, byKey.get("minutes").get("value"));
        assertEquals(4L, byKey.get("cards").get("value"));
        assertEquals(2L, byKey.get("completed").get("value"));
        assertEquals(3L, byKey.get("activeDays").get("value"));
        assertEquals(1L, byKey.get("activeDays").get("previous"));
    }
}
