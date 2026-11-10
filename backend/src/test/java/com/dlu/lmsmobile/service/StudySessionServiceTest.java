package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.exception.InvalidRequestException;
import com.dlu.lmsmobile.exception.ResourceNotFoundException;
import com.dlu.lmsmobile.repository.InsightsRepository;
import com.dlu.lmsmobile.repository.StudentRepository;
import com.dlu.lmsmobile.repository.StudyPlanRepository;
import com.dlu.lmsmobile.repository.StudySessionRepository;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.*;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class StudySessionServiceTest {
    static final ZoneId VN = ZoneId.of("Asia/Ho_Chi_Minh");
    static final Instant NOW = ZonedDateTime.of(2026, 11, 18, 10, 0, 0, 0, VN).toInstant();
    final Clock clock = Clock.fixed(NOW, VN);
    final StudySessionRepository sessions = mock(StudySessionRepository.class);
    final StudyPlanRepository plans = mock(StudyPlanRepository.class);
    final InsightsRepository insights = mock(InsightsRepository.class);
    final StudentRepository students = mock(StudentRepository.class);
    final StudySessionService service = new StudySessionService(sessions, plans, insights, students, clock);

    static Instant ago(int minutes) {
        return NOW.minus(Duration.ofMinutes(minutes));
    }

    @Test
    void validationTable() {
        Object[][] cases = {
            // started, ended, focus, ok?
            {ago(25), NOW, 25, true},
            {ago(25), NOW, 26, true},              // +1 minute rounding tolerance
            {ago(25), NOW, 27, false},             // longer than the session
            {ago(30), ago(5), 25, true},
            {NOW, ago(5), 5, false},               // ends before it starts
            {NOW, NOW, 1, false},                  // zero length
            {ago(10), NOW.plusSeconds(30), 10, true},  // within clock skew
            {ago(10), NOW.plusSeconds(300), 10, false}, // in the future
            {ago(3 * 24 * 60), ago(3 * 24 * 60 - 30), 25, false}, // too old
            {ago(200), NOW, 181, false},           // above 180
            {ago(5), NOW, 0, false},
            {ago(5), NOW, null, false},
            {null, NOW, 5, false},
        };
        for (Object[] c : cases) {
            String err = StudySessionService.validate((Instant) c[0], (Instant) c[1], (Integer) c[2], NOW);
            assertEquals(c[3], err == null, Arrays.toString(c) + " -> " + err);
        }
    }

    private Map<String, Object> body(Object... kv) {
        Map<String, Object> m = new HashMap<>();
        m.put("startedAt", OffsetDateTime.ofInstant(ago(25), VN).toString());
        m.put("endedAt", OffsetDateTime.ofInstant(NOW, VN).toString());
        m.put("focusMinutes", 25);
        for (int i = 0; i < kv.length; i += 2) m.put((String) kv[i], kv[i + 1]);
        return m;
    }

    @Test
    void recordsAndMarksThePlanItemDone() {
        when(insights.isEnrolled(205L, 13L)).thenReturn(true);
        when(plans.findOwned(205L, 9L)).thenReturn(List.of(Map.of("id", 9L)));
        when(sessions.insert(eq(205L), eq(13L), eq(9L), any(), any(), eq(25))).thenReturn(77L);
        Map<String, Object> out = service.record(205L, body("courseId", 13, "planItemId", 9, "markPlanItemDone", true));
        assertEquals(77L, out.get("id"));
        assertEquals(true, out.get("planItemDone"));
        verify(sessions).insert(205L, 13L, 9L, ago(25), NOW, 25);
        verify(plans).updateStatus(205L, 9L, "done");
    }

    @Test
    void withoutCourseOrPlanItemIsAllowed() {
        service.record(205L, body());
        verify(sessions).insert(205L, null, null, ago(25), NOW, 25);
        verifyNoInteractions(plans);
    }

    @Test
    void notEnrolledCourseOrForeignPlanItemIsNotFoundAndNothingIsWritten() {
        when(insights.isEnrolled(205L, 99L)).thenReturn(false);
        assertThrows(ResourceNotFoundException.class, () -> service.record(205L, body("courseId", 99)));
        when(plans.findOwned(205L, 8L)).thenReturn(List.of());
        assertThrows(ResourceNotFoundException.class,
            () -> service.record(205L, body("planItemId", 8, "markPlanItemDone", true)));
        verify(sessions, never()).insert(anyLong(), any(), any(), any(), any(), anyInt());
        verify(plans, never()).updateStatus(anyLong(), anyLong(), anyString());
    }

    @Test
    void invalidBodiesAreRejected() {
        for (Map<String, Object> b : List.of(body("focusMinutes", 40), body("startedAt", "yesterday"),
            body("focusMinutes", "25"), body("courseId", "13"), body("markPlanItemDone", true))) {
            assertThrows(InvalidRequestException.class, () -> service.record(205L, b), b.toString());
        }
        assertThrows(InvalidRequestException.class, () -> service.record(205L, null));
        verifyNoInteractions(sessions);
    }

    @Test
    void summaryFillsEveryDayAndGroupsByCourse() {
        Map<Long, String> names = Map.of(13L, "Software Testing", 14L, "Mobile");
        List<Map<String, Object>> rows = List.of(
            row(LocalDate.of(2026, 11, 16), 13L, 50, 2),
            row(LocalDate.of(2026, 11, 16), null, 25, 1),
            row(LocalDate.of(2026, 11, 18), 14L, 100, 2),
            row(LocalDate.of(2026, 11, 30), 14L, 999, 9)); // outside the range: ignored
        Map<String, Object> s = StudySessionService.summarize(LocalDate.of(2026, 11, 12), LocalDate.of(2026, 11, 18),
            rows, names);
        assertEquals(175L, s.get("totalMinutes"));
        assertEquals(5L, s.get("sessions"));
        @SuppressWarnings("unchecked") List<Map<String, Object>> days = (List<Map<String, Object>>) s.get("days");
        assertEquals(7, days.size());
        assertEquals("2026-11-12", days.get(0).get("date"));
        assertEquals(0L, days.get(0).get("minutes"));
        assertEquals(75L, days.get(4).get("minutes"));
        @SuppressWarnings("unchecked") List<Map<String, Object>> courses = (List<Map<String, Object>>) s.get("courses");
        assertEquals(List.of(14L, 13L), courses.stream().filter(c -> c.get("courseId") != null)
            .map(c -> c.get("courseId")).toList());
        assertEquals("Mobile", courses.get(0).get("courseName"));
    }

    @Test
    void summaryDefaultsToTheLastSevenLocalDaysAndValidatesRange() {
        when(students.findCoursesByUserId(205L)).thenReturn(List.of());
        when(sessions.minutesByDayAndCourse(anyLong(), any(), any())).thenReturn(List.of());
        Map<String, Object> s = service.summary(205L, null, null);
        assertEquals("2026-11-12", s.get("from"));
        assertEquals("2026-11-18", s.get("to"));
        verify(sessions).minutesByDayAndCourse(205L,
            ZonedDateTime.of(2026, 11, 12, 0, 0, 0, 0, VN).toInstant(),
            ZonedDateTime.of(2026, 11, 19, 0, 0, 0, 0, VN).toInstant());
        assertThrows(InvalidRequestException.class, () -> service.summary(205L, "2026-11-18", "2026-11-01"));
        assertThrows(InvalidRequestException.class, () -> service.summary(205L, "2026-01-01", "2026-11-01"));
        assertThrows(InvalidRequestException.class, () -> service.summary(205L, "x", null));
    }

    @Test
    void studyMinutesGoalSumsSessionsFromStartThroughToday() {
        InsightsRepository repo = mock(InsightsRepository.class);
        GoalService goals = new GoalService(repo, students, clock, sessions);
        when(students.findCoursesByUserId(205L)).thenReturn(List.of());
        when(sessions.totalMinutes(eq(205L), isNull(), any(), any())).thenReturn(120L);
        Map<String, Object> goal = new HashMap<>();
        goal.put("id", 1L);
        goal.put("goal_type", "study_minutes");
        goal.put("target_value", new BigDecimal("300"));
        goal.put("status", "active");
        goal.put("start_date", java.sql.Date.valueOf(LocalDate.of(2026, 11, 16)));
        goal.put("end_date", java.sql.Date.valueOf(LocalDate.of(2026, 11, 22)));
        Map<String, Object> out = goals.evaluate(205L, List.of(goal)).get(0);
        assertEquals(120.0, out.get("current_value"));
        assertEquals(40.0, out.get("progress_percent"));
        assertEquals("phút", out.get("unit"));
        assertEquals("active", out.get("status"));
        verify(sessions).totalMinutes(205L, null, ZonedDateTime.of(2026, 11, 16, 0, 0, 0, 0, VN).toInstant(),
            ZonedDateTime.of(2026, 11, 19, 0, 0, 0, 0, VN).toInstant());

        when(sessions.totalMinutes(eq(205L), isNull(), any(), any())).thenReturn(300L);
        assertEquals("completed", goals.evaluate(205L, List.of(goal)).get(0).get("status"));
    }

    private static Map<String, Object> row(LocalDate day, Long course, long minutes, long n) {
        Map<String, Object> m = new HashMap<>();
        m.put("day", java.sql.Date.valueOf(day));
        m.put("course_id", course);
        m.put("minutes", minutes);
        m.put("sessions", n);
        return m;
    }
}
