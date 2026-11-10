package com.dlu.lmsmobile.controller;

import com.dlu.lmsmobile.service.StudySessionService;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/** V2-N10 focus sessions; path identity by the security chain, enrolment/ownership by the service. */
@RestController
@RequestMapping("/api/v1/dev/students/{userId}/study-sessions")
public class StudentStudySessionController {
    private final StudySessionService sessions;

    public StudentStudySessionController(StudySessionService sessions) {
        this.sessions = sessions;
    }

    @PostMapping
    public Map<String, Object> record(@PathVariable Long userId, @RequestBody Map<String, Object> body) {
        return sessions.record(userId, body);
    }

    @GetMapping("/summary")
    public Map<String, Object> summary(@PathVariable Long userId, @RequestParam(required = false) String from,
                                       @RequestParam(required = false) String to) {
        return sessions.summary(userId, from, to);
    }
}
