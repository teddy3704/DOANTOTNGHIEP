package com.dlu.lmsmobile.controller;

import com.dlu.lmsmobile.portal.PortalSourcesService;
import com.dlu.lmsmobile.portal.StudentPortalService;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/** V3 P1–P5, P7 for the student. Path identity by the security chain; Portal identity by server config. */
@RestController
@RequestMapping("/api/v1/dev/students/{userId}/portal")
public class StudentPortalController {
    private final StudentPortalService portal;
    private final PortalSourcesService sources;

    public StudentPortalController(StudentPortalService portal, PortalSourcesService sources) {
        this.portal = portal;
        this.sources = sources;
    }

    @GetMapping("/summary")
    public Map<String, Object> summary(@PathVariable Long userId) {
        return portal.summary(userId);
    }

    @GetMapping("/transcript")
    public Map<String, Object> transcript(@PathVariable Long userId) {
        return portal.transcript(userId);
    }

    @GetMapping("/program")
    public Map<String, Object> program(@PathVariable Long userId) {
        return portal.program(userId);
    }

    @GetMapping("/gpa-simulation")
    public Map<String, Object> gpaSimulation(@PathVariable Long userId) {
        return portal.gpaSimulation(userId);
    }

    @GetMapping("/conduct")
    public Map<String, Object> conduct(@PathVariable Long userId) {
        return portal.conduct(userId);
    }

    @GetMapping("/decisions")
    public Map<String, Object> decisions(@PathVariable Long userId) {
        return portal.decisions(userId);
    }

    @GetMapping("/sources")
    public Map<String, Object> sources(@PathVariable Long userId) {
        return sources.forStudent(userId);
    }
}
