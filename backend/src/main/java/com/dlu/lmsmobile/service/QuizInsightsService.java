package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.exception.ResourceNotFoundException;
import com.dlu.lmsmobile.repository.QuizInsightsRepository;
import com.dlu.lmsmobile.repository.TeacherRepository;
import org.springframework.stereotype.Service;

import java.util.*;

import static com.dlu.lmsmobile.service.Values.*;

/**
 * V2-N16 quiz analysis for one teacher course. Per quiz: 5-band histogram of the latest finished attempt
 * of each roster student, median duration, share of the roster with no attempt, and automatic flags:
 * TOO_HARD (mean &lt; 50% with ≥ 3 finished), MANY_SKIPPED (no attempt ≥ 40%),
 * TOO_FAST (median duration &lt; 20% of the time limit; only when the quiz has a time limit).
 */
@Service
public class QuizInsightsService {
    public static final double HARD_MEAN = 50, SKIPPED_SHARE = 0.40, FAST_SHARE = 0.20;
    public static final int MIN_FINISHED_FOR_HARD = 3;

    private final QuizInsightsRepository quizzes;
    private final TeacherRepository teachers;

    public QuizInsightsService(QuizInsightsRepository quizzes, TeacherRepository teachers) {
        this.quizzes = quizzes;
        this.teachers = teachers;
    }

    /** One finished attempt: percent may be null (not graded), seconds may be null (missing times). */
    public record Finished(Double percent, Long seconds) {
    }

    public record Analysis(int[] histogram, Double mean, Long medianSeconds, int finished, int attempted,
                           int notAttempted, double notAttemptedShare, List<String> flags) {
    }

    /** Pure. {@code roster} = class size; {@code attempted} = roster students with any attempt. */
    public static Analysis analyze(List<Finished> finished, int roster, int attempted, long timeLimitSeconds) {
        int[] hist = new int[5];
        double sum = 0;
        int graded = 0;
        List<Long> durations = new ArrayList<>();
        for (Finished f : finished) {
            if (f.percent() != null) {
                double p = Math.max(0, Math.min(100, f.percent()));
                hist[Math.min(4, (int) (p / 20))]++;
                sum += p;
                graded++;
            }
            if (f.seconds() != null && f.seconds() > 0) durations.add(f.seconds());
        }
        Double mean = graded == 0 ? null : sum / graded;
        Long median = null;
        if (!durations.isEmpty()) {
            Collections.sort(durations);
            int n = durations.size();
            median = n % 2 == 1 ? durations.get(n / 2) : (durations.get(n / 2 - 1) + durations.get(n / 2)) / 2;
        }
        int notAttempted = Math.max(0, roster - attempted);
        double share = roster == 0 ? 0 : (double) notAttempted / roster;
        List<String> flags = new ArrayList<>();
        if (mean != null && mean < HARD_MEAN && graded >= MIN_FINISHED_FOR_HARD) flags.add("TOO_HARD");
        if (roster > 0 && share >= SKIPPED_SHARE) flags.add("MANY_SKIPPED");
        if (timeLimitSeconds > 0 && median != null && median < FAST_SHARE * timeLimitSeconds) flags.add("TOO_FAST");
        return new Analysis(hist, mean, median, finished.size(), attempted, notAttempted, share, flags);
    }

    public Map<String, Object> insights(Long teacherId, Long courseId) {
        if (!teachers.hasCourse(teacherId, courseId)) throw new ResourceNotFoundException("Teacher course not found");
        Set<Long> roster = new LinkedHashSet<>();
        for (Map<String, Object> s : teachers.findStudents(teacherId, courseId)) roster.add(lng(s.get("userid")));

        Map<Long, List<Map<String, Object>>> byQuiz = new HashMap<>();
        for (Map<String, Object> a : quizzes.findLatestAttempts(courseId)) {
            if (!roster.contains(lng(a.get("userid")))) continue;
            byQuiz.computeIfAbsent(lng(a.get("quiz_id")), k -> new ArrayList<>()).add(a);
        }

        List<Map<String, Object>> out = new ArrayList<>();
        for (Map<String, Object> q : quizzes.findQuizzes(teacherId, courseId)) {
            List<Map<String, Object>> attempts = byQuiz.getOrDefault(lng(q.get("quiz_id")), List.of());
            Set<Long> attemptedIds = new HashSet<>();
            List<Finished> finished = new ArrayList<>();
            for (Map<String, Object> a : attempts) {
                attemptedIds.add(lng(a.get("userid")));
                if (!"finished".equals(str(a.get("state")))) continue;
                long start = lng(a.get("timestart")), end = lng(a.get("timefinish"));
                finished.add(new Finished(num(a.get("percent")), start > 0 && end > start ? end - start : null));
            }
            Analysis an = analyze(finished, roster.size(), attemptedIds.size(), lng(q.get("timelimit")));
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("quizId", lng(q.get("quiz_id")));
            m.put("name", str(q.get("quiz_name")));
            m.put("timeClose", lng(q.get("timeclose")) > 0 ? lng(q.get("timeclose")) : null);
            m.put("timeLimitSeconds", lng(q.get("timelimit")));
            m.put("moodlePath", q.get("moodle_path"));
            m.put("courseModuleId", q.get("coursemoduleid") instanceof Number n ? n.longValue() : null);
            m.put("rosterSize", roster.size());
            m.put("finished", an.finished());
            m.put("attempted", an.attempted());
            m.put("notAttempted", an.notAttempted());
            m.put("notAttemptedPercent", round1(an.notAttemptedShare() * 100));
            m.put("histogram", Arrays.stream(an.histogram()).boxed().toList());
            m.put("meanPercent", round1(an.mean()));
            m.put("medianSeconds", an.medianSeconds());
            m.put("flags", an.flags());
            // Roster ids only (the teacher already sees the roster): used by "Nhắc những sinh viên chưa làm".
            m.put("notAttemptedUserIds", roster.stream().filter(id -> !attemptedIds.contains(id)).toList());
            out.add(m);
        }
        Map<String, Object> res = new LinkedHashMap<>();
        res.put("courseId", courseId);
        res.put("quizzes", out);
        return res;
    }
}
