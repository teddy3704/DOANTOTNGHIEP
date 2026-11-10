package com.dlu.lmsmobile.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

/** V2-N7: app.notification_preferences (SELECT, INSERT, UPDATE granted; one row per user). */
@Repository
public class NotificationPreferenceRepository {
    private final JdbcTemplate jdbc;

    public NotificationPreferenceRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public record Prefs(boolean pushEnabled, boolean assignmentReminder, boolean quizReminder,
                        boolean learningReminder, int reminderBeforeHours) {
    }

    public List<Map<String, Object>> find(Long userId) {
        return jdbc.queryForList("""
            SELECT push_enabled, assignment_reminder_enabled, quiz_reminder_enabled, learning_reminder_enabled,
                   default_reminder_before_hours, updated_at
            FROM app.notification_preferences WHERE user_id = ?
            """, userId);
    }

    /** Insert or update the caller's own row; columns this feature does not manage keep their values/defaults. */
    public void upsert(Long userId, Prefs p) {
        jdbc.update("""
            INSERT INTO app.notification_preferences (user_id, push_enabled, assignment_reminder_enabled,
                quiz_reminder_enabled, learning_reminder_enabled, default_reminder_before_hours)
            VALUES (?, ?, ?, ?, ?, ?)
            ON CONFLICT (user_id) DO UPDATE SET push_enabled = EXCLUDED.push_enabled,
                assignment_reminder_enabled = EXCLUDED.assignment_reminder_enabled,
                quiz_reminder_enabled = EXCLUDED.quiz_reminder_enabled,
                learning_reminder_enabled = EXCLUDED.learning_reminder_enabled,
                default_reminder_before_hours = EXCLUDED.default_reminder_before_hours,
                updated_at = now()
            """, userId, p.pushEnabled(), p.assignmentReminder(), p.quizReminder(), p.learningReminder(),
            p.reminderBeforeHours());
    }
}
