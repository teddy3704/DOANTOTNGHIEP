package com.dlu.lmsmobile.controller;

import com.dlu.lmsmobile.service.LearningHealthService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/** V2-N9. Path identity is enforced by the security chain; rows are always filtered by userId. */
@RestController
@RequestMapping("/api/v1/dev/students/{userId}")
public class StudentHealthController {
    private final LearningHealthService health;

    public StudentHealthController(LearningHealthService health) {
        this.health = health;
    }

    @GetMapping("/learning-health")
    public Map<String, Object> overview(@PathVariable Long userId) {
        return health.overview(userId);
    }

    @GetMapping("/courses/{courseId}/learning-health")
    public Map<String, Object> course(@PathVariable Long userId, @PathVariable Long courseId) {
        return health.forCourse(userId, courseId);
    }
}
