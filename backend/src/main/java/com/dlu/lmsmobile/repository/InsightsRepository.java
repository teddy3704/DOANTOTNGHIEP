package com.dlu.lmsmobile.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/**
 * Read models for learning insights and CRUD for app-owned learning goals.
 *
 * <p>Sources and column names are taken from db/schema/lms_mobile_learning_schema.sql.
 * Completion filters mirror derived.student_course_progress so numbers stay consistent with
 * the progress percentage shown elsewhere. The only writes are INSERT/UPDATE on
 * app.learning_goals; nothing is ever deleted.
 */
@Repository
public class InsightsRepository {
    /** Same zone as ClockConfig.ANALYTICS_ZONE; used to bucket epoch seconds into local days. */
    private static final String ZONE = "Asia/Ho_Chi_Minh";

    private final JdbcTemplate jdbc;

    public InsightsRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    // ---------------------------------------------------------------- student read models

    /** Learning events per local day, limited to courses the student is enrolled in. */
    public List<Map<String, Object>> findStudentActivityByDay(Long userId, long sinceEpochSeconds) {
        return jdbc.queryForList("""
            SELECT (to_timestamp(l.timecreated) AT TIME ZONE '%s')::date AS day, count(*) AS events
            FROM lms.logstore_standard_log l
            WHERE l.userid = ? AND l.anonymous = 0 AND l.timecreated >= ?
              AND l.courseid IN (SELECT p.courseid FROM derived.student_course_progress p WHERE p.userid = ?)
            GROUP BY 1 ORDER BY 1
            """.formatted(ZONE), userId, sinceEpochSeconds, userId);
    }

    /**
     * Activity completions per local day and course. {@code day} is the last time Moodle
     * updated the completion state, which only approximates when it was completed.
     */
    public List<Map<String, Object>> findStudentCompletionsByDay(Long userId) {
        return jdbc.queryForList("""
            SELECT (to_timestamp(cmc.timemodified) AT TIME ZONE '%s')::date AS day,
                   cm.course AS courseid, count(*) AS completed
            FROM lms.course_modules_completion cmc
            JOIN lms.course_modules cm ON cm.id = cmc.coursemoduleid
            JOIN derived.student_course_progress p ON p.userid = cmc.userid AND p.courseid = cm.course
            WHERE cmc.userid = ? AND cmc.completionstate IN (1, 2, 3) AND cmc.timemodified > 0
              AND cm.completion <> 0 AND cm.deletioninprogress = 0 AND cm.visible = 1
            GROUP BY 1, 2 ORDER BY 1
            """.formatted(ZONE), userId);
    }

    public List<Map<String, Object>> findLearningAnalytics(Long userId) {
        return jdbc.queryForList(
            "SELECT * FROM derived.student_learning_analytics WHERE userid = ? ORDER BY courseid", userId);
    }

    public boolean isEnrolled(Long userId, Long courseId) {
        return Boolean.TRUE.equals(jdbc.queryForObject("""
            SELECT EXISTS (SELECT 1 FROM derived.student_course_progress WHERE userid = ? AND courseid = ?)
            """, Boolean.class, userId, courseId));
    }

    // ---------------------------------------------------------------- learning goals

    public List<Map<String, Object>> findGoals(Long userId) {
        return jdbc.queryForList(GOAL_SELECT + " WHERE g.user_id = ? "
            + "ORDER BY (g.status = 'active') DESC, g.created_at DESC, g.id DESC", userId);
    }

    public List<Map<String, Object>> findGoal(Long userId, Long goalId) {
        return jdbc.queryForList(GOAL_SELECT + " WHERE g.user_id = ? AND g.id = ?", userId, goalId);
    }

    public int countActiveGoals(Long userId) {
        Integer count = jdbc.queryForObject(
            "SELECT count(*) FROM app.learning_goals WHERE user_id = ? AND status = 'active'",
            Integer.class, userId);
        return count == null ? 0 : count;
    }

    public long insertGoal(Long userId, Long courseId, String goalType, BigDecimal targetValue,
                           LocalDate startDate, LocalDate endDate) {
        Long id = jdbc.queryForObject("""
            INSERT INTO app.learning_goals (user_id, course_id, goal_type, target_value, start_date, end_date)
            VALUES (?, ?, ?, ?, ?, ?) RETURNING id
            """, Long.class, userId, courseId, goalType, targetValue,
            java.sql.Date.valueOf(startDate), endDate == null ? null : java.sql.Date.valueOf(endDate));
        return id == null ? 0L : id;
    }

    /** Soft-cancels a goal owned by the user. Returns the number of rows changed (0 or 1). */
    public int cancelGoal(Long userId, Long goalId) {
        return jdbc.update("""
            UPDATE app.learning_goals SET status = 'cancelled', updated_at = CURRENT_TIMESTAMP
            WHERE id = ? AND user_id = ? AND status = 'active'
            """, goalId, userId);
    }

    private static final String GOAL_SELECT = """
        SELECT g.id, g.course_id, c.fullname AS course_name, g.goal_type, g.target_value,
               g.start_date, g.end_date, g.status, g.created_at, g.updated_at
        FROM app.learning_goals g LEFT JOIN lms.course c ON c.id = g.course_id
        """;

