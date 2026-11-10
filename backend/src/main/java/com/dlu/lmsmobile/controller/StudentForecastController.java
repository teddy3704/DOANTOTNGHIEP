package com.dlu.lmsmobile.controller;

import com.dlu.lmsmobile.service.GradeForecastService;
import com.dlu.lmsmobile.service.PeerComparisonService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/** V2-N1. The path user id is checked by PathIdentityAuthorizationManager; enrolment by the service. */
@RestController
@RequestMapping("/api/v1/dev/students/{userId}")
public class StudentForecastController {
    private final GradeForecastService forecasts;
    private final PeerComparisonService peers;

    public StudentForecastController(GradeForecastService forecasts, PeerComparisonService peers) {
        this.forecasts = forecasts;
        this.peers = peers;
    }

    /** V2-N3: anonymous class position (aggregates only; suppressed under 5 students). */
    @GetMapping("/courses/{courseId}/peer-comparison")
    public Map<String, Object> peerComparison(@PathVariable Long userId, @PathVariable Long courseId) {
        return peers.compare(userId, courseId);
    }

    @GetMapping("/courses/{courseId}/grade-forecast")
    public Map<String, Object> gradeForecast(@PathVariable Long userId, @PathVariable Long courseId) {
        return forecasts.studentForecast(userId, courseId);
    }
}
