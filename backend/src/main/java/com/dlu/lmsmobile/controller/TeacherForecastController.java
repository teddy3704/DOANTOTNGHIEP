package com.dlu.lmsmobile.controller;

import com.dlu.lmsmobile.service.GradeForecastService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/** V2-N4. Teacher identity by the security chain; course ownership (roster) by the service → 404. */
@RestController
@RequestMapping("/api/v1/dev/teachers/{teacherId}/courses/{courseId}")
public class TeacherForecastController {
    private final GradeForecastService forecasts;

    public TeacherForecastController(GradeForecastService forecasts) {
        this.forecasts = forecasts;
    }

    @GetMapping("/grade-forecast")
    public Map<String, Object> gradeForecast(@PathVariable Long teacherId, @PathVariable Long courseId) {
        return forecasts.teacherForecast(teacherId, courseId);
    }
}
