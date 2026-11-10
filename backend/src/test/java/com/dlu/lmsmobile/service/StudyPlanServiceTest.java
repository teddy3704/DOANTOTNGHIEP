package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.exception.InvalidRequestException;
import com.dlu.lmsmobile.exception.ResourceNotFoundException;
import com.dlu.lmsmobile.repository.FlashcardReviewRepository;
import com.dlu.lmsmobile.repository.StudentRepository;
import com.dlu.lmsmobile.repository.StudyPlanRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.sql.Date;
import java.time.*;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/** V2-N6 service: task selection from LMS rows, persistence (keep done), status changes. */
@SuppressWarnings("unchecked")
class StudyPlanServiceTest {
    static final ZoneId VN = ZoneId.of("Asia/Ho_Chi_Minh");
    static final Instant NOW = LocalDate.of(2026, 11, 16).atTime(8, 0).atZone(VN).toInstant();
    static final LocalDate TODAY = LocalDate.of(2026, 11, 16);

    StudentRepository students;
    FlashcardReviewRepository cards;
    StudyRecommendationService recommendations;
    StudyPlanRepository plans;
    StudyPlanService service;

    static long epoch(LocalDate d) {
        return d.atTime(23, 59).atZone(VN).toEpochSecond();
    }

    static Map<String, Object> task(String type, long id, String status, LocalDate due, String sourceStatus, String quizState) {
        Map<String, Object> m = new HashMap<>();
        m.put("task_type", type);
        m.put("source_id", id);
        m.put("courseid", 13L);
        m.put("title", type + " " + id);
        m.put("task_status", status);
        m.put("due_time", due == null ? null : epoch(due));
        m.put("source_status", sourceStatus);
        m.put("quiz_state", quizState);
        return m;
    }

    @BeforeEach
    void setup() {
        students = mock(StudentRepository.class);
        cards = mock(FlashcardReviewRepository.class);
        recommendations = mock(StudyRecommendationService.class);
        plans = mock(StudyPlanRepository.class);
        when(students.findAllTasks(205L)).thenReturn(List.of(
            task("assignment", 1, "overdue", TODAY.minusDays(5), "new", null),
            task("quiz", 2, "pending", TODAY.plusDays(3), null, null),
            task("assignment", 3, "pending", TODAY.plusDays(3), "submitted", null),   // submitted → done
            task("quiz", 4, "pending", TODAY.plusDays(2), null, "finished"),         // finished → done
            task("quiz", 5, "completed", TODAY.plusDays(2), null, null),
            task("quiz", 6, "pending", TODAY.plusDays(20), null, null),              // beyond 14 days
            task("assignment", 7, "pending", null, "new", null)));                  // no deadline
        when(cards.findDue(eq(205L), isNull(), any())).thenReturn(List.of(Map.of(), Map.of(), Map.of()));
        when(recommendations.overall(205L, 3)).thenReturn(Map.of("chapters", List.of(Map.of("courseId", 13L,
            "suggestions", List.of(Map.of("activityName", "Slide chương 2", "courseModuleId", 501L))))));
        when(plans.findRange(eq(205L), any(), any())).thenReturn(List.of());
        service = new StudyPlanService(students, cards, recommendations, plans, Clock.fixed(NOW, VN));
    }

    @Test
    void selectsOnlyPendingTasksWithADeadlineInRange() {
        List<StudyPlanner.Task> t = service.lmsTasks(205L, TODAY);
        assertEquals(List.of(1L, 2L), t.stream().map(StudyPlanner.Task::sourceId).toList());
        assertEquals(StudyPlanner.Kind.OVERDUE, t.get(0).kind());
        assertEquals("assign", t.get(0).sourceType());
        assertEquals(StudyPlanner.Kind.DEADLINE, t.get(1).kind());
    }

    @Test
    void generateReplacesPlannedItemsAndReportsTheWeek() {
        Map<String, Object> out = service.generate(205L, 90);
        ArgumentCaptor<List<StudyPlanRepository.NewItem>> rows = ArgumentCaptor.forClass(List.class);
        verify(plans).replacePlanned(eq(205L), eq(TODAY), rows.capture());
        List<StudyPlanRepository.NewItem> r = rows.getValue();
        // Mon: overdue assignment 90; Tue: quiz 45 + cards 5? no — cards are today-only and today is full → dropped
        assertEquals(List.of("assign", "quiz", "resource"), r.stream().map(StudyPlanRepository.NewItem::sourceType).toList());
        assertEquals(TODAY, r.get(0).planDate());
        assertEquals(90, r.get(0).plannedMinutes());
        assertEquals(TODAY.plusDays(1), r.get(1).planDate());
        assertEquals("Ôn lại: Slide chương 2", r.get(2).title());
        assertEquals(90, out.get("dailyMinutes"));
        assertEquals(7, ((List<?>) out.get("days")).size());
        assertEquals(List.of(), out.get("overloaded"));
    }

    @Test
    void flashcardsGetTodayWhenThereIsRoom() {
        when(students.findAllTasks(205L)).thenReturn(List.of());
        service.generate(205L, 30);
        ArgumentCaptor<List<StudyPlanRepository.NewItem>> rows = ArgumentCaptor.forClass(List.class);
        verify(plans).replacePlanned(eq(205L), eq(TODAY), rows.capture());
        StudyPlanRepository.NewItem first = rows.getValue().get(0);
        assertEquals("flashcards", first.sourceType());
        assertEquals("Ôn 3 thẻ ghi nhớ", first.title());
        assertEquals(5, first.plannedMinutes()); // ceil(3 × 1.5)
    }