    // ---------------------------------------------------------------- teacher class read models

    private static final String ROSTER_IDS = """
        (SELECT m.studentid FROM derived.teacher_student_monitoring m WHERE m.teacherid = ? AND m.courseid = ?)
        """;

    /** Task counts by type and status for the students the teacher is responsible for. */
    public List<Map<String, Object>> findClassTaskStatus(Long teacherId, Long courseId) {
        return jdbc.queryForList("""
            SELECT ut.task_type, ut.task_status, count(*) AS tasks
            FROM derived.unified_tasks ut
            WHERE ut.courseid = ? AND ut.userid IN\s""" + ROSTER_IDS + """
            GROUP BY ut.task_type, ut.task_status
            """, courseId, teacherId, courseId);
    }

    /** Distinct active students and event counts per Monday-start week. */
    public List<Map<String, Object>> findClassEngagementByWeek(Long teacherId, Long courseId, long sinceEpochSeconds) {
        return jdbc.queryForList("""
            SELECT date_trunc('week', (to_timestamp(l.timecreated) AT TIME ZONE '%s'))::date AS week_start,
                   count(DISTINCT l.userid) AS active_students, count(*) AS events
            FROM lms.logstore_standard_log l
            WHERE l.courseid = ? AND l.anonymous = 0 AND l.timecreated >= ? AND l.userid IN\s
            """.formatted(ZONE) + ROSTER_IDS + " GROUP BY 1 ORDER BY 1",
            courseId, sinceEpochSeconds, teacherId, courseId);
    }

    /**
     * Every assignment/quiz of every roster student, with its completed/pending/overdue status
     * and when it was last handed in (submitted assignment / finished quiz attempt), so a
     * late submission can be told apart from an on-time one.
     */
    public List<Map<String, Object>> findClassTasks(Long teacherId, Long courseId) {
        return jdbc.queryForList("""
            SELECT ut.userid, ut.task_type, ut.source_id, ut.title, ut.due_time, ut.task_status,
                   CASE WHEN ut.task_type = 'assignment' THEN
                       (SELECT max(s.timemodified) FROM lms.assign_submission s
                        WHERE s.assignment = ut.source_id AND s.userid = ut.userid AND s.status = 'submitted')
                   ELSE
                       (SELECT max(qa.timefinish) FROM lms.quiz_attempts qa
                        WHERE qa.quiz = ut.source_id AND qa.userid = ut.userid AND qa.state = 'finished')
                   END AS submitted_at,
                   EXISTS (SELECT 1 FROM lms.logstore_standard_log l
                           WHERE l.userid = ut.userid AND l.contextlevel = 70 AND l.contextinstanceid = cmv.cmid) AS viewed,
                   gr.finalgrade IS NOT NULL AS graded, gr.grade_percentage, gr.passed
            FROM derived.unified_tasks ut
            LEFT JOIN LATERAL (
                SELECT c.id AS cmid FROM lms.course_modules c JOIN lms.modules m ON m.id = c.module
                WHERE c.course = ut.courseid AND c.instance = ut.source_id AND c.deletioninprogress = 0
                  AND m.name = CASE WHEN ut.task_type = 'assignment' THEN 'assign' ELSE 'quiz' END
                ORDER BY c.id LIMIT 1) cmv ON TRUE
            LEFT JOIN LATERAL (
                SELECT g.finalgrade, g.grade_percentage, g.passed FROM derived.student_grade_overview g
                WHERE g.userid = ut.userid AND g.courseid = ut.courseid AND g.source_id = ut.source_id
                  AND g.activity_type = CASE WHEN ut.task_type = 'assignment' THEN 'assign' ELSE 'quiz' END
                LIMIT 1) gr ON TRUE
            WHERE ut.courseid = ? AND ut.userid IN\s""" + ROSTER_IDS + """
            ORDER BY ut.userid, NULLIF(ut.due_time, 0) NULLS LAST, ut.title
            """, courseId, teacherId, courseId);
    }

    /**
     * What each roster student's record looked like at {@code asOfEpoch}: last log event before
     * it, events in the 7 days before it, and tracked activities completed by then. Used to
     * rebuild last week's watch score from Moodle history without storing snapshots.
     */
    public List<Map<String, Object>> findStudentStateAt(Long teacherId, Long courseId, long asOfEpoch) {
        return jdbc.queryForList("""
            SELECT m.studentid AS userid,
                   (SELECT max(l.timecreated) FROM lms.logstore_standard_log l
                    WHERE l.userid = m.studentid AND l.courseid = m.courseid AND l.anonymous = 0
                      AND l.timecreated < ?) AS last_event,
                   (SELECT count(*) FROM lms.logstore_standard_log l
                    WHERE l.userid = m.studentid AND l.courseid = m.courseid AND l.anonymous = 0
                      AND l.timecreated >= ? - 604800 AND l.timecreated < ?) AS events_7d,
                   (SELECT count(*) FROM lms.course_modules_completion cmc
                    JOIN lms.course_modules cm ON cm.id = cmc.coursemoduleid
                    WHERE cmc.userid = m.studentid AND cm.course = m.courseid AND cmc.completionstate IN (1, 2, 3)
                      AND cm.completion <> 0 AND cm.deletioninprogress = 0 AND cm.visible = 1
                      AND cmc.timemodified <= ?) AS completed_activities
            FROM derived.teacher_student_monitoring m
            WHERE m.teacherid = ? AND m.courseid = ?
            """, asOfEpoch, asOfEpoch, asOfEpoch, asOfEpoch, teacherId, courseId);
    }

