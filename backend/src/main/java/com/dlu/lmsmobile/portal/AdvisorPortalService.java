package com.dlu.lmsmobile.portal;

import com.dlu.lmsmobile.exception.InvalidRequestException;
import com.dlu.lmsmobile.exception.ResourceNotFoundException;
import com.dlu.lmsmobile.portal.PortalModels.*;
import com.dlu.lmsmobile.repository.TeacherRepository;
import com.dlu.lmsmobile.service.LearningHealthService;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Clock;
import java.time.LocalDate;
import java.util.*;

/**
 * V3-P6: advisor class view for a teacher's configured classes only. Class lists from the Portal
 * are reduced to advising fields; names/IDs are masked when presentation mode is on. The LMS
 * bridge only shows students who are in one of this teacher's own Moodle courses.
 */
@Service
public class AdvisorPortalService {
    static final BigDecimal LOW_GPA = new BigDecimal("2.0");
    static final int SEARCH_YEARS = 8;
    static final double[][] HISTOGRAM = {{0, 1}, {1, 2}, {2, 2.5}, {2.5, 3.2}, {3.2, 3.6}, {3.6, 4.01}};

    private final PortalClient portal;
    private final PortalIdentity identity;
    private final TeacherRepository teachers;
    private final LearningHealthService health;
    private final Clock clock;

    public AdvisorPortalService(PortalClient portal, PortalIdentity identity, TeacherRepository teachers,
                                LearningHealthService health, Clock clock) {
        this.portal = portal;
        this.identity = identity;
        this.teachers = teachers;
        this.health = health;
        this.clock = clock;
    }

    public record TermKey(String yearStudy, String termId) {
    }

    public Map<String, Object> classes(Long teacherId) {
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("classes", identity.advisorClasses(teacherId));
        out.put("presentationMask", portal.properties().isPresentationMask());
        return out;
    }

    /** Terms with grade data, newest first (the data is static: never assume "now" has data). */
    List<TermKey> termsWithData(String classId) {
        List<TermKey> found = new ArrayList<>();
        int startYear = LocalDate.now(clock).getYear() + 1;
        for (int y = startYear; y > startYear - SEARCH_YEARS; y--) {
            String year = (y - 1) + "-" + y;
            boolean any = false;
            for (String term : List.of("HK02", "HK01")) {
                if (PortalParser.classGrades(portal.classGrades(year, term, classId)).stream().anyMatch(ClassGrade::hasData)) {
                    found.add(new TermKey(year, term));
                    any = true;
                }
            }
            if (!any && !found.isEmpty()) break;
        }
        return found;
    }

    private TermKey pick(List<TermKey> terms, String yearStudy, String termId) {
        if (terms.isEmpty()) throw new ResourceNotFoundException("No Portal data for this class");
        if (yearStudy == null && termId == null) return terms.get(0);
        return terms.stream().filter(t -> t.yearStudy().equals(yearStudy) && t.termId().equals(termId)).findFirst()
            .orElseThrow(() -> new ResourceNotFoundException("Term not available"));
    }

    private boolean masked(Boolean mask) {
        return mask == null ? portal.properties().isPresentationMask() : mask;
    }

    record Row(int no, ClassGrade grade, Conduct conduct) {
    }

    private List<Row> rows(String classId, TermKey t) {
        List<ClassGrade> grades = new ArrayList<>(PortalParser.classGrades(portal.classGrades(t.yearStudy(), t.termId(), classId)));
        grades.removeIf(g -> g.studentId() == null);
        grades.sort(Comparator.comparing(ClassGrade::studentId));
        Map<String, Conduct> conduct = new HashMap<>();
        for (Conduct c : PortalParser.conduct(portal.classConduct(t.yearStudy(), t.termId(), classId))) {
            if (c.studentId() != null) conduct.put(c.studentId(), c);
        }
        List<Row> out = new ArrayList<>();
        for (int i = 0; i < grades.size(); i++) out.add(new Row(i + 1, grades.get(i), conduct.get(grades.get(i).studentId())));
        return out;
    }

    List<String> flags(Row r) {
        List<String> f = new ArrayList<>();
        ClassGrade g = r.grade();
        if (!g.hasData()) f.add("NO_SCORE");
        else if (g.average4() != null && g.average4().compareTo(LOW_GPA) < 0) f.add("LOW_GPA");
        String rank = PortalStudentText.fold(g.rank());
        if (rank.equals("yeu") || rank.equals("kem")) f.add("WEAK_RANK");
        BigDecimal conductScore = r.conduct() == null ? null : r.conduct().finalScore();
        if (conductScore != null && conductScore.compareTo(portal.properties().getConductThreshold()) < 0) f.add("LOW_CONDUCT");
        return f;
    }

