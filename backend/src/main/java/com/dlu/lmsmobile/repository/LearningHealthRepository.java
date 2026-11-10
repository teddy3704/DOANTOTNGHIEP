package com.dlu.lmsmobile.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

/** V2-N9: the student's own risk row (same view the teacher's monitoring row is built from). */
@Repository
public class LearningHealthRepository {
    private final JdbcTemplate jdbc;

    public LearningHealthRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /** One row per enrolled course of this student only; courseId null = every course. */
    public List<Map<String, Object>> findRiskRows(Long userId, Long courseId) {
        String sql = """
            SELECT r.userid, r.courseid, r.course_name, r.progress_percentage, r.pending_tasks, r.overdue_tasks,
                   r.events_last_7_days, r.active_days_last_7_days, r.days_since_last_activity, r.risk_score, r.risk_level,
                   p.completed_activities, p.total_tracked_activities
            FROM derived.student_risk_indicator r
            JOIN derived.student_course_progress p ON p.userid = r.userid AND p.courseid = r.courseid
            WHERE r.userid = ?
            """;
        if (courseId == null) return jdbc.queryForList(sql + " ORDER BY r.courseid", userId);
        return jdbc.queryForList(sql + " AND r.courseid = ?", userId, courseId);
    }

    /** First unfinished visible activity per course, used as the "open on LMS" target. */
    public List<Map<String, Object>> findNextActivities(Long userId) {
        return jdbc.queryForList("""
            SELECT DISTINCT ON (courseid) courseid, coursemoduleid, moodle_path, activity_name, activity_type
            FROM derived.student_course_learning_items
            WHERE userid = ? AND completionstate = 0 AND visible = 1 AND visibleoncoursepage = 1
            ORDER BY courseid, section_number NULLS LAST, coursemoduleid
            """, userId);
    }
}
