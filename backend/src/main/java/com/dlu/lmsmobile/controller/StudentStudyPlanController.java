package com.dlu.lmsmobile.controller;

import com.dlu.lmsmobile.service.StudyPlanService;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/** V2-N6 weekly study plan; path identity by the security chain, ownership by the repository. */
@RestController
@RequestMapping("/api/v1/dev/students/{userId}/study-plan")
public class StudentStudyPlanController {
    private final StudyPlanService plans;

    public StudentStudyPlanController(StudyPlanService plans) {
        this.plans = plans;
    }

    @PostMapping("/generate")
    public Map<String, Object> generate(@PathVariable Long userId, @RequestBody Map<String, Object> body) {
        return plans.generate(userId, body.get("dailyMinutes"));
    }

    @GetMapping
    public Map<String, Object> get(@PathVariable Long userId, @RequestParam(required = false) String from,
                                   @RequestParam(required = false) String to) {
        return plans.get(userId, from, to);
    }

    @PutMapping("/items/{id}/status")
    public Map<String, Object> status(@PathVariable Long userId, @PathVariable Long id,
                                      @RequestBody Map<String, Object> body) {
        return plans.setStatus(userId, id, body.get("status"));
    }
}
