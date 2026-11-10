package com.dlu.lmsmobile.controller;

import com.dlu.lmsmobile.service.NotificationPreferenceService;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/** V2-N7 reminder settings; path identity by the security chain, the row is always the caller's own. */
@RestController
@RequestMapping("/api/v1/dev/students/{userId}/notification-preferences")
public class StudentNotificationPreferenceController {
    private final NotificationPreferenceService prefs;

    public StudentNotificationPreferenceController(NotificationPreferenceService prefs) {
        this.prefs = prefs;
    }

    @GetMapping
    public Map<String, Object> get(@PathVariable Long userId) {
        return prefs.get(userId);
    }

    @PutMapping
    public Map<String, Object> put(@PathVariable Long userId, @RequestBody Map<String, Object> body) {
        return prefs.put(userId, body);
    }
}
