package com.dlu.lmsmobile.service;
import com.dlu.lmsmobile.repository.NotificationRepository;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Map;
@Service
public class NotificationService {
    private final NotificationRepository repository;
    public NotificationService(NotificationRepository repository) { this.repository = repository; }
    public List<Map<String, Object>> findByUser(Long userId, String role) {
        List<Map<String, Object>> rows = repository.findByUser(userId, role);
        rows.forEach(NotificationText::localize);
        return rows;
    }

    /** Idempotent: marking an already-read notification again is not an error. */
    public Map<String, Object> markRead(Long userId, Long notificationId) {
        return Map.of("updated", repository.markRead(userId, notificationId));
    }
}
