package com.dlu.lmsmobile.controller;

import com.dlu.lmsmobile.service.SearchService;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/** V2-N13 quick search; path identity by the security chain, rows scoped to the caller. */
@RestController
@RequestMapping("/api/v1/dev")
public class SearchController {
    private final SearchService search;

    public SearchController(SearchService search) {
        this.search = search;
    }

    @GetMapping("/students/{userId}/search")
    public Map<String, Object> student(@PathVariable Long userId, @RequestParam(required = false) String q) {
        return search.student(userId, q);
    }

    @GetMapping("/teachers/{teacherId}/search")
    public Map<String, Object> teacher(@PathVariable Long teacherId, @RequestParam(required = false) String q) {
        return search.teacher(teacherId, q);
    }
}
