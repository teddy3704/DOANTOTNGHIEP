package com.dlu.lmsmobile.controller;

import com.dlu.lmsmobile.service.WeeklyReportService;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/** V2-N14 "Tuần của bạn"; path identity by the security chain, only the caller's own data. */
@RestController
@RequestMapping("/api/v1/dev/students/{userId}/weekly-report")
public class StudentWeeklyReportController {
    private final WeeklyReportService reports;

    public StudentWeeklyReportController(WeeklyReportService reports) {
        this.reports = reports;
    }

    @GetMapping
    public Map<String, Object> get(@PathVariable Long userId, @RequestParam(required = false) String week) {
        return reports.report(userId, week);
    }
}
