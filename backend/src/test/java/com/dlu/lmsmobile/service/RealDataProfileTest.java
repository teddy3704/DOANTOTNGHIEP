package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.config.DataProfile;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/**
 * REAL-DATA-1: the real Moodle export has no access log, no attendance sessions, no quiz close
 * times and no names. Labels must say how numbers are computed, and missing sources must give
 * empty results of the right shape instead of errors.
 */
class RealDataProfileTest {

    @Test
    void profileDefaultsToDemoAndOnlyRealSwitchesLabels() {
        assertEquals("demo", new DataProfile(null).name());
        assertEquals("demo", new DataProfile("anything").name());
        assertFalse(new DataProfile("demo").handInsOnly());
        assertEquals("real", new DataProfile(" REAL ").name());
        assertTrue(DataProfile.real().handInsOnly());
    }

    @Test
    void realRiskReasonsSayHandInsNeverAccess() {
        List<Map<String, Object>> never = RiskScore.breakdown(null, 1, 10.0, 0, true);
        List<String> labels = never.stream().map(r -> (String) r.get("label")).toList();
        assertEquals(List.of("Chưa từng nộp bài hoặc làm bài kiểm tra", "1 bài quá hạn (1–2 bài)",
            "Tiến độ (theo hoạt động có chấm điểm) 10% (dưới 30%)",
            "Không nộp bài hoặc làm bài kiểm tra nào trong 7 ngày qua"), labels);
        assertTrue(labels.stream().noneMatch(l -> l.contains("truy cập")));
        assertEquals("12 ngày chưa nộp bài hoặc làm bài kiểm tra (7–13 ngày)",
            RiskScore.breakdown(12, 1, 90.0, 1, true).get(0).get("label"));
        assertEquals("20 ngày chưa nộp bài hoặc làm bài kiểm tra (≥14 ngày)",
            RiskScore.breakdown(20, 1, 90.0, 1, true).get(0).get("label"));
    }

    @Test
    void realNeverWatchesAStudentWhoOwesNothing() {
        // All work handed in (or only future deadlines): no inactivity points on hand-in data.
        assertEquals(0, RiskScore.total(RiskScore.breakdown(null, 0, 100.0, 0, true)));
        assertEquals(25, RiskScore.total(RiskScore.breakdown(40, 0, 10.0, 0, true)));
        // Demo (access log) keeps the original rule.
        assertEquals(50, RiskScore.total(RiskScore.breakdown(null, 0, 100.0, 0)));
    }

    @Test
    void realAndDemoGiveTheSamePointsOnlyTheWordingDiffers() {
        var demo = RiskScore.breakdown(9, 2, 45.0, 0);
        var real = RiskScore.breakdown(9, 2, 45.0, 0, true);
        assertEquals(RiskScore.total(demo), RiskScore.total(real));
        assertEquals(demo.stream().map(r -> r.get("code")).toList(), real.stream().map(r -> r.get("code")).toList());
        assertEquals("9 ngày không truy cập (7–13 ngày)", demo.get(0).get("label"));
    }

    @Test
    void learningHealthUsesTheRealWording() {
        Map<String, Object> row = new HashMap<>();
        row.put("courseid", 7L);
        row.put("course_name", "Môn A");
        row.put("days_since_last_activity", null);   // no hand-in yet
        row.put("overdue_tasks", 1L);
        row.put("progress_percentage", 0.0);
        row.put("events_last_7_days", 0L);
        row.put("total_tracked_activities", 0L);
        row.put("completed_activities", 0L);
        Map<String, Object> c = LearningHealthService.course(row, null, true);
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> reasons = (List<Map<String, Object>>) c.get("reasons");
        assertEquals("Chưa từng nộp bài hoặc làm bài kiểm tra", reasons.get(0).get("label"));
        assertEquals(90, c.get("score"));

        // Visiting a forum would not change a hand-in based score: the action asks for a hand-in instead.
        Map<String, Object> forum = new HashMap<>(Map.of("activity_type", "forum", "activity_name", "Diễn đàn · Chung",
            "moodle_path", "/mod/forum/view.php?id=1", "coursemoduleid", 1L));
        Map<String, Object> withNext = LearningHealthService.course(row, forum, true);
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> actions = (List<Map<String, Object>>) withNext.get("actions");
        Map<String, Object> visit = actions.stream().filter(a -> "VISIT_COURSE".equals(a.get("code"))).findFirst().orElseThrow();
        assertEquals("TASKS", visit.get("target"));
        assertEquals("Nộp bài hoặc làm bài kiểm tra trên LMS", visit.get("title"));
        assertNull(visit.get("moodlePath"));
    }

