package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.exception.InvalidRequestException;
import com.dlu.lmsmobile.repository.FlashcardRepository;
import com.dlu.lmsmobile.repository.StudentRepository;
import com.dlu.lmsmobile.repository.TeacherRepository;
import org.springframework.stereotype.Service;

import java.text.Normalizer;
import java.util.*;

import static com.dlu.lmsmobile.service.Values.*;

/**
 * V2-N13 quick search over the caller's OWN data only. Matching happens in Java on rows already scoped
 * by user/roster, so the query text never reaches SQL. Vietnamese accent-insensitive: NFD, combining marks
 * removed, đ→d, lower case ("nguyen" finds "Nguyễn"). q: 2–100 characters; at most 20 results.
 */
@Service
public class SearchService {
    public static final int MIN_Q = 2, MAX_Q = 100, MAX_RESULTS = 20;
    static final List<String> STUDENT_ORDER = List.of("course", "task", "activity", "flashcard");
    static final List<String> TEACHER_ORDER = List.of("course", "student", "assignment", "quiz");

    private final StudentRepository students;
    private final FlashcardRepository flashcards;
    private final TeacherRepository teachers;

    public SearchService(StudentRepository students, FlashcardRepository flashcards, TeacherRepository teachers) {
        this.students = students;
        this.flashcards = flashcards;
        this.teachers = teachers;
    }

    /** Pure: accent- and case-insensitive form. */
    public static String fold(String s) {
        if (s == null) return "";
        String n = Normalizer.normalize(s, Normalizer.Form.NFD).replaceAll("\\p{M}+", "");
        return n.replace('đ', 'd').replace('Đ', 'D').toLowerCase(Locale.ROOT).replaceAll("\\s+", " ").trim();
    }

    static String validQuery(String q) {
        String t = q == null ? "" : q.trim();
        if (t.length() < MIN_Q || t.length() > MAX_Q) {
            throw new InvalidRequestException("Từ khóa phải dài từ " + MIN_Q + " đến " + MAX_Q + " ký tự");
        }
        return fold(t);
    }

    /** One candidate before filtering. {@code text} is what the query is matched against. */
    record Candidate(String type, String title, String subtitle, String text, Map<String, Object> extra) {
    }

    /**
     * Pure: keeps candidates whose folded text contains every query word; title starts-with ranks first;
     * groups in {@code order}; at most {@link #MAX_RESULTS}; duplicates (same type + title + subtitle) once.
     */
    static Map<String, Object> rank(String folded, List<Candidate> candidates, List<String> order) {
        String[] words = folded.split(" ");
        Map<String, List<Candidate>> byType = new LinkedHashMap<>();
        for (String t : order) byType.put(t, new ArrayList<>());
        Set<String> seen = new HashSet<>();
        for (Candidate c : candidates) {
            String hay = fold(c.text());
            boolean all = true;
            for (String w : words) if (!hay.contains(w)) { all = false; break; }
            if (!all || !byType.containsKey(c.type())) continue;
            if (!seen.add(c.type() + "|" + c.title() + "|" + c.subtitle())) continue;
            byType.get(c.type()).add(c);
        }
        List<Map<String, Object>> results = new ArrayList<>();
        int total = 0;
        for (Map.Entry<String, List<Candidate>> g : byType.entrySet()) {
            List<Candidate> list = g.getValue();
            list.sort(Comparator.comparing((Candidate c) -> !fold(c.title()).startsWith(words[0]))
                .thenComparing(c -> fold(c.title())));
            for (Candidate c : list) {
                if (results.size() >= MAX_RESULTS) break;
                Map<String, Object> m = new LinkedHashMap<>();
                m.put("type", c.type());
                m.put("title", c.title());
                m.put("subtitle", c.subtitle());
                m.putAll(c.extra());
                results.add(m);
            }
            total += list.size();
        }
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("results", results);
        out.put("total", total);
        out.put("truncated", total > results.size());
        return out;
    }

    public Map<String, Object> student(Long userId, String q) {
        String folded = validQuery(q);
        List<Candidate> c = new ArrayList<>();
        for (Map<String, Object> course : students.findCoursesByUserId(userId)) {
            long courseId = lng(course.get("courseid"));
            String name = str(course.get("course_name"));
            c.add(new Candidate("course", name, str(course.get("course_shortname")),
                name + " " + str(course.get("course_shortname")), Map.of("courseId", courseId)));
            for (Map<String, Object> li : students.findLearningItemsByUserIdAndCourseId(userId, courseId)) {
                Map<String, Object> extra = new HashMap<>();
                extra.put("courseId", courseId);
                extra.put("moodlePath", li.get("moodle_path"));
                extra.put("courseModuleId", li.get("coursemoduleid") instanceof Number n ? n.longValue() : null);
                c.add(new Candidate("activity", str(li.get("activity_name")),
                    name + " · " + nz(str(li.get("section_name"))),
                    str(li.get("activity_name")) + " " + str(li.get("section_name")), extra));
            }
            for (Map<String, Object> f : flashcards.findByCourseIdAndUserId(courseId, userId)) {
                c.add(new Candidate("flashcard", str(f.get("front_text")), name,
                    str(f.get("front_text")) + " " + str(f.get("back_text")), Map.of("courseId", courseId)));
            }
        }
        for (Map<String, Object> t : students.findAllTasks(userId)) {
            Map<String, Object> extra = new HashMap<>();
            extra.put("courseId", t.get("courseid") instanceof Number n ? n.longValue() : null);
            extra.put("dueTime", lng(t.get("due_time")) > 0 ? lng(t.get("due_time")) : null);
            extra.put("status", str(t.get("task_status")));
            extra.put("moodlePath", t.get("moodle_path"));
            extra.put("courseModuleId", t.get("coursemoduleid") instanceof Number n ? n.longValue() : null);
            c.add(new Candidate("task", str(t.get("title")), str(t.get("course_name")),
                str(t.get("title")) + " " + str(t.get("course_name")), extra));
        }
        return rank(folded, c, STUDENT_ORDER);
    }

    public Map<String, Object> teacher(Long teacherId, String q) {
        String folded = validQuery(q);
        List<Candidate> c = new ArrayList<>();
        for (Map<String, Object> course : teachers.findCoursesByTeacherId(teacherId)) {
            long courseId = lng(course.get("courseid"));
            String name = str(course.get("course_name"));
            c.add(new Candidate("course", name, str(course.get("course_shortname")),
                name + " " + str(course.get("course_shortname")), Map.of("courseId", courseId)));
            for (Map<String, Object> s : teachers.findStudents(teacherId, courseId)) {
                String code = str(s.get("student_code"));
                c.add(new Candidate("student", str(s.get("fullname")), (code == null ? "" : code + " · ") + name,
                    str(s.get("fullname")) + " " + nz(code),
                    Map.of("courseId", courseId, "userId", lng(s.get("userid")))));
            }
            for (String type : List.of("assignment", "quiz")) {
                for (Map<String, Object> a : teachers.findActivities(teacherId, courseId, type)) {
                    Map<String, Object> extra = new HashMap<>();
                    extra.put("courseId", courseId);
                    extra.put("sourceId", lng(a.get("source_id")));
                    extra.put("moodlePath", a.get("moodle_path"));
                    extra.put("courseModuleId", a.get("coursemoduleid") instanceof Number n ? n.longValue() : null);
                    c.add(new Candidate(type, str(a.get("title")), name, str(a.get("title")), extra));
                }
            }
        }
        return rank(folded, c, TEACHER_ORDER);
    }

    private static String nz(String s) {
        return s == null ? "" : s;
    }
}
