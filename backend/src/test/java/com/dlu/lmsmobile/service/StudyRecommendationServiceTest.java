package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.service.StudyRecommendationService.ClassStat;
import org.junit.jupiter.api.Test;

import java.util.*;

import static org.junit.jupiter.api.Assertions.*;

@SuppressWarnings("unchecked")
class StudyRecommendationServiceTest {
    static final long NOW = 1_790_000_000L;

    static Map<String, Object> item(long cm, long section, String type, long source, String name, int completion,
                                    Long due, String taskStatus) {
        Map<String, Object> m = new HashMap<>();
        m.put("coursemoduleid", cm);
        m.put("section_id", 100 + section);
        m.put("section_number", section);
        m.put("section_name", "Chương " + section);
        m.put("activity_type", type);
        m.put("source_id", source);
        m.put("activity_name", name);
        m.put("completionstate", completion);
        m.put("due_time", due);
        m.put("task_status", taskStatus);
        m.put("moodle_path", "/mod/" + type + "/view.php?id=" + cm);
        return m;
    }

    static Map<String, Object> grade(String type, long source, Double pct) {
        Map<String, Object> m = new HashMap<>();
        m.put("activity_type", type);
        m.put("source_id", source);
        m.put("grade_percentage", pct);
        m.put("grademax", 100.0);
        m.put("gradepass", 50.0);
        return m;
    }

    @Test
    void chapterBelowPassIsWeakAndSuggestsUnreadMaterialFirst() {
        List<Map<String, Object>> items = List.of(
            item(1, 3, "resource", 11, "Slide chương 3", 0, null, null),
            item(2, 3, "resource", 12, "Bài đọc chương 3", 0, null, null),
            item(3, 3, "quiz", 31, "Quiz 3.1", 1, NOW - 100, "completed"),
            item(4, 1, "quiz", 41, "Quiz 1.1", 1, NOW - 100, "completed"));
        List<Map<String, Object>> chapters = StudyRecommendationService.recommend(items,
            List.of(grade("quiz", 31, 20.0), grade("quiz", 41, 90.0)), Map.of(), 50, NOW);
        assertEquals(1, chapters.size());
        Map<String, Object> ch = chapters.get(0);
        assertEquals("Chương 3", ch.get("sectionName"));
        assertEquals(List.of("Trung bình chương 20,0% dưới ngưỡng qua 50,0%"), ch.get("reasons"));
        List<Map<String, Object>> s = (List<Map<String, Object>>) ch.get("suggestions");
        assertEquals(List.of("Slide chương 3", "Bài đọc chương 3", "Quiz 3.1"),
            s.stream().map(x -> x.get("activityName")).toList());
        assertEquals("Quiz 3.1: 20,0%", s.get(2).get("reason"));
    }

    @Test
    void chapterWithoutGradesIsOnlyWeakWhenGradedWorkIsOverdue() {
        List<Map<String, Object>> noGrades = List.of(item(1, 2, "resource", 11, "Tài liệu", 0, null, null),
            item(2, 2, "assign", 21, "Bài tập 2", 0, NOW + 86400, "pending"));
        assertTrue(StudyRecommendationService.recommend(noGrades, List.of(), Map.of(), 50, NOW).isEmpty());

        List<Map<String, Object>> overdue = List.of(item(1, 2, "resource", 11, "Tài liệu", 0, null, null),
            item(2, 2, "assign", 21, "Bài tập 2", 0, NOW - 86400, "overdue"));
        Map<String, Object> ch = StudyRecommendationService.recommend(overdue, List.of(), Map.of(), 50, NOW).get(0);
        assertNull(ch.get("average"));
        assertEquals(1, ch.get("overdueCount"));
        assertEquals(List.of("1 bài tính điểm đã quá hạn, chưa hoàn thành"), ch.get("reasons"));
        List<Map<String, Object>> s = (List<Map<String, Object>>) ch.get("suggestions");
        assertEquals("Tài liệu", s.get(0).get("activityName"));
        assertTrue(s.get(1).get("reason").toString().startsWith("Quá hạn từ "));
    }

