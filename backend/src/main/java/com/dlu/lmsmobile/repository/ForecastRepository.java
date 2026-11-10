package com.dlu.lmsmobile.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

/**
 * Read-only grade data for the V2 forecast, recommendation and peer-comparison features.
 * Everything comes from derived views the runtime role can already SELECT; nothing touches
 * lms.grade_* directly.
 */
@Repository
public class ForecastRepository {
    private final JdbcTemplate jdbc;

    public ForecastRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /**
     * Every gradable activity of the course (any student's row defines the item), with its
     * category pair and the visible course module that links it. module_visible = false means the
     * activity has no visible module, which the forecast treats as hidden.
     */
    public List<Map<String, Object>> findCourseGradeItems(Long courseId) {
        return jdbc.queryForList("""
            SELECT i.grade_item_id, i.activity_type, i.source_id, i.activity_name, i.category_id,
                   i.category_name, i.parent_category_id, i.grademax, i.gradepass,
                   li.due_time, li.moodle_path, li.coursemoduleid, (li.coursemoduleid IS NOT NULL) AS module_visible
            FROM (SELECT DISTINCT ON (g.grade_item_id) g.grade_item_id, g.activity_type, g.source_id,
                         g.activity_name, g.category_id, g.category_name, g.parent_category_id, g.grademax, g.gradepass
                  FROM derived.student_grade_overview g WHERE g.courseid = ? ORDER BY g.grade_item_id) i
            LEFT JOIN LATERAL (SELECT l.due_time, l.moodle_path, l.coursemoduleid
                  FROM derived.student_course_learning_items l
                  WHERE l.courseid = ? AND l.activity_type = i.activity_type AND l.source_id = i.source_id
                  ORDER BY l.coursemoduleid LIMIT 1) li ON TRUE
            ORDER BY i.grade_item_id
            """, courseId, courseId);
    }

    /** V2-N3: (is it me, progress %) for every enrolled student; no identifiers leave the query. */
    public List<Map<String, Object>> findClassProgress(Long userId, Long courseId) {
        return jdbc.queryForList("""
            SELECT (userid = ?) AS mine, progress_percentage
            FROM derived.student_course_progress WHERE courseid = ?
            """, userId, courseId);
    }

    /** V2-N3: (is it me, mean graded %) per student with at least one graded activity. */
    public List<Map<String, Object>> findClassAverageGrades(Long userId, Long courseId) {
        return jdbc.queryForList("""
            SELECT bool_or(userid = ?) AS mine, avg(grade_percentage) AS average_percentage
            FROM derived.student_grade_overview
            WHERE courseid = ? AND grade_percentage IS NOT NULL
            GROUP BY userid
            """, userId, courseId);
    }

    /** Per graded activity: class mean and how many students have a grade (never individual rows). */
    public List<Map<String, Object>> findClassItemStats(Long courseId) {
        return jdbc.queryForList("""
            SELECT activity_type, source_id, avg(grade_percentage) AS average_percentage, count(*) AS graded_count
            FROM derived.student_grade_overview
            WHERE courseid = ? AND grade_percentage IS NOT NULL
            GROUP BY activity_type, source_id
            """, courseId);
    }

    /** Graded rows of one student (userId given) or of the whole course (userId null). */
    public List<Map<String, Object>> findCourseGrades(Long courseId, Long userId) {
        if (userId == null) {
            return jdbc.queryForList("""
                SELECT userid, grade_item_id, grade_percentage FROM derived.student_grade_overview
                WHERE courseid = ? AND grade_percentage IS NOT NULL
                """, courseId);
        }
        return jdbc.queryForList("""
            SELECT userid, grade_item_id, grade_percentage FROM derived.student_grade_overview
            WHERE courseid = ? AND userid = ? AND grade_percentage IS NOT NULL
            """, courseId, userId);
    }
}
