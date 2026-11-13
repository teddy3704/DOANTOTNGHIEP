package com.dlu.lmsmobile.controller;

import com.dlu.lmsmobile.portal.LocalTranscriptService;
import com.dlu.lmsmobile.portal.PortalNotLinkedException;
import org.springframework.http.ResponseEntity;

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
    private final LocalTranscriptService local;

    public StudentPortalController(StudentPortalService portal, PortalSourcesService sources, LocalTranscriptService local) {
        this.portal = portal;
        this.sources = sources;
        this.local = local;
    }

    // REAL-DATA-2: on the real export the simulated Portal API is off. Transcript, summary and GPA
    // simulation come from the student's own file (LocalTranscriptService); program, conduct and
    // decisions have no real source and answer PORTAL_NOT_LINKED (the app shows its empty state).

    @ExceptionHandler(LocalTranscriptService.FormatException.class)
    public ResponseEntity<Map<String, Object>> badFile(LocalTranscriptService.FormatException e) {
        return ResponseEntity.unprocessableEntity().body(Map.of("code", "TRANSCRIPT_FILE_INVALID", "message", e.getMessage()));
    }

    @GetMapping("/summary")
    public Map<String, Object> summary(@PathVariable Long userId) {
        return local.active() ? local.summary(userId) : portal.summary(userId);
    }

    @GetMapping("/transcript")
    public Map<String, Object> transcript(@PathVariable Long userId) {
        return local.active() ? local.transcript(userId) : portal.transcript(userId);
    }

    @GetMapping("/program")
    public Map<String, Object> program(@PathVariable Long userId) {
        if (local.active()) throw new PortalNotLinkedException();
        return portal.program(userId);
    }

    @GetMapping("/gpa-simulation")
    public Map<String, Object> gpaSimulation(@PathVariable Long userId) {
        return local.active() ? local.gpaSimulation(userId) : portal.gpaSimulation(userId);
    }

    @GetMapping("/conduct")
    public Map<String, Object> conduct(@PathVariable Long userId) {
        if (local.active()) return local.conduct(userId);   // real: the student's own conduct file
        return portal.conduct(userId);
    }

    @GetMapping("/decisions")
    public Map<String, Object> decisions(@PathVariable Long userId) {
        if (local.active()) throw new PortalNotLinkedException();
        return portal.decisions(userId);
    }

    @GetMapping("/sources")
    public Map<String, Object> sources(@PathVariable Long userId) {
        return sources.forStudent(userId);
    }
}