    @Test
    void doneFlashcardReviewTodayIsNotPlannedAgainButYesterdaysIs() {
        when(students.findAllTasks(205L)).thenReturn(List.of());
        Map<String, Object> doneToday = new HashMap<>();
        doneToday.put("id", 7L);
        doneToday.put("plan_date", Date.valueOf(TODAY));
        doneToday.put("source_type", "flashcards");
        doneToday.put("source_id", null);
        doneToday.put("planned_minutes", 5);
        doneToday.put("status", "done");
        when(plans.findRange(eq(205L), any(), any())).thenReturn(List.of(doneToday));
        service.generate(205L, 30);
        ArgumentCaptor<List<StudyPlanRepository.NewItem>> rows = ArgumentCaptor.forClass(List.class);
        verify(plans).replacePlanned(eq(205L), eq(TODAY), rows.capture());
        assertTrue(rows.getValue().stream().noneMatch(i -> "flashcards".equals(i.sourceType())));

        Map<String, Object> doneYesterday = new HashMap<>(doneToday);
        doneYesterday.put("plan_date", Date.valueOf(TODAY.minusDays(1)));
        when(plans.findRange(eq(205L), any(), any())).thenReturn(List.of(doneYesterday));
        service.generate(205L, 30);
        verify(plans, times(2)).replacePlanned(eq(205L), eq(TODAY), rows.capture());
        assertEquals("flashcards", rows.getValue().get(0).sourceType());
    }

    @Test
    void doneItemsAreKeptAndCountAgainstTheirDay() {
        when(plans.findRange(eq(205L), any(), any())).thenReturn(List.of(Map.of(
            "id", 9L, "plan_date", Date.valueOf(TODAY), "source_type", "assign", "source_id", 1L,
            "title", "assignment 1 (phần 1/2)", "planned_minutes", 45, "status", "done")));
        service.generate(205L, 90);
        ArgumentCaptor<List<StudyPlanRepository.NewItem>> rows = ArgumentCaptor.forClass(List.class);
        verify(plans).replacePlanned(eq(205L), eq(TODAY), rows.capture());
        StudyPlanRepository.NewItem rest = rows.getValue().get(0);
        assertEquals(45, rest.plannedMinutes()); // only the remaining part of assignment 1
        assertEquals(TODAY, rest.planDate());    // today had 90 − 45 = 45 free
    }

    @Test
    void splitTitlesAreNumbered() {
        when(students.findAllTasks(205L)).thenReturn(List.of(task("assignment", 1, "pending", TODAY.plusDays(4), "new", null)));
        when(cards.findDue(eq(205L), isNull(), any())).thenReturn(List.of());
        when(recommendations.overall(205L, 3)).thenReturn(Map.of("chapters", List.of()));
        service.generate(205L, 60);
        ArgumentCaptor<List<StudyPlanRepository.NewItem>> rows = ArgumentCaptor.forClass(List.class);
        verify(plans).replacePlanned(eq(205L), eq(TODAY), rows.capture());
        assertEquals(List.of("assignment 1 (phần 1/2)", "assignment 1 (phần 2/2)"),
            rows.getValue().stream().map(StudyPlanRepository.NewItem::title).toList());
    }

    @Test
    void validation() {
        for (Object bad : new Object[]{null, 45, "60", 60.0}) {
            assertThrows(InvalidRequestException.class, () -> service.generate(205L, bad), String.valueOf(bad));
        }
        verify(plans, never()).replacePlanned(anyLong(), any(), any());
        assertThrows(InvalidRequestException.class, () -> service.get(205L, "16/11/2026", null));
        assertThrows(InvalidRequestException.class, () -> service.get(205L, "2026-11-16", "2026-11-01"));
        assertThrows(InvalidRequestException.class, () -> service.setStatus(205L, 1L, "finished"));
    }

    @Test
    void statusChangeIsScopedToTheOwner() {
        when(plans.updateStatus(205L, 99L, "done")).thenReturn(0);
        assertThrows(ResourceNotFoundException.class, () -> service.setStatus(205L, 99L, "done"));
        when(plans.updateStatus(205L, 9L, "done")).thenReturn(1);
        when(plans.findOwned(205L, 9L)).thenReturn(List.of(Map.of("id", 9L, "plan_date", Date.valueOf(TODAY),
            "source_type", "quiz", "source_id", 2L, "title", "quiz 2", "planned_minutes", 45, "status", "done")));
        Map<String, Object> m = service.setStatus(205L, 9L, "done");
        assertEquals("done", m.get("status"));
        assertEquals("2026-11-16", m.get("date"));
    }

    @Test
    void getInfersBudgetFromTheBusiestDay() {
        when(plans.findRange(eq(205L), any(), any())).thenReturn(List.of(
            Map.of("id", 1L, "plan_date", Date.valueOf(TODAY), "source_type", "quiz", "source_id", 2L,
                "title", "quiz 2", "planned_minutes", 45, "status", "planned"),
            Map.of("id", 2L, "plan_date", Date.valueOf(TODAY), "source_type", "resource", "source_id", 3L,
                "title", "Ôn lại", "planned_minutes", 20, "status", "done")));
        Map<String, Object> out = service.get(205L, null, null);
        assertEquals(90, out.get("dailyMinutes"));
        Map<String, Object> monday = ((List<Map<String, Object>>) out.get("days")).get(0);
        assertEquals(65, monday.get("plannedMinutes"));
        assertEquals(20, monday.get("doneMinutes"));
    }
}
