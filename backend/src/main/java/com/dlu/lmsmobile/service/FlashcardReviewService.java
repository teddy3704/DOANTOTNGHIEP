package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.exception.InvalidRequestException;
import com.dlu.lmsmobile.exception.ResourceNotFoundException;
import com.dlu.lmsmobile.repository.FlashcardReviewRepository;
import com.dlu.lmsmobile.repository.InsightsRepository;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.*;

import static com.dlu.lmsmobile.service.Values.*;

/** V2-N5: which cards are due today and the SM-2 step after an answer. Algorithm in {@link Sm2}. */
@Service
public class FlashcardReviewService {
    private final FlashcardReviewRepository reviews;
    private final InsightsRepository insights;
    private final Clock clock;

    public FlashcardReviewService(FlashcardReviewRepository reviews, InsightsRepository insights, Clock clock) {
        this.reviews = reviews;
        this.insights = insights;
        this.clock = clock;
    }

    /** Due cards of the student; {@code courseId} null = every enrolled course. */
    public Map<String, Object> due(Long userId, Long courseId) {
        if (courseId != null) checkCourse(userId, courseId);
        List<Map<String, Object>> cards = new ArrayList<>();
        int fresh = 0;
        for (Map<String, Object> r : reviews.findDue(userId, courseId, clock.instant())) {
            boolean isNew = r.get("repetitions") == null && r.get("due_at") == null;
            if (isNew) fresh++;
            Sm2.State s = state(r);
            Map<String, Object> c = new LinkedHashMap<>();
            c.put("id", lng(r.get("id")));
            c.put("courseId", lng(r.get("course_id")));
            c.put("frontText", str(r.get("front_text")));
            c.put("backText", str(r.get("back_text")));
            c.put("isNew", isNew);
            c.put("repetitions", s.repetitions());
            c.put("easeFactor", s.easeFactor());
            c.put("intervalDays", s.intervalDays());
            c.put("dueAt", instant(r.get("due_at")));
            c.put("nextIntervals", Sm2.preview(s));
            cards.add(c);
        }
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("total", cards.size());
        out.put("newCount", fresh);
        out.put("reviewCount", cards.size() - fresh);
        out.put("cards", cards);
        return out;
    }

    public Map<String, Object> review(Long userId, Long courseId, Long cardId, Object rating) {
        checkCourse(userId, courseId);
        int q = rating(rating);
        Map<String, Object> row = reviews.findCardState(cardId, courseId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Flashcard not found or access denied"));
        Sm2.State next = Sm2.next(state(row), q);
        Instant now = clock.instant();
        Instant dueAt = now.plus(Duration.ofDays(next.intervalDays()));
        reviews.upsert(cardId, userId, next.repetitions(), next.easeFactor(), next.intervalDays(), dueAt, q, now);
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("flashcardId", cardId);
        out.put("rating", q);
        out.put("repetitions", next.repetitions());
        out.put("easeFactor", next.easeFactor());
        out.put("intervalDays", next.intervalDays());
        out.put("dueAt", dueAt.toString());
        return out;
    }

    static int rating(Object value) {
        if (value instanceof Integer i && Sm2.RATINGS.contains(i)) return i;
        throw new InvalidRequestException("rating phải là một trong " + Sm2.RATINGS);
    }

    private static Sm2.State state(Map<String, Object> r) {
        if (r.get("repetitions") == null) return Sm2.State.NEW;
        Double ef = num(r.get("ease_factor"));
        return new Sm2.State((int) lng(r.get("repetitions")), ef == null ? Sm2.START_EF : ef,
            (int) lng(r.get("interval_days")));
    }

    private void checkCourse(Long userId, Long courseId) {
        if (userId == null || courseId == null || !insights.isEnrolled(userId, courseId)) {
            throw new ResourceNotFoundException("Student course not found");
        }
    }
}
