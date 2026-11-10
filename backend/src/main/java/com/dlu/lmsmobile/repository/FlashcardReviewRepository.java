package com.dlu.lmsmobile.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/** V2-N5: reads app.flashcards with the caller's SM-2 state; writes only app.flashcard_reviews. */
@Repository
public class FlashcardReviewRepository {
    private final JdbcTemplate jdbc;

    public FlashcardReviewRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /**
     * Cards of this user that are due at {@code now} (never reviewed = due), only in courses the
     * user is enrolled in; optionally one course. Reviews first (oldest due first), then new cards.
     */
    public List<Map<String, Object>> findDue(Long userId, Long courseId, Instant now) {
        return jdbc.queryForList("""
            SELECT f.id, f.course_id, f.front_text, f.back_text,
                   r.repetitions, r.ease_factor, r.interval_days, r.due_at
            FROM app.flashcards f
            LEFT JOIN app.flashcard_reviews r ON r.flashcard_id = f.id AND r.user_id = f.userid
            WHERE f.userid = ?
              AND (CAST(? AS bigint) IS NULL OR f.course_id = ?)
              AND EXISTS (SELECT 1 FROM derived.student_course_progress p
                          WHERE p.userid = f.userid AND p.courseid = f.course_id)
              AND (r.id IS NULL OR r.due_at <= ?)
            ORDER BY (r.id IS NULL), r.due_at, f.id
            """, userId, courseId, courseId, utc(now));
    }

    /** The card (must belong to this user and course) with its SM-2 state, if any. */
    public Optional<Map<String, Object>> findCardState(Long cardId, Long courseId, Long userId) {
        return jdbc.queryForList("""
            SELECT f.id, r.repetitions, r.ease_factor, r.interval_days
            FROM app.flashcards f
            LEFT JOIN app.flashcard_reviews r ON r.flashcard_id = f.id AND r.user_id = f.userid
            WHERE f.id = ? AND f.course_id = ? AND f.userid = ?
            """, cardId, courseId, userId).stream().findFirst();
    }

    public void upsert(Long cardId, Long userId, int repetitions, double easeFactor, int intervalDays,
                       Instant dueAt, int rating, Instant reviewedAt) {
        jdbc.update("""
            INSERT INTO app.flashcard_reviews
                (flashcard_id, user_id, repetitions, ease_factor, interval_days, due_at, last_rating, last_reviewed_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT (flashcard_id, user_id) DO UPDATE SET
                repetitions = EXCLUDED.repetitions, ease_factor = EXCLUDED.ease_factor,
                interval_days = EXCLUDED.interval_days, due_at = EXCLUDED.due_at,
                last_rating = EXCLUDED.last_rating, last_reviewed_at = EXCLUDED.last_reviewed_at
            """, cardId, userId, repetitions, java.math.BigDecimal.valueOf(easeFactor), intervalDays,
            utc(dueAt), (short) rating, utc(reviewedAt));
    }

    private static OffsetDateTime utc(Instant i) {
        return OffsetDateTime.ofInstant(i, ZoneOffset.UTC);
    }

    /**
     * V2-N14: cards whose LATEST review falls in [from, to). Only the latest review per card is stored,
     * so a card reviewed in both weeks counts in the later week only.
     */
    public long countReviewedBetween(Long userId, Instant from, Instant to) {
        Long n = jdbc.queryForObject("""
            SELECT count(*) FROM app.flashcard_reviews
            WHERE user_id = ? AND last_reviewed_at >= ? AND last_reviewed_at < ?
            """, Long.class, userId, java.sql.Timestamp.from(from), java.sql.Timestamp.from(to));
        return n == null ? 0 : n;
    }
}
