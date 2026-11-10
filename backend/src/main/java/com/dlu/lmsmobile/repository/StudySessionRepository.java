package com.dlu.lmsmobile.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.Map;

/** V2-N10: app.study_sessions (SELECT, INSERT granted). Days are bucketed in Asia/Ho_Chi_Minh. */
@Repository
public class StudySessionRepository {
    private final JdbcTemplate jdbc;

    public StudySessionRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public long insert(Long userId, Long courseId, Long planItemId, Instant startedAt, Instant endedAt,
                       int focusMinutes) {
        Long id = jdbc.queryForObject("""
            INSERT INTO app.study_sessions (user_id, course_id, plan_item_id, started_at, ended_at, focus_minutes)
            VALUES (?, ?, ?, ?, ?, ?) RETURNING id
            """, Long.class, userId, courseId, planItemId, Timestamp.from(startedAt), Timestamp.from(endedAt),
            focusMinutes);
        return id == null ? 0 : id;
    }

    /** Focus minutes per local day and course for sessions started in [from, to). */
    public List<Map<String, Object>> minutesByDayAndCourse(Long userId, Instant from, Instant to) {
        return jdbc.queryForList("""
            SELECT (started_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS day, course_id,
                   SUM(focus_minutes) AS minutes, COUNT(*) AS sessions
            FROM app.study_sessions
            WHERE user_id = ? AND started_at >= ? AND started_at < ?
            GROUP BY 1, 2 ORDER BY 1, 2
            """, userId, Timestamp.from(from), Timestamp.from(to));
    }

    /** Total focus minutes in [from, to), optionally for one course (goal progress). */
    public long totalMinutes(Long userId, Long courseId, Instant from, Instant to) {
        Long v = courseId == null
            ? jdbc.queryForObject("""
                SELECT COALESCE(SUM(focus_minutes), 0) FROM app.study_sessions
                WHERE user_id = ? AND started_at >= ? AND started_at < ?
                """, Long.class, userId, Timestamp.from(from), Timestamp.from(to))
            : jdbc.queryForObject("""
                SELECT COALESCE(SUM(focus_minutes), 0) FROM app.study_sessions
                WHERE user_id = ? AND course_id = ? AND started_at >= ? AND started_at < ?
                """, Long.class, userId, courseId, Timestamp.from(from), Timestamp.from(to));
        return v == null ? 0 : v;
    }
}
