package com.dlu.lmsmobile.controller;

import com.dlu.lmsmobile.service.FlashcardReviewService;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/** V2-N5 spaced repetition; path identity by the security chain, enrolment and ownership by the service. */
@RestController
@RequestMapping("/api/v1/dev/students/{userId}")
public class StudentFlashcardReviewController {
    private final FlashcardReviewService reviews;

    public StudentFlashcardReviewController(FlashcardReviewService reviews) {
        this.reviews = reviews;
    }

    @GetMapping("/flashcards/due")
    public Map<String, Object> due(@PathVariable Long userId, @RequestParam(required = false) Long courseId) {
        return reviews.due(userId, courseId);
    }

    @PostMapping("/courses/{courseId}/flashcards/{id}/review")
    public Map<String, Object> review(@PathVariable Long userId, @PathVariable Long courseId, @PathVariable Long id,
                                      @RequestBody Map<String, Object> body) {
        return reviews.review(userId, courseId, id, body.get("rating"));
    }
}
