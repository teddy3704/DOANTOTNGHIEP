package com.dlu.lmsmobile.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;
import java.util.ArrayList;

@Repository
public class TeacherNoteRepository {
    private final JdbcTemplate jdbc;

    public TeacherNoteRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<Map<String, Object>> findByTeacherId(Long teacherId, Long courseId, Long studentId) {
        StringBuilder sql = new StringBuilder("SELECT n.* FROM app.teacher_notes n WHERE n.teacher_id = ? AND " + authorizedRoster());
        List<Object> arguments = new ArrayList<>();
        arguments.add(teacherId);
        if (courseId != null) { sql.append(" AND n.course_id = ?"); arguments.add(courseId); }
        if (studentId != null) { sql.append(" AND n.student_id = ?"); arguments.add(studentId); }
        sql.append(" ORDER BY n.created_at DESC");
        return jdbc.queryForList(sql.toString(), arguments.toArray());
    }

    public void save(Long teacherId, Long studentId, Long courseId, String note, String status) {
        jdbc.update("INSERT INTO app.teacher_notes (teacher_id, student_id, course_id, note, status) VALUES (?, ?, ?, ?, ?)",
                teacherId, studentId, courseId, note, status != null ? status : "active");
    }

    public int updateStatus(Long id, Long teacherId, String status) {
        return jdbc.update("UPDATE app.teacher_notes n SET status = ? WHERE n.id = ? AND n.teacher_id = ? AND " + authorizedRoster(),
                status, id, teacherId);
    }

    private static String authorizedRoster() {
        // Existing group read model, not a new or guessed schema. Live verification remains blocked.
        return "EXISTS (SELECT 1 FROM derived.teacher_student_monitoring m WHERE m.teacherid = n.teacher_id "
                + "AND m.courseid = n.course_id AND m.studentid = n.student_id)";
    }
}
