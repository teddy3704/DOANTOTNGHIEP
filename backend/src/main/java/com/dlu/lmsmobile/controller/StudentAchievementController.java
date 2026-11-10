package com.dlu.lmsmobile.controller;

import com.dlu.lmsmobile.service.AchievementService;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/** V2-N17 achievements; path identity by the security chain, only the caller's own badges. */
@RestController
@RequestMapping("/api/v1/dev/students/{userId}/achievements")
public class StudentAchievementController {
    private final AchievementService achievements;

    public StudentAchievementController(AchievementService achievements) {
        this.achievements = achievements;
    }

    @GetMapping
    public Map<String, Object> get(@PathVariable Long userId) {
        return achievements.achievements(userId);
    }
}
