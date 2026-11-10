package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.exception.ResourceNotFoundException;
import com.dlu.lmsmobile.repository.QuizInsightsRepository;
import com.dlu.lmsmobile.repository.TeacherRepository;
import com.dlu.lmsmobile.service.QuizInsightsService.Finished;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class QuizInsightsServiceTest {
    static List<Finished> scores(Double... p) {
        List<Finished> out = new ArrayList<>();
        for (Double v : p) out.add(new Finished(v, 600L));
        return out;
    }

    @Test
    void noAttemptsAtAll() {
        var a = QuizInsightsService.analyze(List.of(), 10, 0, 1800);
        assertArrayEquals(new int[5], a.histogram());
        assertNull(a.mean());
        assertNull(a.medianSeconds());
        assertEquals(10, a.notAttempted());
        assertEquals(List.of("MANY_SKIPPED"), a.flags());
    }

    @Test
    void histogramBandsIncludingEdges() {
        var a = QuizInsightsService.analyze(scores(0.0, 19.99, 20.0, 59.0, 79.9, 80.0, 100.0, 120.0), 8, 8, 0);
        assertArrayEquals(new int[]{2, 1, 1, 1, 3}, a.histogram()); // 100 and >100 clamp into the top band
    }

    @Test
    void tooHardNeedsThreeGradedAttemptsBelowFifty() {
        assertEquals(List.of(), QuizInsightsService.analyze(scores(10.0, 20.0), 2, 2, 0).flags());
        assertEquals(List.of("TOO_HARD"), QuizInsightsService.analyze(scores(10.0, 20.0, 49.0), 3, 3, 0).flags());
        assertEquals(List.of(), QuizInsightsService.analyze(scores(40.0, 50.0, 60.0), 3, 3, 0).flags()); // mean 50
    }

    @Test
    void manySkippedAtFortyPercent() {
        assertEquals(List.of("MANY_SKIPPED"), QuizInsightsService.analyze(scores(90.0), 10, 6, 0).flags());
        assertEquals(List.of(), QuizInsightsService.analyze(scores(90.0), 10, 7, 0).flags());
    }

    @Test
    void tooFastOnlyWithATimeLimit() {
        List<Finished> quick = List.of(new Finished(90.0, 100L), new Finished(95.0, 200L), new Finished(80.0, 300L));
        assertEquals(List.of("TOO_FAST"), QuizInsightsService.analyze(quick, 3, 3, 1800).flags()); // 200 < 360
        assertEquals(List.of(), QuizInsightsService.analyze(quick, 3, 3, 900).flags());           // 200 ≥ 180
        assertEquals(List.of(), QuizInsightsService.analyze(quick, 3, 3, 0).flags());
        assertEquals(200L, QuizInsightsService.analyze(quick, 3, 3, 0).medianSeconds());
        List<Finished> even = List.of(new Finished(1.0, 100L), new Finished(1.0, 300L));
        assertEquals(200L, QuizInsightsService.analyze(even, 2, 2, 0).medianSeconds());
    }

    @Test
    void ungradedFinishedAttemptsCountForTimeNotForScore() {
        var a = QuizInsightsService.analyze(List.of(new Finished(null, 500L), new Finished(70.0, null)), 2, 2, 0);
        assertEquals(70.0, a.mean());
        assertEquals(500L, a.medianSeconds());
        assertEquals(2, a.finished());
    }

    @Test
    void serviceUsesRosterOnlyAndReturnsAggregates() {
        QuizInsightsRepository repo = mock(QuizInsightsRepository.class);
        TeacherRepository teachers = mock(TeacherRepository.class);
        when(teachers.hasCourse(102L, 14L)).thenReturn(true);
        when(teachers.findStudents(102L, 14L)).thenReturn(List.of(Map.of("userid", 1L), Map.of("userid", 2L),
            Map.of("userid", 3L), Map.of("userid", 4L), Map.of("userid", 5L)));
        when(repo.findQuizzes(102L, 14L)).thenReturn(List.of(Map.of("quiz_id", 7L, "quiz_name", "Quiz 5.1",
            "timeclose", 0L, "timelimit", 0L, "moodle_path", "/mod/quiz/view.php?id=70", "coursemoduleid", 70L)));
        when(repo.findLatestAttempts(14L)).thenReturn(List.of(
            attempt(7, 1, "finished", 30), attempt(7, 2, "finished", 40), attempt(7, 3, "inprogress", null),
            attempt(7, 99, "finished", 100))); // 99 is not in the roster: ignored
        var service = new QuizInsightsService(repo, teachers);
        @SuppressWarnings("unchecked")
        Map<String, Object> q = ((List<Map<String, Object>>) service.insights(102L, 14L).get("quizzes")).get(0);
        assertEquals(2, q.get("finished"));
        assertEquals(3, q.get("attempted"));
        assertEquals(2, q.get("notAttempted"));
        assertEquals(40.0, q.get("notAttemptedPercent"));
        assertEquals(35.0, q.get("meanPercent"));
        assertEquals(List.of(0, 1, 1, 0, 0), q.get("histogram"));
        assertEquals(List.of("MANY_SKIPPED"), q.get("flags"));
        assertEquals(List.of(4L, 5L), q.get("notAttemptedUserIds"));
        assertNull(q.get("timeClose"));
        assertEquals(70L, q.get("courseModuleId"));
        assertFalse(q.toString().contains("fullname"));
    }

    @Test
    void courseOfAnotherTeacherIsNotFound() {
        QuizInsightsRepository repo = mock(QuizInsightsRepository.class);
        TeacherRepository teachers = mock(TeacherRepository.class);
        when(teachers.hasCourse(102L, 99L)).thenReturn(false);
        assertThrows(ResourceNotFoundException.class, () -> new QuizInsightsService(repo, teachers).insights(102L, 99L));
        verifyNoInteractions(repo);
    }

    private static Map<String, Object> attempt(long quiz, long user, String state, Integer percent) {
        Map<String, Object> m = new HashMap<>();
        m.put("quiz_id", quiz);
        m.put("userid", user);
        m.put("state", state);
        m.put("timestart", 1000L);
        m.put("timefinish", "finished".equals(state) ? 1600L : 0L);
        m.put("percent", percent == null ? null : BigDecimal.valueOf(percent));
        return m;
    }
}