    private Map<String, Object> studentJson(Row r, boolean mask) {
        ClassGrade g = r.grade();
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("no", r.no());
        m.put("name", mask ? String.format("SV %02d", r.no()) : PortalParser.fullName(g));
        m.put("studentId", mask ? PortalValues.maskId(g.studentId()) : g.studentId());
        m.put("gpa4", n2(g.average4()));
        m.put("gpa10", n2(g.average10()));
        m.put("cumulativeGpa4", n2(g.cumulative4()));
        m.put("credits", n2(g.credits()));
        m.put("rank", g.rank());
        m.put("conduct", r.conduct() == null ? null : n2(r.conduct().finalScore()));
        List<String> f = flags(r);
        m.put("flags", f);
        m.put("attention", !f.isEmpty());
        return m;
    }

    public Map<String, Object> overview(Long teacherId, String classId, String yearStudy, String termId, Boolean mask) {
        String cls = identity.advisorClass(teacherId, classId);
        boolean hide = masked(mask);
        List<TermKey> terms = termsWithData(cls);
        TermKey t = pick(terms, yearStudy, termId);
        List<Row> rows = rows(cls, t);
        List<ClassMember> members = PortalParser.classMembers(portal.classStudents(cls));

        Map<String, Integer> ranks = new LinkedHashMap<>();
        int[] hist = new int[HISTOGRAM.length];
        List<Map<String, Object>> students = new ArrayList<>();
        int attention = 0;
        for (Row r : rows) {
            ranks.merge(r.grade().rank() == null ? "Chưa có" : r.grade().rank(), 1, Integer::sum);
            BigDecimal a4 = r.grade().average4();
            if (a4 != null) {
                for (int i = 0; i < HISTOGRAM.length; i++) {
                    if (a4.doubleValue() >= HISTOGRAM[i][0] && a4.doubleValue() < HISTOGRAM[i][1]) { hist[i]++; break; }
                }
            }
            Map<String, Object> s = studentJson(r, hide);
            if ((Boolean) s.get("attention")) attention++;
            students.add(s);
        }
        int idx = terms.indexOf(t);
        TermKey previous = idx + 1 < terms.size() ? terms.get(idx + 1) : null;
        Double avg = average(rows);
        Double prevAvg = previous == null ? null : average(rows(cls, previous));

        Map<String, Object> out = new LinkedHashMap<>();
        out.put("classId", cls);
        out.put("term", termJson(t));
        out.put("terms", terms.stream().map(AdvisorPortalService::termJson).toList());
        out.put("previousTerm", previous == null ? null : termJson(previous));
        out.put("size", members.stream().filter(ClassMember::inClass).count());
        out.put("ranks", ranks);
        List<Map<String, Object>> histogram = new ArrayList<>();
        for (int i = 0; i < HISTOGRAM.length; i++) {
            histogram.add(Map.of("from", HISTOGRAM[i][0], "to", Math.min(4.0, HISTOGRAM[i][1]), "count", hist[i]));
        }
        out.put("histogram", histogram);
        out.put("averageGpa4", avg);
        out.put("previousAverageGpa4", prevAvg);
        out.put("trend", avg == null || prevAvg == null ? null : n2(BigDecimal.valueOf(avg - prevAvg)));
        out.put("conductThreshold", n2(portal.properties().getConductThreshold()));
        out.put("attentionCount", attention);
        out.put("mask", hide);
        out.put("students", students);
        return out;
    }

    private static Double average(List<Row> rows) {
        OptionalDouble a = rows.stream().map(r -> r.grade().average4()).filter(Objects::nonNull)
            .mapToDouble(BigDecimal::doubleValue).average();
        return a.isPresent() ? Math.round(a.getAsDouble() * 100.0) / 100.0 : null;
    }

    public Map<String, Object> student(Long teacherId, String classId, int no, String yearStudy, String termId, Boolean mask) {
        String cls = identity.advisorClass(teacherId, classId);
        boolean hide = masked(mask);
        List<TermKey> terms = termsWithData(cls);
        TermKey t = pick(terms, yearStudy, termId);
        Row row = rows(cls, t).stream().filter(r -> r.no() == no).findFirst()
            .orElseThrow(() -> new ResourceNotFoundException("Student not in class"));
        String studentId = row.grade().studentId();
        Map<String, Object> out = new LinkedHashMap<>(studentJson(row, hide));
        out.put("term", termJson(t));
        if (row.conduct() != null) {
            Map<String, Object> cd = new LinkedHashMap<>();
            cd.put("self", n2(row.conduct().selfScore()));
            cd.put("class", n2(row.conduct().classScore()));
            cd.put("department", n2(row.conduct().departmentScore()));
            out.put("conductDetail", cd);
        }
        List<Map<String, Object>> history = new ArrayList<>();
        for (TermKey k : terms) {
            rows(cls, k).stream().filter(r -> studentId.equals(r.grade().studentId())).findFirst().ifPresent(r -> {
                Map<String, Object> h = new LinkedHashMap<>(termJson(k));
                h.put("gpa4", n2(r.grade().average4()));
                h.put("cumulativeGpa4", n2(r.grade().cumulative4()));
                h.put("conduct", r.conduct() == null ? null : n2(r.conduct().finalScore()));
                history.add(h);
            });
        }
        Collections.reverse(history);
        out.put("history", history);
        out.put("lms", lmsBridge(teacherId, studentId));
        return out;
    }

