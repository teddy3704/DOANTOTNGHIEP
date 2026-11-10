package com.dlu.lmsmobile.controller;

import com.dlu.lmsmobile.service.StudyRecommendationService;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/** V2-N2 study recommendations; path identity by the security chain, enrolment by the service. */
@RestController
@RequestMapping("/api/v1/dev/students/{userId}")
public class StudentRecommendationController {
    private final StudyRecommendationService recommendations;

    public StudentRecommendationController(StudyRecommendationService recommendations) {
        this.recommendations = recommendations;
    }

    @GetMapping("/courses/{courseId}/study-recommendations")
    public Map<String, Object> course(@PathVariable Long userId, @PathVariable Long courseId) {
        return recommendations.forCourse(userId, courseId);
    }

    @GetMapping("/study-recommendations")
    public Map<String, Object> overall(@PathVariable Long userId, @RequestParam(required = false) Integer limit) {
        return recommendations.overall(userId, limit);
    }
}
