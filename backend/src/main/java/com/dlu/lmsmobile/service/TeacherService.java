package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.config.DataProfile;
import com.dlu.lmsmobile.exception.ResourceNotFoundException;
import com.dlu.lmsmobile.repository.TeacherRepository;
import org.springframework.stereotype.Service;

import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
public class TeacherService {

    private final TeacherRepository teacherRepository;
    private final DataProfile profile;

    public TeacherService(TeacherRepository teacherRepository, DataProfile profile) {
        this.teacherRepository = teacherRepository;
        this.profile = profile;
    }

    /**
     * On the real profile every course carries {@code current_term} (course of the current term,
     * same rule as the student side) so the teacher home totals only this term's courses; the demo
     * profile is unchanged.
     */
    public List<Map<String, Object>> getTeacherCourses(Long teacherId) {
        List<Map<String, Object>> courses = teacherRepository.findCoursesByTeacherId(teacherId);
        if (!profile.handInsOnly()) return courses;
        Set<Long> current = new HashSet<>(teacherRepository.findCurrentTermCourseIds());
        return courses.stream().map(c -> {
            Map<String, Object> m = new LinkedHashMap<>(c);
            Object id = c.get("courseid");
            m.put("current_term", id instanceof Number n && current.contains(n.longValue()));
            return m;
        }).toList();
    }

    public Map<String, Object> getTeacherCourseAnalytics(Long teacherId, Long courseId) {
        return teacherRepository.findCourseAnalyticsByTeacherIdAndCourseId(teacherId, courseId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Teacher course analytics not found for teacherId: " + teacherId + " and courseId: " + courseId));
    }
}
