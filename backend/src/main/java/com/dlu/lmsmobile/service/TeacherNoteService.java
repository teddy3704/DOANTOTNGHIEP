package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.repository.TeacherNoteRepository;
import com.dlu.lmsmobile.repository.TeacherRepository;
import com.dlu.lmsmobile.exception.InvalidRequestException;
import com.dlu.lmsmobile.exception.ResourceNotFoundException;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class TeacherNoteService {
    private final TeacherNoteRepository repository;
    private final TeacherRepository teachers;

    public TeacherNoteService(TeacherNoteRepository repository, TeacherRepository teachers) {
        this.repository = repository;
        this.teachers = teachers;
    }

    public List<Map<String, Object>> getNotes(Long teacherId, Long courseId, Long studentId) {
        if (courseId != null) checkScope(teacherId, courseId, studentId);
        else if (studentId != null) throw new InvalidRequestException("courseId is required when filtering by studentId");
        return repository.findByTeacherId(teacherId, courseId, studentId);
    }

    public void addNote(Long teacherId, Map<String, Object> payload) {
        Long studentId = positiveId(payload.get("studentId"), "studentId");
        Long courseId = positiveId(payload.get("courseId"), "courseId");
        if (!(payload.get("note") instanceof String note) || note.isBlank() || note.length() > 10000) {
            throw new InvalidRequestException("note must contain between 1 and 10000 characters");
        }
        String status = payload.get("status") == null ? "active" : payload.get("status").toString();
        checkStatus(status);
        checkScope(teacherId, courseId, studentId);
        repository.save(teacherId, studentId, courseId, note.trim(), status);
    }

    public void updateStatus(Long id, Long teacherId, String status) {
        checkStatus(status);
        int rows = repository.updateStatus(id, teacherId, status);
        if (rows == 0) throw new ResourceNotFoundException("Note not found or access denied");
    }

    private void checkScope(Long teacherId, Long courseId, Long studentId) {
        if (courseId <= 0 || !teachers.hasCourse(teacherId, courseId)) {
            throw new ResourceNotFoundException("Teacher course not found");
        }
        if (studentId != null && teachers.findStudents(teacherId, courseId).stream()
                .noneMatch(row -> row.get("userid") instanceof Number n && n.longValue() == studentId)) {
            throw new ResourceNotFoundException("Student not enrolled in course");
        }
    }

    private static Long positiveId(Object value, String name) {
        if (!(value instanceof Integer || value instanceof Long) || ((Number) value).longValue() <= 0) {
            throw new InvalidRequestException(name + " must be a positive integer");
        }
        return ((Number) value).longValue();
    }

    private static void checkStatus(String status) {
        if (!"active".equals(status) && !"resolved".equals(status)) {
            throw new InvalidRequestException("Supported note statuses: active, resolved");
        }
    }
}
