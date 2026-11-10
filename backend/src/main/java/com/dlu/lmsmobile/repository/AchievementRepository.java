package com.dlu.lmsmobile.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/** V2-N17: read-only facts for achievements; every query is limited to one user. */
@Repository
public class AchievementRepository {
    private final JdbcTemplate jdbc;

    public AchievementRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /** The student's assignments with a deadline and the time of their latest submitted submission, by due date. */
    public List<Map<String, Object>> findAssignmentSubmissions(Long userId) {
        return jdbc.queryForList("""
            SELECT ut.source_id, ut.title, ut.due_time, s.timemodified AS submitted_at
            FROM derived.unified_tasks ut
            LEFT JOIN lms.assign_submission s ON s.assignment = ut.source_id AND s.userid = ut.userid
                 AND s.latest = 1 AND s.status = 'submitted'
            WHERE ut.userid = ? AND ut.task_type = 'assignment' AND ut.due_time > 0
            ORDER BY ut.due_time, ut.source_id
            """, userId);
    }

    /** Local days on which at least one card had its LATEST review (only the latest review is stored). */
    public List<LocalDate> findReviewDays(Long userId) {
        List<LocalDate> out = new ArrayList<>();
        for (Map<String, Object> r : jdbc.queryForList("""
                SELECT DISTINCT (last_reviewed_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS day
                FROM app.flashcard_reviews WHERE user_id = ? AND last_reviewed_at IS NOT NULL ORDER BY 1
                """, userId)) {
            Object d = r.get("day");
            if (d instanceof java.sql.Date sd) out.add(sd.toLocalDate());
        }
        return out;
    }
}
