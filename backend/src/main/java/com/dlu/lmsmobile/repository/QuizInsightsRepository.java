package com.dlu.lmsmobile.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

/**
 * V2-N16: quizzes of a teacher's course and the attempts of that course's students
 * (lms.quiz, lms.quiz_attempts, lms.course_modules, lms.modules: SELECT granted).
 * Only the service sees per-student rows; the API returns aggregates and roster ids for reminders.
 */
@Repository
public class QuizInsightsRepository {
    private final JdbcTemplate jdbc;

    public QuizInsightsRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<Map<String, Object>> findQuizzes(Long teacherId, Long courseId) {
        return jdbc.queryForList("""
            SELECT q.quiz_id, q.quiz_name, q.timeopen, q.timeclose, q.timelimit, cm.id AS coursemoduleid,
                   CASE WHEN cm.id IS NOT NULL THEN '/mod/quiz/view.php?id=' || cm.id END AS moodle_path
            FROM derived.teacher_quiz_monitoring q
            LEFT JOIN LATERAL (SELECT c.id FROM lms.course_modules c JOIN lms.modules m ON m.id = c.module
                WHERE c.course = q.courseid AND c.instance = q.quiz_id AND m.name = 'quiz'
                AND c.deletioninprogress = 0 ORDER BY c.id LIMIT 1) cm ON TRUE
            WHERE q.teacherid = ? AND q.courseid = ?
            ORDER BY NULLIF(q.timeclose, 0) NULLS LAST, q.quiz_id
            """, teacherId, courseId);
    }

    /**
     * Latest attempt per (quiz, enrolled student) of the course, any state. percent = sumgrades / quiz.sumgrades;
     * null when not graded or the quiz has no maximum.
     */
    public List<Map<String, Object>> findLatestAttempts(Long courseId) {
        return jdbc.queryForList("""
            SELECT DISTINCT ON (qa.quiz, qa.userid) qa.quiz AS quiz_id, qa.userid, qa.state,
                   qa.timestart, qa.timefinish,
                   CASE WHEN q.sumgrades > 0 AND qa.sumgrades IS NOT NULL
                        THEN qa.sumgrades / q.sumgrades * 100 END AS percent
            FROM lms.quiz_attempts qa
            JOIN lms.quiz q ON q.id = qa.quiz
            JOIN derived.student_course_progress p ON p.courseid = q.course AND p.userid = qa.userid
            WHERE q.course = ?
            ORDER BY qa.quiz, qa.userid, qa.attempt DESC, qa.timemodified DESC
            """, courseId);
    }
}
