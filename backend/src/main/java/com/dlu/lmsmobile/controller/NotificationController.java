package com.dlu.lmsmobile.controller;
import com.dlu.lmsmobile.service.NotificationService;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;
@RestController
@RequestMapping("/api/v1/dev")
public class NotificationController {
    private final NotificationService service;
    public NotificationController(NotificationService service) { this.service = service; }
    @GetMapping("/students/{userId}/notifications")
    public List<Map<String, Object>> studentNotifications(@PathVariable Long userId) { 
        return service.findByUser(userId, "student"); 
    }

    @PostMapping("/students/{userId}/notifications/{notificationId}/read")
    public Map<String, Object> markStudentNotificationRead(@PathVariable Long userId, @PathVariable Long notificationId) {
        return service.markRead(userId, notificationId);
    }

    @GetMapping("/teachers/{userId}/notifications")
    public List<Map<String, Object>> teacherNotifications(@PathVariable Long userId) { 
        return service.findByUser(userId, "teacher"); 
    }
}