    @Test
    @SuppressWarnings("unchecked")
    void realExportNeverCallsUntrackedMaterialUnfinished() {
        // REAL-DATA-1: no completion data for ungraded material; only graded (tracked) work is "chưa hoàn thành".
        Map<String, Object> link = item(1, 2, "url", 11, "Liên kết · Chương 2", 0, null, null);
        link.put("completion_tracking", 0);
        Map<String, Object> work = item(2, 2, "assign", 21, "Bài tập 2", 0, NOW - 86400, "overdue");
        work.put("completion_tracking", 1);
        Map<String, Object> ch = StudyRecommendationService.recommend(List.of(link, work), List.of(), Map.of(), 50, NOW, true).get(0);
        List<Map<String, Object>> s = (List<Map<String, Object>>) ch.get("suggestions");
        assertEquals(1, s.size());
        assertEquals("Bài tập 2", s.get(0).get("activityName"));
        assertTrue(s.stream().noneMatch(x -> "Chưa hoàn thành trong chương này".equals(x.get("reason"))));
    }

    @Test
    void submittedWorkIsNotOverdue() {
        List<Map<String, Object>> items = List.of(item(2, 2, "assign", 21, "Bài tập 2", 0, NOW - 86400, "submitted"));
        assertTrue(StudyRecommendationService.recommend(items, List.of(), Map.of(), 50, NOW).isEmpty());
    }

    @Test
    void chapterWeakBecauseTheClassIsHigherUsesOnlyLargeEnoughClasses() {
        List<Map<String, Object>> items = List.of(item(3, 3, "quiz", 31, "Quiz 3.1", 1, NOW - 10, "completed"));
        List<Map<String, Object>> mine = List.of(grade("quiz", 31, 60.0));
        // Class 75 with 15 graded → gap 15 ≥ 10 → weak even though 60 passes.
        Map<String, Object> ch = StudyRecommendationService.recommend(items, mine,
            Map.of("quiz:31", new ClassStat(75.0, 15)), 50, NOW).get(0);
        assertEquals(List.of("Thấp hơn trung bình lớp 15,0 điểm (lớp 75,0%)"), ch.get("reasons"));
        assertEquals(75.0, ch.get("classAverage"));
        assertEquals("Quiz 3.1: 60,0% (lớp 75,0%)",
            ((List<Map<String, Object>>) ch.get("suggestions")).get(0).get("reason"));
        // Same numbers but only 4 graded students: the class figure is withheld, chapter not weak.
        assertTrue(StudyRecommendationService.recommend(items, mine,
            Map.of("quiz:31", new ClassStat(75.0, 4)), 50, NOW).isEmpty());
        // Gap below 10 points is not weak.
        assertTrue(StudyRecommendationService.recommend(items, mine,
            Map.of("quiz:31", new ClassStat(69.0, 15)), 50, NOW).isEmpty());
    }

    @Test
    void atMostThreeSuggestionsAndMostSevereChapterFirst() {
        List<Map<String, Object>> items = new ArrayList<>();
        for (int k = 1; k <= 5; k++) items.add(item(k, 4, "resource", 10 + k, "Tài liệu " + k, 0, null, null));
        items.add(item(20, 4, "quiz", 41, "Quiz 4", 1, NOW - 10, "completed"));
        items.add(item(30, 5, "quiz", 51, "Quiz 5", 1, NOW - 10, "completed"));
        List<Map<String, Object>> chapters = StudyRecommendationService.recommend(items,
            List.of(grade("quiz", 41, 45.0), grade("quiz", 51, 0.0)), Map.of(), 50, NOW);
        assertEquals(2, chapters.size());
        assertEquals("Chương 5", chapters.get(0).get("sectionName"));   // severity 50 > 5
        assertEquals(50.0, chapters.get(0).get("severity"));
        List<Map<String, Object>> s = (List<Map<String, Object>>) chapters.get(1).get("suggestions");
        assertEquals(3, s.size());
    }

    @Test
    void passThresholdFollowsTheGradeItems() {
        Map<String, Object> g = grade("quiz", 1, 10.0);
        g.put("grademax", 10.0);
        g.put("gradepass", 6.0);
        assertEquals(60.0, StudyRecommendationService.passPercent(List.of(g)));
        assertEquals(50.0, StudyRecommendationService.passPercent(List.of()));
    }
}
