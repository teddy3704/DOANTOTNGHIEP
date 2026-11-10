package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.exception.InvalidRequestException;
import com.dlu.lmsmobile.exception.ResourceNotFoundException;
import com.dlu.lmsmobile.repository.FlashcardRepository;
import com.dlu.lmsmobile.repository.InsightsRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class FlashcardService {
    private final FlashcardRepository repository;
    private final InsightsRepository courses;

    public FlashcardService(FlashcardRepository repository, InsightsRepository courses) {
        this.repository = repository;
        this.courses = courses;
    }

    public List<Map<String, Object>> getFlashcards(Long courseId, Long userId) {
        checkCourse(userId, courseId);
        return repository.findByCourseIdAndUserId(courseId, userId);
    }

    public void addFlashcard(Long courseId, Long userId, Map<String, Object> payload) {
        checkCourse(userId, courseId);
        repository.save(courseId, userId, text(payload, "frontText"), text(payload, "backText"));
    }

    public void updateFlashcard(Long id, Long courseId, Long userId, Map<String, Object> payload) {
        checkCourse(userId, courseId);
        int rows = repository.update(id, courseId, userId, text(payload, "frontText"), text(payload, "backText"));
        if (rows == 0) throw new ResourceNotFoundException("Flashcard not found or access denied");
    }

    public void deleteFlashcard(Long id, Long courseId, Long userId) {
        checkCourse(userId, courseId);
        int rows = repository.delete(id, courseId, userId);
        if (rows == 0) throw new ResourceNotFoundException("Flashcard not found or access denied");
    }

    private static String text(Map<String, Object> payload, String key) {
        if (!(payload.get(key) instanceof String value) || value.isBlank()) {
            throw new InvalidRequestException("Thiếu nội dung thẻ: " + key);
        }
        return value.trim();
    }

    private void checkCourse(Long userId, Long courseId) {
        if (userId == null || courseId == null || !courses.isEnrolled(userId, courseId)) {
            throw new ResourceNotFoundException("Student course not found");
        }
    }
}
