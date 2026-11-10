package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.exception.InvalidRequestException;
import com.dlu.lmsmobile.exception.ResourceNotFoundException;
import com.dlu.lmsmobile.repository.FlashcardReviewRepository;
import com.dlu.lmsmobile.repository.InsightsRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.*;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/** V2-N5 service: due list, SM-2 write, ownership and enrolment checks (no database). */
class FlashcardReviewServiceTest {
    static final Instant NOW = Instant.parse("2026-11-20T02:00:00Z");
    FlashcardReviewRepository repo;
    InsightsRepository insights;
    FlashcardReviewService service;

    @BeforeEach
    void setup() {
        repo = mock(FlashcardReviewRepository.class);
        insights = mock(InsightsRepository.class);
        when(insights.isEnrolled(205L, 13L)).thenReturn(true);
        service = new FlashcardReviewService(repo, insights, Clock.fixed(NOW, ZoneId.of("Asia/Ho_Chi_Minh")));
    }

    private static Map<String, Object> row(long id, Integer reps, Double ef, Integer interval, Instant due) {
        Map<String, Object> r = new HashMap<>();
        r.put("id", id);
        r.put("course_id", 13L);
        r.put("front_text", "Q" + id);
        r.put("back_text", "A" + id);
        r.put("repetitions", reps);
        r.put("ease_factor", ef == null ? null : BigDecimal.valueOf(ef));
        r.put("interval_days", interval);
        r.put("due_at", due == null ? null : Timestamp.from(due));
        return r;
    }

    @Test
    void dueListsNewAndReviewCardsWithButtonIntervals() {
        when(repo.findDue(205L, null, NOW)).thenReturn(List.of(
            row(1, 2, 2.5, 6, NOW.minusSeconds(60)),
            row(2, null, null, null, null)));
        Map<String, Object> out = service.due(205L, null);
        assertEquals(2, out.get("total"));
        assertEquals(1, out.get("newCount"));
        assertEquals(1, out.get("reviewCount"));
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> cards = (List<Map<String, Object>>) out.get("cards");
        assertEquals(false, cards.get(0).get("isNew"));
        assertEquals(Map.of(1, 1, 3, 15, 4, 15, 5, 15), cards.get(0).get("nextIntervals"));
        assertEquals(true, cards.get(1).get("isNew"));
        assertEquals(Map.of(1, 1, 3, 1, 4, 1, 5, 1), cards.get(1).get("nextIntervals"));
        verifyNoInteractions(insights);
    }

    @Test
    void emptyDueList() {
        when(repo.findDue(205L, 13L, NOW)).thenReturn(List.of());
        Map<String, Object> out = service.due(205L, 13L);
        assertEquals(0, out.get("total"));
        assertEquals(List.of(), out.get("cards"));
    }

    @Test
    void dueOfUnenrolledCourseIsNotFound() {
        assertThrows(ResourceNotFoundException.class, () -> service.due(205L, 99L));
        verifyNoInteractions(repo);
    }

    @Test
    void reviewWritesNextScheduleFromStoredState() {
        when(repo.findCardState(7L, 13L, 205L)).thenReturn(Optional.of(row(7, 2, 2.5, 6, NOW)));
        Map<String, Object> out = service.review(205L, 13L, 7L, 4);
        assertEquals(3, out.get("repetitions"));
        assertEquals(15, out.get("intervalDays"));
        assertEquals("2026-12-05T02:00:00Z", out.get("dueAt"));
        verify(repo).upsert(7L, 205L, 3, 2.5, 15, Instant.parse("2026-12-05T02:00:00Z"), 4, NOW);
    }

    @Test
    void firstReviewOfNewCardStartsFromDefaults() {
        when(repo.findCardState(8L, 13L, 205L)).thenReturn(Optional.of(row(8, null, null, null, null)));
        Map<String, Object> out = service.review(205L, 13L, 8L, 1);
        assertEquals(0, out.get("repetitions"));
        assertEquals(1.96, (double) out.get("easeFactor"), 1e-9);
        assertEquals(1, out.get("intervalDays"));
    }

    @Test
    void cardOfAnotherStudentOrCourseIsNotFoundAndNothingIsWritten() {
        when(repo.findCardState(anyLong(), anyLong(), anyLong())).thenReturn(Optional.empty());
        assertThrows(ResourceNotFoundException.class, () -> service.review(205L, 13L, 999L, 4));
        verify(repo, never()).upsert(anyLong(), anyLong(), anyInt(), anyDouble(), anyInt(), any(), anyInt(), any());
    }

    @Test
    void reviewInUnenrolledCourseIsNotFound() {
        assertThrows(ResourceNotFoundException.class, () -> service.review(205L, 99L, 7L, 4));
        verifyNoInteractions(repo);
    }

    @Test
    void invalidRatingsAreRejected() {
        for (Object bad : new Object[]{null, 0, 2, 6, "4", 4.0}) {
            assertThrows(InvalidRequestException.class, () -> service.review(205L, 13L, 7L, bad), String.valueOf(bad));
        }
        verifyNoInteractions(repo);
    }
}
