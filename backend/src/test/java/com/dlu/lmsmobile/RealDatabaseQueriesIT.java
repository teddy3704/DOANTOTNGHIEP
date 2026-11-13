package com.dlu.lmsmobile;

import com.dlu.lmsmobile.repository.InsightsRepository;
import com.dlu.lmsmobile.repository.LearningHealthRepository;
import com.dlu.lmsmobile.repository.StudentDetailRepository;
import com.dlu.lmsmobile.repository.StudentRepository;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.SingleConnectionDataSource;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/**
 * REAL-DATA-1: runs the student repositories' real SQL against an imported lms_mobile_group_real,
 * as the runtime role (SET ROLE lms_group_app), so missing source tables (attendance sessions,
 * access log, names, quiz close times) are proven to give empty results of the right shape, never
 * an error. Skipped unless REAL_TEST_DB_URL points at a THROWAWAY trust-auth cluster, e.g.
 * jdbc:postgresql://127.0.0.1:55499/lms_mobile_group_real (never the group cluster 55432).
 * The student is picked by SQL at run time; no personal identifier is stored in this file, and
 * assertions only check shapes and counts, never print rows.
 */
@EnabledIfEnvironmentVariable(named = "REAL_TEST_DB_URL", matches = "jdbc:postgresql://127\\.0\\.0\\.1:(?!55432)\\d+/lms_mobile_group_real")
class RealDatabaseQueriesIT {
    static SingleConnectionDataSource ds;
    static JdbcTemplate jdbc;
    static long student;
    static long course;

    @BeforeAll
    static void connect() {
        ds = new SingleConnectionDataSource(System.getenv("REAL_TEST_DB_URL"), "postgres", "", true);
        jdbc = new JdbcTemplate(ds);
        jdbc.execute("SET ROLE lms_group_app");
        Map<String, Object> pick = jdbc.queryForMap("""
            SELECT p.userid, p.courseid FROM derived.student_course_progress p
            WHERE p.courseid IN (SELECT courseid FROM derived.real_courses_in_progress)
            ORDER BY p.total_tracked_activities DESC, p.userid, p.courseid LIMIT 1""");
        student = ((Number) pick.get("userid")).longValue();
        course = ((Number) pick.get("courseid")).longValue();
    }

    @AfterAll
    static void close() {
        if (ds != null) ds.destroy();
    }

    @Test
    void attendanceSessionTablesAreEmptySoSessionsAreAnEmptyList() {
        assertEquals(List.of(), new StudentDetailRepository(jdbc).findAttendanceSessions(student, course));
    }

    @Test
    void attendanceSummaryComesFromTheGradeItemWithUnknownSessionCounts() {
        assertEquals(0L, jdbc.queryForObject("""
            SELECT count(*) FROM derived.student_attendance_summary
            WHERE total_sessions IS NOT NULL OR attendance_percentage IS NULL""", Long.class));
        new StudentRepository(jdbc).findAttendanceByUserIdAndCourseId(student, course)
            .ifPresent(a -> assertNull(a.get("total_sessions")));
    }

    @Test
    void noActivityViewEventsSoNotOpenedIsNeverClaimed() {
        assertFalse(new InsightsRepository(jdbc).hasActivityViewLogs(course));
        assertEquals(0L, jdbc.queryForObject("SELECT count(*) FROM lms.logstore_standard_log WHERE origin <> 'derived'", Long.class));
    }

    @Test
    void studentReadModelsLoadWithoutErrors() {
        StudentRepository students = new StudentRepository(jdbc);
        assertTrue(students.findDashboardByUserId(student).isPresent());
        assertFalse(students.findCoursesByUserId(student).isEmpty());
        assertNotNull(students.findAllTasks(student));
        assertNotNull(students.findLearningItemsByUserIdAndCourseId(student, course));
        assertNotNull(students.findGradesByUserIdAndCourseId(student, course));
        assertNotNull(students.findGradeCategoriesByUserIdAndCourseId(student, course));
        assertNotNull(students.findContinueLearning(student, course));
        StudentDetailRepository details = new StudentDetailRepository(jdbc);
        assertFalse(details.findProgressItems(student, course).isEmpty());
        assertNotNull(details.findGradeItems(student, course));
        InsightsRepository insights = new InsightsRepository(jdbc);
        assertNotNull(insights.findStudentActivityByDay(student, 0));
        assertNotNull(insights.findStudentCompletionsByDay(student));
        assertNotNull(insights.findLearningAnalytics(student));
        assertNotNull(new LearningHealthRepository(jdbc).findRiskRows(student, null));
    }

    @Test
    void quizzesHaveNoCloseTimeAndAreNeverOverdue() {
        assertEquals(0L, jdbc.queryForObject("""
            SELECT count(*) FROM derived.unified_tasks WHERE task_type = 'quiz' AND (due_time <> 0 OR task_status = 'overdue')""",
            Long.class));
    }

    @Test
    void usersHaveNoNamesAndNoEmailOnlyTheirCode() {
        assertEquals(0L, jdbc.queryForObject("""
            SELECT count(*) FROM lms."user" WHERE email <> '' OR lastname <> '' OR firstname <> username""", Long.class));
    }
}
