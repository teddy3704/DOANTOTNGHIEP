package com.dlu.lmsmobile.portal;

import com.dlu.lmsmobile.repository.HealthRepository;
import com.dlu.lmsmobile.repository.StudentRepository;
import com.dlu.lmsmobile.repository.TeacherRepository;
import org.springframework.stereotype.Service;

import java.util.*;

/** V3-P7: data sources, fields used / not used and cache policy, for both roles. */
@Service
public class PortalSourcesService {
    static final String PROVIDER = "Dữ liệu đào tạo lấy từ API Portal Online DLU Proxy do thầy Nguyễn Trọng Hiếu cung cấp. "
        + "Đây là dữ liệu mô phỏng có cấu trúc giống Portal đào tạo của Trường; ứng dụng đã thiết kế sẵn các biện pháp "
        + "bảo vệ để nối với dữ liệu thật.";

    /** Fields the backend reads, per Portal endpoint (mirrors PortalParser). */
    static final List<Map<String, Object>> USED = List.of(
        used("Bảng điểm sinh viên", "Học phần, tín chỉ, điểm hệ 10/4/chữ, đạt, TB học kỳ và tích lũy, tín chỉ đạt, xếp loại"),
        used("Chương trình đào tạo", "Mã và tên học phần, tín chỉ, LT/TH, học kỳ, bắt buộc/tự chọn, học phần tiên quyết/học trước"),
        used("Điểm theo lớp (cố vấn)", "MSSV, họ tên, tín chỉ, ĐTB hệ 10/4, TB tích lũy, xếp loại, điểm rèn luyện"),
        used("Điểm rèn luyện theo lớp", "MSSV, điểm tự đánh giá, lớp, khoa, điểm cuối"),
        used("Danh sách lớp", "MSSV, họ tên, lớp, CTĐT, còn trong lớp, vai trò"),
        used("Quyết định", "Tên, loại, nội dung, ngày ký, năm học, học kỳ"));

    static final List<Map<String, Object>> NOT_USED = List.of(
        Map.of("fields", "Số điện thoại, ngày sinh, nơi sinh, hộ khẩu, giới tính", "reason", "Không cần cho học tập"),
        Map.of("fields", "Các trường tiếng Anh (*_Eng)", "reason", "Trùng nội dung"),
        Map.of("fields", "Số hiệu bằng, quyết định tốt nghiệp, người cập nhật", "reason", "Không cần cho học tập"),
        Map.of("fields", "Miễn giảm học phí", "reason",
            "Cho biết đối tượng chính sách, dân tộc: dữ liệu cá nhân nhạy cảm (Nghị định 13/2023/NĐ-CP)"));

    private final PortalClient portal;
    private final HealthRepository health;
    private final StudentRepository students;
    private final TeacherRepository teachers;

    public PortalSourcesService(PortalClient portal, HealthRepository health, StudentRepository students,
                                TeacherRepository teachers) {
        this.portal = portal;
        this.health = health;
        this.students = students;
        this.teachers = teachers;
    }

    private static Map<String, Object> used(String source, String fields) {
        return Map.of("source", source, "fields", fields);
    }

    public Map<String, Object> forStudent(Long userId) {
        Map<Long, String> names = new HashMap<>();
        for (Map<String, Object> c : students.findCoursesByUserId(userId)) {
            if (c.get("courseid") instanceof Number n) names.put(n.longValue(), Objects.toString(c.get("course_name"), null));
        }
        Map<String, Object> out = base();
        PortalProperties p = portal.properties();
        out.put("linked", p.getStudents().containsKey(userId) && p.getStudents().get(userId).complete());
        out.put("courseMappings", mappings(names));
        return out;
    }

    public Map<String, Object> forTeacher(Long teacherId) {
        Map<Long, String> names = new HashMap<>();
        for (Map<String, Object> c : teachers.findCoursesByTeacherId(teacherId)) {
            if (c.get("courseid") instanceof Number n) names.put(n.longValue(), Objects.toString(c.get("course_name"), null));
        }
        Map<String, Object> out = base();
        List<String> classes = portal.properties().getAdvisors().getOrDefault(teacherId, List.of());
        out.put("linked", !classes.isEmpty());
        out.put("advisorClasses", classes);
        out.put("courseMappings", mappings(names));
        out.put("linkedLmsStudents", portal.properties().getLmsStudentLinks().size());
        return out;
    }

    private List<Map<String, Object>> mappings(Map<Long, String> visibleCourses) {
        List<Map<String, Object>> list = new ArrayList<>();
        portal.properties().getCourseMap().forEach((lmsId, code) -> {
            if (!visibleCourses.containsKey(lmsId)) return;
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("lmsCourseId", lmsId);
            m.put("lmsCourseName", visibleCourses.get(lmsId));
            m.put("portalCode", code);
            list.add(m);
        });
        return list;
    }

    private Map<String, Object> base() {
        Map<String, Object> out = new LinkedHashMap<>();
        boolean db;
        try {
            db = health.isDatabaseConnected();
        } catch (RuntimeException e) {
            db = false;
        }
        out.put("lms", Map.of("status", db ? "UP" : "DOWN"));
        Map<String, Object> p = new LinkedHashMap<>();
        p.put("status", portal.health().name());
        p.put("lastSuccess", portal.lastSuccess() == null ? null : portal.lastSuccess().toString());
        p.put("cacheMinutes", portal.properties().getCacheTtl().toMinutes());
        p.put("provider", PROVIDER);
        out.put("portal", p);
        out.put("demoMapping", portal.properties().isDemoMapping());
        out.put("used", USED);
        out.put("notUsed", NOT_USED);
        return out;
    }
}
