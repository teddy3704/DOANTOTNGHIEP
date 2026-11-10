package com.dlu.lmsmobile.repository;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Map;

@Repository
public class NotificationRepository {
    private final JdbcTemplate jdbc;
    public NotificationRepository(JdbcTemplate jdbc) { this.jdbc = jdbc; }

    /**
     * A user's notifications and learning reminders, newest first. A teacher reminder
     * (notification_type 'teacher_reminder') also names the teacher who sent it: the
     * reminder service writes a matching support note in the same transaction, so the note
     * with the same student, course and title, closest in time, identifies the sender.
     */
    public List<Map<String, Object>> findByUser(Long userId, String role) {
        boolean isTeacher = "teacher".equals(role);
        String sql = """
            WITH messages AS (
                SELECT id, 'notification' AS source_kind, notification_type, user_id, title, message, course_id,
                       source_type, source_id, created_at AS event_time, is_read FROM app.notifications WHERE user_id = ?
                       AND (title = 'Students need attention' OR title LIKE 'Teacher%') = ?
            """ + (!isTeacher ? """
                UNION ALL
                SELECT id, 'reminder' AS source_kind, NULL::varchar AS notification_type, user_id, title, message,
                       course_id, source_type, source_id, remind_at AS event_time, NULL::boolean AS is_read
                FROM app.learning_reminders
                WHERE user_id = ? AND status IN ('scheduled', 'sent')
            """ : "") + """
            )
            SELECT n.*, c.fullname AS course_name, link.coursemoduleid, link.moodle_path, sender.sender_name
            FROM messages n LEFT JOIN lms.course c ON c.id = n.course_id
            LEFT JOIN LATERAL (
                SELECT cm.id AS coursemoduleid, '/mod/' || m.name || '/view.php?id=' || cm.id AS moodle_path
                FROM lms.course_modules cm JOIN lms.modules m ON m.id = cm.module
                WHERE cm.course = n.course_id AND cm.instance = n.source_id
                  AND m.name = CASE WHEN n.source_type = 'assignment' THEN 'assign' ELSE n.source_type END
                  AND cm.deletioninprogress = 0 ORDER BY cm.id LIMIT 1
            ) link ON TRUE
            LEFT JOIN LATERAL (
                SELECT concat(u.firstname, ' ', u.lastname) AS sender_name
                FROM app.teacher_notes tn JOIN lms."user" u ON u.id = tn.teacher_id
                WHERE n.notification_type = 'teacher_reminder'
                  AND tn.student_id = n.user_id AND tn.course_id = n.course_id
                  -- same prefix as TeacherReminderService.NOTE_PREFIX
                  AND tn.note = 'Đã gửi nhắc nhở: ' || n.title
                  AND abs(extract(epoch FROM (tn.created_at::timestamptz - n.event_time))) < 120
                ORDER BY abs(extract(epoch FROM (tn.created_at::timestamptz - n.event_time))) LIMIT 1
            ) sender ON TRUE
            ORDER BY n.event_time DESC, n.source_kind, n.id DESC
            """;

        if (isTeacher) {
            return jdbc.queryForList(sql, userId, true);
        } else {
            return jdbc.queryForList(sql, userId, false, userId);
        }
    }

    /** Marks one of the user's own notifications as read; returns 0 if it is not theirs or already read. */
    public int markRead(Long userId, Long notificationId) {
        return jdbc.update("""
            UPDATE app.notifications SET is_read = TRUE, read_at = CURRENT_TIMESTAMP
            WHERE id = ? AND user_id = ? AND is_read = FALSE
            """, notificationId, userId);
    }
}
