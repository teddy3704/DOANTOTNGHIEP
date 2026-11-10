package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.exception.ResourceNotFoundException;
import com.dlu.lmsmobile.repository.LearningHealthRepository;
import org.junit.jupiter.api.Test;

import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class LearningHealthServiceTest {
    /** A monitoring row as both sides read it (teacher roster row uses the same column values). */
    static Map<String, Object> row(long course, Object inactive, long overdue, Double progress, long events,
                                   int stored, long completed, long total) {
        Map<String, Object> r = new HashMap<>();
        r.put("userid", 205L);
        r.put("courseid", course);
        r.put("course_name", "Course " + course);
        r.put("days_since_last_activity", inactive);
        r.put("overdue_tasks", overdue);
        r.put("progress_percentage", progress);
        r.put("events_last_7_days", events);
        r.put("risk_score", stored);
        r.put("completed_activities", completed);
        r.put("total_tracked_activities", total);
        return r;
    }

    @SuppressWarnings("unchecked")
    @Test
    void studentSeesExactlyTheTeachersScoreAndReasons() {
        Object[][] cases = {
            {15, 3L, 20.0, 0L, 100}, {null, 0L, 0.0, 0L, 75}, {8, 1L, 45.0, 2L, 50},
            {3, 0L, 85.0, 5L, 0}, {20, 4L, 10.0, 0L, 100},
        };
        for (Object[] c : cases) {
            Map<String, Object> studentRow = row(13, c[0], (long) c[1], (Double) c[2], (long) c[3], (int) c[4], 2, 7);
            // Teacher side: the class-insights student list built from the roster row of the same student.
            Map<String, Object> roster = new HashMap<>(studentRow);
            roster.put("progress", c[2]);
            roster.put("risk_level", "HIGH");
            Map<String, Object> teacher = ClassInsightsService.studentDetails(List.of(roster)).get(0);
            Map<String, Object> student = LearningHealthService.course(studentRow, null);

            List<Map<String, Object>> tReasons = (List<Map<String, Object>>) teacher.get("score_breakdown");
            assertEquals(tReasons, student.get("reasons"), Arrays.toString(c));
            int teacherSum = Math.min(100, tReasons.stream().mapToInt(p -> ((Number) p.get("points")).intValue()).sum());
            assertEquals(teacherSum, student.get("score"));
            // And both equal the score stored by derived.student_risk_indicator.
            assertEquals(c[4], student.get("score"), Arrays.toString(c));
            assertEquals(student.get("score"), student.get("storedScore"));
        }
    }

    @Test
    void levelsFollowTheSharedCutOffs() {
        assertEquals("GREEN", LearningHealthService.level(0));
        assertEquals("GREEN", LearningHealthService.level(29));
        assertEquals("YELLOW", LearningHealthService.level(30));
        assertEquals("YELLOW", LearningHealthService.level(59));
        assertEquals("RED", LearningHealthService.level(60));
    }

    @SuppressWarnings("unchecked")
    @Test
    void actionsAreAtMostThreeBiggestFirstAndMergeTheVisit() {
        Map<String, Object> next = Map.of("coursemoduleid", 24102L, "moodle_path", "/mod/quiz/view.php?id=24102",
            "activity_name", "Quiz 3.1");
        Map<String, Object> c = LearningHealthService.course(row(13, 20, 4L, 10.0, 0L, 100, 2, 20), next);
        List<Map<String, Object>> actions = (List<Map<String, Object>>) c.get("actions");
        assertEquals(3, actions.size());
        // inactive 40 + no events 10 merged into one visit; overdue 30; progress 25.
        assertEquals("OPEN_LMS", actions.get(0).get("target"));
        assertEquals(50, actions.get(0).get("scoreDrop"));
        assertEquals(24102L, actions.get(0).get("courseModuleId"));
        assertEquals("Hoàn thành 4 bài quá hạn", actions.get(1).get("title"));
        assertEquals("TASKS", actions.get(1).get("target"));
        // 30% of 20 = 6 activities, 2 done → 4 more.
        assertEquals("Hoàn thành thêm 4 hoạt động để đạt 30% tiến độ", actions.get(2).get("title"));
        assertEquals("RECOMMENDATIONS", actions.get(2).get("target"));
    }

    @Test
    void greenCourseHasNoActions() {
        Map<String, Object> c = LearningHealthService.course(row(13, 1, 0L, 90.0, 4L, 0, 9, 10), null);
        assertEquals("GREEN", c.get("level"));
        assertEquals(List.of(), c.get("actions"));
    }

    @SuppressWarnings("unchecked")
    @Test
    void overviewOnlyQueriesTheCallerAndSortsWorstFirst() {
        LearningHealthRepository repo = mock(LearningHealthRepository.class);
        when(repo.findRiskRows(205L, null)).thenReturn(List.of(
            row(13, 1, 0L, 90.0, 4L, 0, 9, 10), row(14, 20, 4L, 10.0, 0L, 100, 1, 10)));
        when(repo.findNextActivities(205L)).thenReturn(List.of());
        Map<String, Object> out = new LearningHealthService(repo).overview(205L);
        assertEquals("RED", out.get("level"));
        List<Map<String, Object>> courses = (List<Map<String, Object>>) out.get("courses");
        assertEquals(14L, courses.get(0).get("courseId"));
        assertEquals(Map.of("RED", 1L, "YELLOW", 0L, "GREEN", 1L), out.get("counts"));
        verify(repo).findRiskRows(205L, null);
        verify(repo).findNextActivities(205L);
        verifyNoMoreInteractions(repo);
        // Nothing identifying anyone appears in the payload.
        String json = out.toString();
        assertFalse(json.contains("userid"));
        assertFalse(json.contains("fullname"));
    }

    @Test
    void courseNotEnrolledIsNotFound() {
        LearningHealthRepository repo = mock(LearningHealthRepository.class);
        when(repo.findRiskRows(205L, 99L)).thenReturn(List.of());
        assertThrows(ResourceNotFoundException.class, () -> new LearningHealthService(repo).forCourse(205L, 99L));
    }
}
