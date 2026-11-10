package com.dlu.lmsmobile.controller;

import com.dlu.lmsmobile.portal.AdvisorPortalService;
import com.dlu.lmsmobile.portal.PortalSourcesService;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.nio.charset.StandardCharsets;
import java.util.Map;

/** V3-P6/P7 for the advisor. Classes are limited to the server-configured advisor classes. */
@RestController
@RequestMapping("/api/v1/dev/teachers/{teacherId}/portal")
public class TeacherPortalController {
    private final AdvisorPortalService advisor;
    private final PortalSourcesService sources;

    public TeacherPortalController(AdvisorPortalService advisor, PortalSourcesService sources) {
        this.advisor = advisor;
        this.sources = sources;
    }

    @GetMapping("/advisor/classes")
    public Map<String, Object> classes(@PathVariable Long teacherId) {
        return advisor.classes(teacherId);
    }

    @GetMapping("/advisor/classes/{classId}")
    public Map<String, Object> overview(@PathVariable Long teacherId, @PathVariable String classId,
                                        @RequestParam(required = false) String yearStudy,
                                        @RequestParam(required = false) String termId,
                                        @RequestParam(required = false) Boolean mask) {
        return advisor.overview(teacherId, classId, yearStudy, termId, mask);
    }

    @GetMapping("/advisor/classes/{classId}/students/{no}")
    public Map<String, Object> student(@PathVariable Long teacherId, @PathVariable String classId, @PathVariable int no,
                                       @RequestParam(required = false) String yearStudy,
                                       @RequestParam(required = false) String termId,
                                       @RequestParam(required = false) Boolean mask) {
        return advisor.student(teacherId, classId, no, yearStudy, termId, mask);
    }

    @GetMapping("/advisor/classes/{classId}/export")
    public ResponseEntity<String> export(@PathVariable Long teacherId, @PathVariable String classId,
                                         @RequestParam(required = false) String yearStudy,
                                         @RequestParam(required = false) String termId,
                                         @RequestParam(required = false) Boolean mask,
                                         @RequestParam(defaultValue = "false") boolean confirm) {
        String csv = advisor.exportCsv(teacherId, classId, yearStudy, termId, mask, confirm);
        return ResponseEntity.ok()
            .contentType(new MediaType("text", "csv", StandardCharsets.UTF_8))
            .header(HttpHeaders.CONTENT_DISPOSITION, ContentDisposition.attachment()
                .filename("lop-" + classId.replaceAll("[^A-Za-z0-9]", "") + ".csv").build().toString())
            .header(HttpHeaders.CACHE_CONTROL, "no-store")
            .body(csv);
    }

    @GetMapping("/sources")
    public Map<String, Object> sources(@PathVariable Long teacherId) {
        return sources.forTeacher(teacherId);
    }
}
