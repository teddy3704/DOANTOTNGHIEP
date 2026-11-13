package com.dlu.lmsmobile.security;

import com.dlu.lmsmobile.config.DataProfile;
import org.springframework.core.MethodParameter;
import org.springframework.http.MediaType;
import org.springframework.http.converter.HttpMessageConverter;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.servlet.mvc.method.annotation.ResponseBodyAdvice;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

/**
 * REAL-DATA-2: on the real export every teacher response is anonymised on the server, so no screen
 * (assistant, roster, watch list, forecast, quiz analysis, heat map, reminder box, search) can show
 * another student's name, student code, username or e-mail. Each student gets an alias "SV 01",
 * "SV 02"… in first-seen order, stable for the life of the backend so the same student keeps the same
 * alias on every screen. Internal numeric ids stay (they are not personal identifiers on screen).
 * Off on the demo profile (fictional data, unchanged behaviour).
 */
@ControllerAdvice
public class TeacherAnonymizer implements ResponseBodyAdvice<Object> {
    static final Set<String> IDENTITY = Set.of("fullname", "full_name", "student_name", "studentName", "firstname",
        "lastname", "username", "email", "student_code", "studentCode", "idnumber", "fullName");
    static final List<String> ID_KEYS = List.of("studentid", "student_id", "studentId", "userid", "userId", "user_id");

    /**
     * Real export: the only activity signal is a hand-in, so teacher-side reason/legend texts built for
     * the access log are relabelled to say exactly that (longest phrases first).
     */
    static final List<String[]> RELABEL = List.of(
        new String[]{"Liên hệ để biết sinh viên có gặp khó khăn khi truy cập khóa học không",
            "Liên hệ để biết sinh viên có gặp khó khăn khi nộp bài hoặc làm bài kiểm tra không"},
        new String[]{"Không có sự kiện học tập trong 7 ngày", "Không nộp bài hoặc làm bài kiểm tra trong 7 ngày"},
        new String[]{"Không có hoạt động nào trong 7 ngày qua", "Không nộp bài hoặc làm bài kiểm tra nào trong 7 ngày qua"},
        new String[]{"Chưa từng truy cập khóa học", "Chưa từng nộp bài hoặc làm bài kiểm tra"},
        new String[]{"Chưa từng truy cập môn học", "Chưa từng nộp bài hoặc làm bài kiểm tra"},
        new String[]{"Không hoạt động 7–13 ngày", "Không nộp bài hoặc làm bài kiểm tra 7–13 ngày"},
        new String[]{"số sinh viên có hoạt động trong tuần", "số sinh viên có nộp bài hoặc làm bài kiểm tra trong tuần"},
        new String[]{"số hoạt động được hoàn thành trong tuần", "số hoạt động có chấm điểm được hoàn thành trong tuần"},
        new String[]{" ngày không truy cập", " ngày chưa nộp bài hoặc làm bài kiểm tra"},
        new String[]{" ngày chưa truy cập", " ngày chưa nộp bài hoặc làm bài kiểm tra"},
        new String[]{" ngày chưa hoạt động", " ngày chưa nộp bài hoặc làm bài kiểm tra"},
        new String[]{"Tiến độ học tập", "Tiến độ (theo hoạt động có chấm điểm)"});

    private final boolean on;
    private final Map<Long, String> aliases = new ConcurrentHashMap<>();
    private final Map<String, String> byValue = new ConcurrentHashMap<>();
    private final java.util.concurrent.atomic.AtomicInteger counter = new java.util.concurrent.atomic.AtomicInteger();

    /** Reads the property directly: controller advice also loads in slice tests that have no DataProfile bean. */
    @org.springframework.beans.factory.annotation.Autowired
    public TeacherAnonymizer(@org.springframework.beans.factory.annotation.Value("${app.data-profile:demo}") String profile) {
        this(new DataProfile(profile));
    }

    public TeacherAnonymizer(DataProfile profile) {
        this.on = profile.handInsOnly();
    }

    @Override
    public boolean supports(MethodParameter returnType, Class<? extends HttpMessageConverter<?>> converterType) {
        return on;
    }

    @Override
    public Object beforeBodyWrite(Object body, MethodParameter returnType, MediaType contentType,
                                  Class<? extends HttpMessageConverter<?>> converterType,
                                  ServerHttpRequest request, ServerHttpResponse response) {
        String path = request.getURI().getPath();
        return path != null && path.contains("/api/v1/dev/teachers/") ? anonymise(body) : body;
    }

    /** Deep copy with every identity field replaced by the student's alias. */
    public Object anonymise(Object v) {
        if (v instanceof Map<?, ?> m) {
            Long id = null;
            for (String k : ID_KEYS) {
                if (m.get(k) instanceof Number n) { id = n.longValue(); break; }
            }
            Map<Object, Object> out = new LinkedHashMap<>();
            for (Map.Entry<?, ?> e : m.entrySet()) {
                Object key = e.getKey();
                Object val = e.getValue();
                if (key instanceof String s && IDENTITY.contains(s) && val != null) {
                    out.put(key, alias(id, String.valueOf(val)));
                } else {
                    out.put(key, anonymise(val));
                }
            }
            return out;
        }
        if (v instanceof Collection<?> c) {
            List<Object> out = new ArrayList<>(c.size());
            for (Object o : c) out.add(anonymise(o));
            return out;
        }
        if (v instanceof String str) return relabel(str);
        return v;
    }

    static String relabel(String s) {
        String out = s;
        for (String[] r : RELABEL) out = out.replace(r[0], r[1]);
        // Any other "Tiến độ x" becomes graded-activity progress, never twice.
        return out.replaceAll("Tiến độ (?!\\(theo hoạt động có chấm điểm\\))", "Tiến độ (theo hoạt động có chấm điểm) ");
    }

    String alias(Long id, String value) {
        if (id != null) return aliases.computeIfAbsent(id, k -> next());
        return byValue.computeIfAbsent(value, k -> next());
    }

    private String next() {
        return String.format("SV %02d", counter.incrementAndGet());
    }
}
