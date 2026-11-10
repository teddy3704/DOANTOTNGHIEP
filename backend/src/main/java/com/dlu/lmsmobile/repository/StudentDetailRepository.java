package com.dlu.lmsmobile.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

/**
 * The rows behind a student's overview numbers in one course, so a teacher can see which
 * activities make up the progress, which sessions make up the attendance and which marks
 * make up the average. Sources verified in db/schema/lms_mobile_learning_schema.sql.
 */
@Repository
public class StudentDetailRepository {
    private final JdbcTemplate jdbc;

    public StudentDetailRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /** Activities with completion tracking, done or not, in course order. */
    public List<Map<String, Object>> findProgressItems(Long userId, Long courseId) {
        return jdbc.queryForList("""
            SELECT li.coursemoduleid, li.activity_type, li.activity_name, li.section_name, li.due_time,
                   li.completionstate IN (1, 2, 3) AS completed,
                   CASE WHEN li.completionstate IN (1, 2, 3) THEN cmc.timemodified END AS completed_at,
                   li.moodle_path
            FROM derived.student_course_learning_items li
            LEFT JOIN lms.course_modules_completion cmc
                   ON cmc.coursemoduleid = li.coursemoduleid AND cmc.userid = li.userid
            WHERE li.userid = ? AND li.courseid = ? AND li.completion_tracking <> 0
            ORDER BY li.section_number NULLS LAST, li.coursemoduleid
            """, userId, courseId);
    }

    /**
     * Every attendance session of the course with this student's status, if marked. The
     * status grade and the best grade in the set are what the attendance % is built from.
     */
    public List<Map<String, Object>> findAttendanceSessions(Long userId, Long courseId) {
        return jdbc.queryForList("""
            SELECT a.name AS attendance_name, s.id AS session_id, s.sessdate, s.duration, s.description,
                   st.acronym, st.description AS status_description, st.grade AS status_grade,
                   mx.max_grade, al.remarks
            FROM lms.attendance a
            JOIN lms.attendance_sessions s ON s.attendanceid = a.id
            LEFT JOIN lms.attendance_log al ON al.sessionid = s.id AND al.studentid = ?
            LEFT JOIN lms.attendance_statuses st ON st.id = al.statusid
            CROSS JOIN LATERAL (SELECT max(st2.grade) AS max_grade FROM lms.attendance_statuses st2
                                WHERE st2.attendanceid = a.id AND st2.deleted = 0 AND st2.visible = 1) mx
            WHERE a.course = ?
            ORDER BY s.sessdate, s.id
            """, userId, courseId);
    }

    /** Gradebook rows for the course's activities, graded or not yet. */
    public List<Map<String, Object>> findGradeItems(Long userId, Long courseId) {
        return jdbc.queryForList("""
            SELECT g.activity_type, g.source_id, g.activity_name, g.finalgrade, g.grademax, g.gradepass,
                   g.grade_percentage, g.passed, g.timemodified
            FROM derived.student_grade_overview g
            WHERE g.userid = ? AND g.courseid = ?
            ORDER BY g.finalgrade IS NULL, g.activity_name
            """, userId, courseId);
    }
}