    /** N9 signals for the Moodle account linked to this StudentID, limited to the teacher's courses. */
    Map<String, Object> lmsBridge(Long teacherId, String studentId) {
        Map<Long, String> taught = new LinkedHashMap<>();
        Map<Long, Long> rosterUser = new HashMap<>();
        Long linked = null;
        for (Map<String, Object> c : teachers.findCoursesByTeacherId(teacherId)) {
            if (!(c.get("courseid") instanceof Number cid)) continue;
            taught.put(cid.longValue(), Objects.toString(c.get("course_name"), null));
            for (Map<String, Object> s : teachers.findStudents(teacherId, cid.longValue())) {
                if (!(s.get("userid") instanceof Number uid)) continue;
                rosterUser.put(uid.longValue(), uid.longValue());
                if (linked == null && studentId.equalsIgnoreCase(Objects.toString(s.get("student_code"), ""))) {
                    linked = uid.longValue();
                }
            }
        }
        if (linked == null) linked = configuredLink(studentId);
        Map<String, Object> out = new LinkedHashMap<>();
        if (linked == null || !rosterUser.containsKey(linked)) {
            out.put("linked", false);
            return out;
        }
        List<Map<String, Object>> courses = new ArrayList<>();
        Map<String, Object> overview = health.overview(linked);
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> all = overview == null ? null : (List<Map<String, Object>>) overview.get("courses");
        for (Map<String, Object> c : all == null ? List.<Map<String, Object>>of() : all) {
            if (c.get("courseId") instanceof Number cid && taught.containsKey(cid.longValue())) courses.add(c);
        }
        out.put("linked", true);
        out.put("courses", courses);
        return out;
    }

    private Long configuredLink(String studentId) {
        PortalProperties p = portal.properties();
        for (Map.Entry<Long, String> e : p.getLmsStudentLinks().entrySet()) {
            if (studentId.equalsIgnoreCase(e.getValue())) return e.getKey();
        }
        for (Map.Entry<Long, PortalProperties.StudentLink> e : p.getStudents().entrySet()) {
            if (studentId.equalsIgnoreCase(e.getValue().getStudentId())) return e.getKey();
        }
        return null;
    }

    /** CSV for the advisor (N8-style export). Only with presentation mode off and explicit confirmation. */
    public String exportCsv(Long teacherId, String classId, String yearStudy, String termId, Boolean mask, boolean confirm) {
        if (!confirm) throw new InvalidRequestException("Xác nhận trước khi xuất dữ liệu");
        if (masked(mask)) throw new InvalidRequestException("Tắt chế độ ẩn danh trước khi xuất");
        Map<String, Object> o = overview(teacherId, classId, yearStudy, termId, false);
        StringBuilder b = new StringBuilder("﻿STT,MSSV,Họ tên,ĐTB hệ 4,ĐTB hệ 10,TB tích lũy hệ 4,Xếp loại,Điểm rèn luyện,Cần quan tâm\r\n");
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> students = (List<Map<String, Object>>) o.get("students");
        for (Map<String, Object> s : students) {
            b.append(String.join(",", csv(s.get("no")), csv(s.get("studentId")), csv(s.get("name")), csv(s.get("gpa4")),
                csv(s.get("gpa10")), csv(s.get("cumulativeGpa4")), csv(s.get("rank")), csv(s.get("conduct")),
                csv(String.join(" ", PortalAdvisorText.flagLabels(s.get("flags")))))).append("\r\n");
        }
        return b.toString();
    }

    static String csv(Object v) {
        if (v == null) return "";
        String s = v.toString();
        if (!s.isEmpty() && "=+-@".indexOf(s.charAt(0)) >= 0) s = "'" + s; // spreadsheet formula injection
        return s.contains(",") || s.contains("\"") || s.contains("\n") ? '"' + s.replace("\"", "\"\"") + '"' : s;
    }

    private static Map<String, Object> termJson(TermKey t) {
        return Map.of("yearStudy", t.yearStudy(), "termId", t.termId());
    }

    static Double n2(BigDecimal v) {
        return v == null ? null : v.setScale(2, RoundingMode.HALF_UP).doubleValue();
    }
}