    @Test
    void realInactivityNoticesOnlyForCurrentTermCoursesAndSayHandIns() {
        Map<String, Object> old = new HashMap<>(Map.of("courseid", 1L, "course_name", "Môn cũ", "days_since_last_activity", 700));
        Map<String, Object> now = new HashMap<>(Map.of("courseid", 2L, "course_name", "Môn kỳ này", "days_since_last_activity", 20));
        Map<String, Object> status = Map.of("overdue", 0L, "due_soon", 0L, "total", 0L);
        var out = InsightsService.suggestions(status, List.of(old, now), Map.of("current_days", 0L), List.of(), java.util.Set.of(2L));
        List<Object> titles = out.stream().map(m -> m.get("title")).toList();
        assertEquals(List.of("20 ngày chưa nộp bài hoặc làm bài kiểm tra ở Môn kỳ này"),
            titles.stream().filter(t -> String.valueOf(t).contains("ngày")).toList());
        var demo = InsightsService.suggestions(status, List.of(old), Map.of("current_days", 0L), List.of());
        assertTrue(demo.stream().anyMatch(m -> "Chưa có hoạt động ở Môn cũ trong 700 ngày".equals(m.get("title"))));
    }

    @Test
    void quizWithoutCloseTimeIsNeverADatedDeadlineNorOverdue() {
        long now = 1_794_500_000L;
        Map<String, Object> quiz = new HashMap<>(Map.of("task_type", "quiz", "source_id", 1L, "title", "Kiểm tra 1",
            "courseid", 7L, "course_name", "Môn A", "due_time", 0L, "task_status", "pending"));
        Map<String, Object> assign = new HashMap<>(Map.of("task_type", "assignment", "source_id", 2L, "title", "Bài 1",
            "courseid", 7L, "course_name", "Môn A", "due_time", now + 3600, "task_status", "pending"));
        List<Map<String, Object>> deadlines = InsightsService.upcomingDeadlines(List.of(quiz, assign), now);
        assertEquals(List.of("Bài 1"), deadlines.stream().map(d -> d.get("title")).toList());
        Map<String, Object> status = InsightsService.taskStatus(List.of(quiz), now);
        assertNotNull(status);
        assertFalse(String.valueOf(status).contains("overdue=1"));
    }

    @Test
    void calendarWithNoAttendanceSessionsAndNoQuizCloseTimeIsEmptyNotAnError() {
        ZoneId vn = ZoneId.of("Asia/Ho_Chi_Minh");
        Map<String, Object> quiz = new HashMap<>(Map.of("task_type", "quiz", "source_id", 1L, "title", "Kiểm tra 1",
            "courseid", 7L, "course_name", "Môn A", "due_time", 0L, "task_status", "pending"));
        var events = StudentCalendarService.assemble(LocalDate.of(2026, 11, 1), LocalDate.of(2026, 11, 30), vn,
            List.of(quiz), List.of(), List.of(Map.of("courseid", 7L, "course_name", "Môn A")), Map.of());
        assertTrue(events.isEmpty());
    }

    @Test
    void realInsightsAreNotLabelledAsDemoDataAndCountHandIns() {
        var real = new InsightsService(null, null, null, java.time.Clock.systemUTC(), "demo", DataProfile.real());
        var demo = new InsightsService(null, null, null, java.time.Clock.systemUTC(), "demo");
        assertEquals("live", real.dataMode());
        assertEquals("demo", demo.dataMode());
        assertEquals("lượt nộp bài và làm bài kiểm tra / ngày", InsightsService.heatmapUnit(true));
        assertEquals("sự kiện học tập / ngày", InsightsService.heatmapUnit(false));
        // No hand-in at all: an empty heat map of the right shape, not an error.
        Map<String, Object> heat = InsightsService.heatmap(Map.of(), LocalDate.of(2026, 11, 1), LocalDate.of(2026, 11, 7));
        assertEquals(false, heat.get("has_data"));
        assertEquals(7, ((List<?>) heat.get("days")).size());
    }
}
