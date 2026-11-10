package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.exception.InvalidRequestException;
import com.dlu.lmsmobile.repository.StudentDetailRepository;
import com.dlu.lmsmobile.repository.StudentRepository;
import com.dlu.lmsmobile.repository.StudyPlanRepository;
import org.junit.jupiter.api.Test;

import java.sql.Date;
import java.time.*;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class StudentCalendarServiceTest {
    static final ZoneId VN = ZoneId.of("Asia/Ho_Chi_Minh");

    static long epoch(int y, int m, int d, int h, int min) {
        return ZonedDateTime.of(y, m, d, h, min, 0, 0, VN).toEpochSecond();
    }

    static Map<String, Object> task(String type, long id, long due, String status) {
        Map<String, Object> m = new HashMap<>();
        m.put("task_type", type);
        m.put("source_id", id);
        m.put("title", "Bài " + id);
        m.put("courseid", 14L);
        m.put("course_name", "Mobile");
        m.put("due_time", due);
        m.put("task_status", status);
        m.put("moodle_path", "/mod/assign/view.php?id=9" + id);
        m.put("coursemoduleid", 90L + id);
        return m;
    }

    @Test
    void mergesThreeSourcesInsideTheRangeWithStableUids() {
        LocalDate from = LocalDate.of(2026, 11, 1), to = LocalDate.of(2026, 11, 30);
        List<Map<String, Object>> tasks = List.of(
            task("assignment", 1, epoch(2026, 11, 20, 23, 59), "pending"),
            task("quiz", 2, epoch(2026, 11, 30, 23, 59), "completed"),
            task("quiz", 3, epoch(2026, 12, 1, 0, 0), "pending"),   // first instant after the range
            task("assignment", 4, epoch(2026, 10, 31, 23, 59), "pending"),
            task("assignment", 5, 0, "pending"));                  // no deadline
        Map<String, Object> plan = new HashMap<>(Map.of("id", 7L, "plan_date", Date.valueOf("2026-11-16"),
            "course_id", 14L, "title", "Quiz 3", "planned_minutes", 45, "status", "planned"));
        Map<String, Object> skipped = new HashMap<>(plan);
        skipped.put("id", 8L);
        skipped.put("status", "skipped");
        Map<String, Object> session = new HashMap<>(Map.of("session_id", 55L, "sessdate", epoch(2026, 11, 18, 7, 30),
            "duration", 5400L, "attendance_name", "Điểm danh lớp"));
        var events = StudentCalendarService.assemble(from, to, VN, tasks, List.of(plan, skipped),
            List.of(Map.of("courseid", 14L, "course_name", "Mobile")), Map.of(14L, List.of(session)));

        assertEquals(List.of("plan-7@dlu-lms-group", "attendance-55@dlu-lms-group",
            "deadline-assign-1@dlu-lms-group", "deadline-quiz-2@dlu-lms-group"),
            events.stream().map(e -> e.get("uid")).toList());
        Map<String, Object> att = events.get(1);
        assertEquals("attendance", att.get("type"));
        assertEquals("Điểm danh: Điểm danh lớp", att.get("title"));
        assertEquals(Instant.ofEpochSecond(epoch(2026, 11, 18, 9, 0)).toString(), att.get("end"));
        assertEquals("Mobile", att.get("courseName"));
        Map<String, Object> planEvent = events.get(0);
        assertEquals(true, planEvent.get("allDay"));
        assertEquals("2026-11-16", planEvent.get("date"));
        assertEquals(true, events.get(3).get("done"));
        assertEquals(91L, events.get(2).get("courseModuleId"));
    }

    @Test
    void defaultRangeIsTheCurrentMonthAndRangesAreValidated() {
        StudentRepository students = mock(StudentRepository.class);
        StudentDetailRepository details = mock(StudentDetailRepository.class);
        StudyPlanRepository plans = mock(StudyPlanRepository.class);
        Clock clock = Clock.fixed(ZonedDateTime.of(2026, 11, 10, 9, 0, 0, 0, VN).toInstant(), VN);
        when(students.findCoursesByUserId(205L)).thenReturn(List.of(Map.of("courseid", 14L, "course_name", "Mobile")));
        when(students.findAllTasks(205L)).thenReturn(List.of());
        when(plans.findRange(eq(205L), any(), any())).thenReturn(List.of());
        when(details.findAttendanceSessions(205L, 14L)).thenReturn(List.of());
        var service = new StudentCalendarService(students, details, plans, clock);
        Map<String, Object> out = service.calendar(205L, null, null);
        assertEquals("2026-11-01", out.get("from"));
        assertEquals("2026-11-30", out.get("to"));
        assertEquals("Asia/Ho_Chi_Minh", out.get("timeZone"));
        verify(details).findAttendanceSessions(205L, 14L);   // only enrolled courses
        assertThrows(InvalidRequestException.class, () -> service.calendar(205L, "2026-11-30", "2026-11-01"));
        assertThrows(InvalidRequestException.class, () -> service.calendar(205L, "2026-01-01", "2026-12-31"));
        assertThrows(InvalidRequestException.class, () -> service.calendar(205L, "1/11/2026", null));
    }
}
