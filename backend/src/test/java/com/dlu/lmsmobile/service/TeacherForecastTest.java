package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.exception.ResourceNotFoundException;
import com.dlu.lmsmobile.repository.ForecastRepository;
import com.dlu.lmsmobile.repository.InsightsRepository;
import com.dlu.lmsmobile.repository.TeacherRepository;
import org.junit.jupiter.api.Test;

import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/** V2-N4 uses the N1 engine per student; these cases pin the class view on top of it. */
@SuppressWarnings("unchecked")
class TeacherForecastTest {
    static Map<String, Object> itemRow(long id, long cat) {
        Map<String, Object> m = new HashMap<>();
        m.put("grade_item_id", id);
        m.put("activity_type", "assign");
        m.put("source_id", id);
        m.put("activity_name", "Item " + id);
        m.put("category_id", cat);
        m.put("parent_category_id", 1L);
        m.put("grademax", 100.0);
        m.put("gradepass", 50.0);
        m.put("module_visible", true);
        return m;
    }

    static Map<String, Object> gradeRow(long user, long item, double pct) {
        return Map.of("userid", user, "grade_item_id", item, "grade_percentage", pct);
    }

    static Map<String, Object> student(long id, String name) {
        Map<String, Object> m = new HashMap<>();
        m.put("userid", id);
        m.put("fullname", name);
        m.put("student_code", "SV" + id);
        return m;
    }

    GradeForecastService service(TeacherRepository teachers, ForecastRepository repo) {
        return new GradeForecastService(repo, mock(InsightsRepository.class), teachers);
    }

    @Test
    void everyRosterStudentGetsABandAndTheListIsMostUrgentFirst() {
        TeacherRepository teachers = mock(TeacherRepository.class);
        when(teachers.hasCourse(102L, 13L)).thenReturn(true);
        when(teachers.findStudents(102L, 13L)).thenReturn(List.of(
            student(201, "An"), student(202, "Binh"), student(203, "Chi"), student(204, "Dung")));
        ForecastRepository repo = mock(ForecastRepository.class);
        // Four equal-weight items (two sub-categories of two).
        when(repo.findCourseGradeItems(13L)).thenReturn(List.of(itemRow(1, 10), itemRow(2, 10), itemRow(3, 20), itemRow(4, 20)));
        when(repo.findCourseGrades(eq(13L), isNull())).thenReturn(List.of(
            gradeRow(201, 1, 100), gradeRow(201, 2, 100),              // 50 banked → sure pass
            gradeRow(202, 1, 50), gradeRow(202, 2, 30),                // 20 banked → need 60 → SAFE
            gradeRow(203, 1, 0), gradeRow(203, 2, 0), gradeRow(203, 3, 0), // 0 banked, one left (w .25) → need 200
            gradeRow(204, 1, 10), gradeRow(204, 2, 10)));              // 5 banked → need 90 → HIGH_RISK
        Map<String, Object> out = service(teachers, repo).teacherForecast(102L, 13L);

        Map<String, Long> counts = (Map<String, Long>) out.get("counts");
        assertEquals(1L, counts.get("SURE_PASS"));
        assertEquals(1L, counts.get("SAFE"));
        assertEquals(1L, counts.get("HIGH_RISK"));
        assertEquals(1L, counts.get("NOT_FEASIBLE"));
        List<Map<String, Object>> students = (List<Map<String, Object>>) out.get("students");
        assertEquals(List.of("Chi", "Dung", "Binh", "An"), students.stream().map(s -> s.get("fullname")).toList());
        assertEquals(60.0, students.get(2).get("need"));
        assertEquals(50.0, students.get(3).get("worstCase"));
        assertEquals(25.0, students.get(0).get("bestCase"));
        assertEquals(50.0, out.get("passPercent"));
        // Only one course-wide grade query, never per student.
        verify(repo, times(1)).findCourseGrades(eq(13L), isNull());
    }

    @Test
    void studentWithoutAnyGradeNeedsThePassMarkEverywhere() {
        Map<String, Object> out = GradeForecastService.classJson(List.of(student(205, "Giang")),
            Map.of(205L, GradeForecastService.forecast(List.of(GradeForecastServiceTest.sub(1, 10)), Map.of())));
        Map<String, Object> s = ((List<Map<String, Object>>) out.get("students")).get(0);
        assertEquals("SAFE", s.get("band"));
        assertEquals(50.0, s.get("need"));
        assertNull(s.get("current"));
        assertEquals(0L, s.get("gradedCount"));
    }

    @Test
    void anotherTeachersCourseIsNotFoundAndLoadsNothing() {
        TeacherRepository teachers = mock(TeacherRepository.class);
        when(teachers.hasCourse(102L, 99L)).thenReturn(false);
        ForecastRepository repo = mock(ForecastRepository.class);
        assertThrows(ResourceNotFoundException.class, () -> service(teachers, repo).teacherForecast(102L, 99L));
        verifyNoInteractions(repo);
        verify(teachers, never()).findStudents(anyLong(), anyLong());
    }
}
