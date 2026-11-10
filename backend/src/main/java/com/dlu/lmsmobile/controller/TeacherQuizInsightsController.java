package com.dlu.lmsmobile.controller;

import com.dlu.lmsmobile.service.QuizInsightsService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/** V2-N16. Teacher identity by the security chain; course ownership by the service (404). */
@RestController
@RequestMapping("/api/v1/dev/teachers/{teacherId}/courses/{courseId}")
public class TeacherQuizInsightsController {
    private final QuizInsightsService quizzes;

    public TeacherQuizInsightsController(QuizInsightsService quizzes) {
        this.quizzes = quizzes;
    }

    @GetMapping("/quiz-insights")
    public Map<String, Object> quizInsights(@PathVariable Long teacherId, @PathVariable Long courseId) {
        return quizzes.insights(teacherId, courseId);
    }
}
