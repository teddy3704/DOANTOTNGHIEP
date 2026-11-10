package com.dlu.lmsmobile.controller;

import com.dlu.lmsmobile.service.StudentCalendarService;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/** V2-N12 combined calendar; path identity by the security chain, only the caller's own data. */
@RestController
@RequestMapping("/api/v1/dev/students/{userId}/calendar")
public class StudentCalendarController {
    private final StudentCalendarService calendar;

    public StudentCalendarController(StudentCalendarService calendar) {
        this.calendar = calendar;
    }

    @GetMapping
    public Map<String, Object> get(@PathVariable Long userId, @RequestParam(required = false) String from,
                                   @RequestParam(required = false) String to) {
        return calendar.calendar(userId, from, to);
    }
}
