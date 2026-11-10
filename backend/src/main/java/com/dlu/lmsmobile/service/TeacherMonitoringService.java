package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.exception.ResourceNotFoundException;
import com.dlu.lmsmobile.repository.StudentDetailRepository;
import com.dlu.lmsmobile.repository.StudentRepository;
import com.dlu.lmsmobile.repository.TeacherRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;

@Service
@Transactional(readOnly = true)
public class TeacherMonitoringService {
    private final TeacherRepository teachers;
    private final StudentRepository students;
    private final StudentDetailRepository details;
    public TeacherMonitoringService(TeacherRepository teachers, StudentRepository students,
                                    StudentDetailRepository details) {
        this.teachers = teachers; this.students = students; this.details = details;
    }
    private void checkCourse(Long teacherId, Long courseId) {
        if (!teachers.hasCourse(teacherId, courseId)) throw new ResourceNotFoundException("Teacher course not found");
    }
    public List<Map<String, Object>> roster(Long teacherId, Long courseId) {
        checkCourse(teacherId, courseId);
        return teachers.findStudents(teacherId, courseId);
    }
    public Map<String, Object> studentDetail(Long teacherId, Long courseId, Long userId) {
        var student = roster(teacherId, courseId).stream()
            .filter(s -> s.get("userid") instanceof Number n && n.longValue() == userId)
            .findFirst().orElseThrow(() -> new ResourceNotFoundException("Student not enrolled in course"));
        var result = new LinkedHashMap<>(student);
        result.put("tasks", students.findTasksByUserIdAndCourseId(userId, courseId));
        // The rows behind progress, attendance and average grade, so each number can be explained.
        result.put("progress_items", details.findProgressItems(userId, courseId));
        result.put("attendance_sessions", details.findAttendanceSessions(userId, courseId));
        result.put("grade_items", details.findGradeItems(userId, courseId));
        return result;
    }
    public List<Map<String, Object>> activities(Long teacherId, Long courseId, String type) {
        checkCourse(teacherId, courseId);
        return teachers.findActivities(teacherId, courseId, type);
    }
    public List<Map<String, Object>> activityStudents(Long teacherId, Long courseId, String type, Long sourceId) {
        var activities = activities(teacherId, courseId, type);
        if (activities.stream().noneMatch(a -> a.get("source_id") instanceof Number n && n.longValue() == sourceId))
            throw new ResourceNotFoundException("Activity not found in course");
        return teachers.findActivityStudents(teacherId, courseId, type, sourceId);
    }
}
