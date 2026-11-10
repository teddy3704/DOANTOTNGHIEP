package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.exception.InvalidRequestException;
import com.dlu.lmsmobile.repository.NotificationPreferenceRepository;
import com.dlu.lmsmobile.repository.NotificationPreferenceRepository.Prefs;
import org.springframework.stereotype.Service;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * V2-N7 reminder settings. Without a stored row the table defaults apply (all on, 24 h before).
 * PUT is a partial update: missing keys keep the current value.
 */
@Service
public class NotificationPreferenceService {
    public static final Prefs DEFAULTS = new Prefs(true, true, true, true, 24);
    public static final int MAX_HOURS = 168;

    private final NotificationPreferenceRepository repo;

    public NotificationPreferenceService(NotificationPreferenceRepository repo) {
        this.repo = repo;
    }

    public Map<String, Object> get(Long userId) {
        List<Map<String, Object>> rows = repo.find(userId);
        return rows.isEmpty() ? json(DEFAULTS, false) : json(fromRow(rows.get(0)), true);
    }

    public Map<String, Object> put(Long userId, Map<String, Object> body) {
        if (body == null) throw new InvalidRequestException("Thiếu nội dung cài đặt");
        List<Map<String, Object>> rows = repo.find(userId);
        Prefs merged = merge(rows.isEmpty() ? DEFAULTS : fromRow(rows.get(0)), body);
        repo.upsert(userId, merged);
        return json(merged, true);
    }

    /** Pure: applies the provided keys on top of {@code base}; rejects unknown types and out-of-range hours. */
    static Prefs merge(Prefs base, Map<String, Object> body) {
        return new Prefs(
            bool(body, "pushEnabled", base.pushEnabled()),
            bool(body, "assignmentReminder", base.assignmentReminder()),
            bool(body, "quizReminder", base.quizReminder()),
            bool(body, "learningReminder", base.learningReminder()),
            hours(body, base.reminderBeforeHours()));
    }

    private static boolean bool(Map<String, Object> body, String key, boolean fallback) {
        if (!body.containsKey(key)) return fallback;
        if (body.get(key) instanceof Boolean b) return b;
        throw new InvalidRequestException(key + " phải là true hoặc false");
    }

    private static int hours(Map<String, Object> body, int fallback) {
        if (!body.containsKey("reminderBeforeHours")) return fallback;
        if (body.get("reminderBeforeHours") instanceof Integer h && h >= 0 && h <= MAX_HOURS) return h;
        throw new InvalidRequestException("reminderBeforeHours phải là số nguyên từ 0 đến " + MAX_HOURS);
    }

    private static Prefs fromRow(Map<String, Object> r) {
        return new Prefs(Boolean.TRUE.equals(r.get("push_enabled")),
            Boolean.TRUE.equals(r.get("assignment_reminder_enabled")),
            Boolean.TRUE.equals(r.get("quiz_reminder_enabled")),
            Boolean.TRUE.equals(r.get("learning_reminder_enabled")),
            r.get("default_reminder_before_hours") instanceof Number n ? n.intValue() : DEFAULTS.reminderBeforeHours());
    }

    private static Map<String, Object> json(Prefs p, boolean stored) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("pushEnabled", p.pushEnabled());
        m.put("assignmentReminder", p.assignmentReminder());
        m.put("quizReminder", p.quizReminder());
        m.put("learningReminder", p.learningReminder());
        m.put("reminderBeforeHours", p.reminderBeforeHours());
        m.put("stored", stored);
        return m;
    }
}
