package com.dlu.lmsmobile.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.sql.Date;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/** V2-N6: app.study_plan_items only (SELECT, INSERT, UPDATE, DELETE granted). */
@Repository
public class StudyPlanRepository {
    private final JdbcTemplate jdbc;

    public StudyPlanRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public record NewItem(Long courseId, LocalDate planDate, String sourceType, Long sourceId, String title,
                          int plannedMinutes) {
    }

    public List<Map<String, Object>> findRange(Long userId, LocalDate from, LocalDate to) {
        return jdbc.queryForList("""
            SELECT id, course_id, plan_date, source_type, source_id, title, planned_minutes, status
            FROM app.study_plan_items
            WHERE user_id = ? AND plan_date BETWEEN ? AND ?
            ORDER BY plan_date, id
            """, userId, Date.valueOf(from), Date.valueOf(to));
    }

    /** Replaces the planned (not done/skipped) items from {@code from} on with {@code items}, atomically. */
    @Transactional
    public void replacePlanned(Long userId, LocalDate from, List<NewItem> items) {
        jdbc.update("DELETE FROM app.study_plan_items WHERE user_id = ? AND status = 'planned' AND plan_date >= ?",
            userId, Date.valueOf(from));
        for (NewItem i : items) {
            jdbc.update("""
                INSERT INTO app.study_plan_items (user_id, course_id, plan_date, source_type, source_id, title, planned_minutes)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """, userId, i.courseId(), Date.valueOf(i.planDate()), i.sourceType(), i.sourceId(), i.title(),
                i.plannedMinutes());
        }
    }

    /** Status change scoped to the owner; returns updated row count (0 = not found or not theirs). */
    public int updateStatus(Long userId, Long id, String status) {
        return jdbc.update("UPDATE app.study_plan_items SET status = ?, updated_at = now() WHERE id = ? AND user_id = ?",
            status, id, userId);
    }

    public List<Map<String, Object>> findOwned(Long userId, Long id) {
        return jdbc.queryForList("""
            SELECT id, course_id, plan_date, source_type, source_id, title, planned_minutes, status
            FROM app.study_plan_items WHERE id = ? AND user_id = ?
            """, id, userId);
    }
}
