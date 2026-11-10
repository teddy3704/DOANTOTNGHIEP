package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.exception.InvalidRequestException;
import com.dlu.lmsmobile.repository.ReflectionRepository;
import com.dlu.lmsmobile.repository.InsightsRepository;
import com.dlu.lmsmobile.exception.ResourceNotFoundException;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class ReflectionService {
    private final ReflectionRepository repository;
    private final InsightsRepository courses;

    public ReflectionService(ReflectionRepository repository, InsightsRepository courses) {
        this.repository = repository;
        this.courses = courses;
    }

    public List<Map<String, Object>> getReflections(Long userId, Long courseId) {
        checkCourse(userId, courseId);
        return repository.findByUserId(userId, courseId);
    }

    public void addReflection(Long userId, Map<String, Object> payload) {
        if (!(payload.get("content") instanceof String content) || content.isBlank()) {
            throw new InvalidRequestException("Nội dung nhật ký không được để trống");
        }
        Object courseValue = payload.get("courseId");
        if (courseValue != null && !(courseValue instanceof Integer || courseValue instanceof Long)) {
            throw new InvalidRequestException("courseId must be an integer");
        }
        Long courseId = courseValue instanceof Number n ? n.longValue() : null;
        Integer understandingLevel = payload.get("understandingLevel") instanceof Number n ? n.intValue() : null;
        if (understandingLevel != null && (understandingLevel < 1 || understandingLevel > 5)) {
            throw new InvalidRequestException("Mức độ hiểu bài phải từ 1 đến 5");
        }
        checkCourse(userId, courseId);
        repository.save(userId, courseId, content.trim(), understandingLevel);
    }

    private void checkCourse(Long userId, Long courseId) {
        if (courseId != null && (courseId <= 0 || !courses.isEnrolled(userId, courseId))) {
            throw new ResourceNotFoundException("Student course not found");
        }
    }
}
