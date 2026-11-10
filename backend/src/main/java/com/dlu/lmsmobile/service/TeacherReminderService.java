package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.exception.InvalidRequestException;
import com.dlu.lmsmobile.exception.ResourceNotFoundException;
import com.dlu.lmsmobile.repository.InsightsRepository;
import com.dlu.lmsmobile.repository.TeacherNoteRepository;
import com.dlu.lmsmobile.repository.TeacherRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

import static com.dlu.lmsmobile.service.Values.*;

/**
 * A teacher nudging one student (V2-N8 "Nhắc riêng") or several at once. Each reminder lands in the student's in-app
 * notifications and is also kept as a support note, so the "did support help?" section
 * measures reminders the same way as any other contact.
 */
@Service
public class TeacherReminderService {
    /** Notes starting with this are reminders; the follow-up section labels them as such. */
    public static final String NOTE_PREFIX = "Đã gửi nhắc nhở: ";
    static final int MAX_TITLE = 255, MAX_MESSAGE = 2000, MAX_STUDENTS = 500;
    static final Set<String> SOURCE_TYPES = Set.of("assignment", "quiz");

    private final TeacherRepository teachers;
    private final InsightsRepository insights;
    private final TeacherNoteRepository notes;

    public TeacherReminderService(TeacherRepository teachers, InsightsRepository insights, TeacherNoteRepository notes) {
        this.teachers = teachers;
        this.insights = insights;
        this.notes = notes;
    }

    @Transactional
    public Map<String, Object> send(Long teacherId, Long courseId, Map<String, Object> payload) {
        if (!teachers.hasCourse(teacherId, courseId)) throw new ResourceNotFoundException("Teacher course not found");
        String title = trimmed(payload.get("title"));
        String message = trimmed(payload.get("message"));
        if (title == null) throw new InvalidRequestException("Tiêu đề nhắc nhở không được để trống");
        if (message == null) throw new InvalidRequestException("Nội dung nhắc nhở không được để trống");
        if (title.length() > MAX_TITLE) throw new InvalidRequestException("Tiêu đề quá dài");
        if (message.length() > MAX_MESSAGE) throw new InvalidRequestException("Nội dung quá dài");

        String sourceType = trimmed(payload.get("source_type"));
        Long sourceId = payload.get("source_id") instanceof Number n ? n.longValue() : null;
        if (sourceType != null && !SOURCE_TYPES.contains(sourceType)) {
            throw new InvalidRequestException("Loại hoạt động không hợp lệ");
        }
        if ((sourceType == null) != (sourceId == null)) {
            throw new InvalidRequestException("Cần cả loại và mã hoạt động");
        }

        if (!(payload.get("student_ids") instanceof List<?> raw) || raw.isEmpty()) {
            throw new InvalidRequestException("Chưa chọn sinh viên nào");
        }
        Set<Long> ids = new LinkedHashSet<>();
        for (Object o : raw) {
            if (!(o instanceof Number n)) throw new InvalidRequestException("Mã sinh viên không hợp lệ");
            ids.add(n.longValue());
        }
        if (ids.size() > MAX_STUDENTS) throw new InvalidRequestException("Quá nhiều sinh viên trong một lần nhắc");
        Set<Long> roster = new HashSet<>();
        for (Map<String, Object> s : teachers.findStudents(teacherId, courseId)) roster.add(lng(s.get("userid")));
        // V2-N8: same answer as any other roster check (404), so the endpoint does not confirm which
        // user ids exist outside the class; nothing is written.
        if (!roster.containsAll(ids)) throw new ResourceNotFoundException("Student not in this course");

        for (Long id : ids) {
            insights.insertStudentNotification(id, courseId, title, message, sourceType, sourceId);
            notes.save(teacherId, id, courseId, NOTE_PREFIX + title, "active");
        }
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("sent", ids.size());
        return out;
    }

    private static String trimmed(Object v) {
        if (!(v instanceof String s)) return null;
        String t = s.trim();
        return t.isEmpty() ? null : t;
    }
}
