package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.exception.ResourceNotFoundException;
import com.dlu.lmsmobile.repository.*;
import org.junit.jupiter.api.Test;
import java.util.Map;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;

class LearningWriteSecurityTest {
    private final InsightsRepository courses = mock(InsightsRepository.class);

    @Test void flashcardReadsAndWritesRequireCourseEnrollment() {
        var repository = mock(FlashcardRepository.class);
        var service = new FlashcardService(repository, courses);
        var payload = Map.<String, Object>of("frontText", "Q", "backText", "A");
        assertThrows(ResourceNotFoundException.class, () -> service.getFlashcards(14L, 205L));
        assertThrows(ResourceNotFoundException.class, () -> service.addFlashcard(14L, 205L, payload));
        assertThrows(ResourceNotFoundException.class, () -> service.updateFlashcard(1L, 14L, 205L, payload));
        assertThrows(ResourceNotFoundException.class, () -> service.deleteFlashcard(1L, 14L, 205L));
        verifyNoInteractions(repository);
    }

    @Test void reflectionCourseMustBelongToStudent() {
        var repository = mock(ReflectionRepository.class);
        var service = new ReflectionService(repository, courses);
        assertThrows(ResourceNotFoundException.class, () -> service.getReflections(205L, 14L));
        assertThrows(ResourceNotFoundException.class, () -> service.addReflection(205L,
                Map.of("courseId", 14L, "content", "Learning reflection")));
        verifyNoInteractions(repository);
    }
}