    /**
     * Whether the course log records students opening individual activities (module-level
     * events). Without it, "not opened" cannot be told from "not logged".
     */
    public boolean hasActivityViewLogs(Long courseId) {
        return Boolean.TRUE.equals(jdbc.queryForObject("""
            SELECT EXISTS (SELECT 1 FROM lms.logstore_standard_log WHERE courseid = ? AND contextlevel = 70)
            """, Boolean.class, courseId));
    }

    /** One in-app notification for a student; it shows in the student's notification list. */
    public void insertStudentNotification(Long studentId, Long courseId, String title, String message,
                                          String sourceType, Long sourceId) {
        jdbc.update("""
            INSERT INTO app.notifications (user_id, notification_type, title, message, course_id, source_type, source_id)
            VALUES (?, 'teacher_reminder', ?, ?, ?, ?, ?)
            """, studentId, title, message, courseId, sourceType, sourceId);
    }

    /** Log events per student per Monday-start week; weeks with no events are simply absent. */
    public List<Map<String, Object>> findStudentEventsByWeek(Long teacherId, Long courseId, long sinceEpochSeconds) {
        return jdbc.queryForList("""
            SELECT l.userid, date_trunc('week', (to_timestamp(l.timecreated) AT TIME ZONE '%s'))::date AS week_start,
                   count(*) AS events
            FROM lms.logstore_standard_log l
            WHERE l.courseid = ? AND l.anonymous = 0 AND l.timecreated >= ? AND l.userid IN\s
            """.formatted(ZONE) + ROSTER_IDS + " GROUP BY 1, 2 ORDER BY 1, 2",
            courseId, sinceEpochSeconds, teacherId, courseId);
    }

    /**
     * The teacher's support notes in a course with the student's log activity in the 7 days
     * before and after each note. created_at has no zone; it is read in the session zone, the
     * same zone CURRENT_TIMESTAMP used when the note was written.
     */
    public List<Map<String, Object>> findNoteFollowUps(Long teacherId, Long courseId) {
        return jdbc.queryForList("""
            SELECT n.id, n.student_id, concat(u.firstname, ' ', u.lastname) AS fullname,
                   NULLIF(u.idnumber, '') AS student_code, n.note, n.status, e.note_epoch,
                   (SELECT count(*) FROM lms.logstore_standard_log l
                    WHERE l.userid = n.student_id AND l.courseid = n.course_id AND l.anonymous = 0
                      AND l.timecreated >= e.note_epoch - 604800 AND l.timecreated < e.note_epoch) AS events_before,
                   (SELECT count(*) FROM lms.logstore_standard_log l
                    WHERE l.userid = n.student_id AND l.courseid = n.course_id AND l.anonymous = 0
                      AND l.timecreated >= e.note_epoch AND l.timecreated < e.note_epoch + 604800) AS events_after,
                   (SELECT min(l.timecreated) FROM lms.logstore_standard_log l
                    WHERE l.userid = n.student_id AND l.courseid = n.course_id AND l.anonymous = 0
                      AND l.timecreated >= e.note_epoch) AS first_return
            FROM app.teacher_notes n
            JOIN lms."user" u ON u.id = n.student_id
            CROSS JOIN LATERAL (SELECT extract(epoch FROM n.created_at::timestamptz)::bigint AS note_epoch) e
            WHERE n.teacher_id = ? AND n.course_id = ?
            ORDER BY n.created_at DESC, n.id DESC
            """, teacherId, courseId);
    }

    /** Activity completions per Monday-start week for the teacher's students in a course. */
    public List<Map<String, Object>> findClassCompletionsByWeek(Long teacherId, Long courseId, long sinceEpochSeconds) {
        return jdbc.queryForList("""
            SELECT date_trunc('week', (to_timestamp(cmc.timemodified) AT TIME ZONE '%s'))::date AS week_start,
                   count(*) AS completed_activities
            FROM lms.course_modules_completion cmc
            JOIN lms.course_modules cm ON cm.id = cmc.coursemoduleid
            WHERE cm.course = ? AND cmc.completionstate IN (1, 2, 3) AND cmc.timemodified >= ?
              AND cm.completion <> 0 AND cm.deletioninprogress = 0 AND cm.visible = 1
              AND cmc.userid IN\s""".formatted(ZONE) + ROSTER_IDS + " GROUP BY 1 ORDER BY 1",
            courseId, sinceEpochSeconds, teacherId, courseId);
    }
}
