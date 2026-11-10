package com.dlu.lmsmobile.portal;

import com.dlu.lmsmobile.portal.AcademicEngine.*;
import com.dlu.lmsmobile.portal.PortalModels.*;
import com.dlu.lmsmobile.repository.StudentRepository;
import com.dlu.lmsmobile.service.GradeForecastService;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;

/**
 * V3 P1–P5 for the signed-in student. The Portal identity always comes from server configuration
 * ({@link PortalIdentity}); class-wide lists are filtered to the caller's own row here.
 */
@Service
public class StudentPortalService {
    static final List<String> REGULAR_TERMS = List.of("HK01", "HK02");
    static final int MAX_CONDUCT_TERMS = 10;

    private final PortalClient portal;
    private final PortalIdentity identity;
    private final GradeForecastService forecasts;
    private final StudentRepository students;

    public StudentPortalService(PortalClient portal, PortalIdentity identity, GradeForecastService forecasts,
                                StudentRepository students) {
        this.portal = portal;
        this.identity = identity;
        this.forecasts = forecasts;
        this.students = students;
    }

    // ------------------------------------------------------------ shared loading
    record Context(PortalProperties.StudentLink link, List<Term> terms) {
    }

    private Context load(Long userId) {
        PortalProperties.StudentLink link = identity.student(userId);
        return new Context(link, PortalParser.transcript(portal.studentTranscript(link.getStudentId(), link.getStudyProgramId())));
    }

    private List<ProgramCourse> programCourses(String programId) {
        List<ProgramCourse> own = PortalParser.program(portal.programCourses(programId));
        Optional<String> base = AcademicEngine.baseProgram(programId);
        if (base.isEmpty()) return own;
        return AcademicEngine.merge(PortalParser.program(portal.programCourses(base.get())), own);
    }

    /** Moodle course id → name for the student's enrolled courses that are mapped to a Portal code. */
    private Map<String, Long> lmsByCode(Long userId, Map<Long, String> lmsNames) {
        Map<String, Long> out = new HashMap<>();
        portal.properties().getCourseMap().forEach((lmsId, code) -> {
            if (code != null && lmsNames.containsKey(lmsId)) out.put(code.trim().toUpperCase(Locale.ROOT), lmsId);
        });
        return out;
    }

    private Map<Long, String> enrolledCourseNames(Long userId) {
        Map<Long, String> out = new LinkedHashMap<>();
        for (Map<String, Object> c : students.findCoursesByUserId(userId)) {
            if (c.get("courseid") instanceof Number n) out.put(n.longValue(), Objects.toString(c.get("course_name"), null));
        }
        return out;
    }

    private static Map<String, Object> dataUntil(List<Term> terms) {
        return AcademicEngine.latestScoredTerm(terms)
            .map(t -> Map.<String, Object>of("yearStudy", t.yearStudy(), "termId", t.termId())).orElse(null);
    }

    // ------------------------------------------------------------ P1 transcript
    public Map<String, Object> transcript(Long userId) {
        Context ctx = load(userId);
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("dataUntil", dataUntil(ctx.terms()));
        out.put("summary", summaryOf(ctx.terms()));
        List<Map<String, Object>> terms = new ArrayList<>();
        for (Term t : ctx.terms()) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("yearStudy", t.yearStudy());
            m.put("termId", t.termId());
            m.put("gpa4", n2(t.gpa4()));
            m.put("gpa10", n2(t.gpa10()));
            m.put("cumulativeGpa4", n2(t.cumulativeGpa4()));
            m.put("cumulativeGpa10", n2(t.cumulativeGpa10()));
            m.put("termCredits", n2(t.termCredits()));
            m.put("cumulativeCredits", n2(t.cumulativeCredits()));
            m.put("rank", t.rank());
            m.put("hasScores", t.hasScores());
            List<Map<String, Object>> courses = new ArrayList<>();
            for (CourseResult c : t.courses()) {
                Map<String, Object> cm = new LinkedHashMap<>();
                cm.put("code", c.courseId());
                cm.put("name", c.name());
                cm.put("credits", c.credits());
                cm.put("score10", n2(c.score10()));
                cm.put("score4", n2(c.score4()));
                cm.put("letter", c.letter());
                cm.put("scored", c.scored());
                cm.put("passed", c.passed());
                cm.put("countsForGpa", c.countsForGpa());
                courses.add(cm);
            }
            m.put("courses", courses);
            terms.add(m);
        }
        out.put("terms", terms);
        return out;
    }

    private Map<String, Object> summaryOf(List<Term> terms) {
        Map<String, Object> s = new LinkedHashMap<>();
        Optional<Term> last = AcademicEngine.latestScoredTerm(terms);
        BigDecimal official = last.map(Term::cumulativeGpa4).orElse(null);
        Gpa own = AcademicEngine.recompute(terms);
        s.put("cumulativeGpa4", n2(official));
        s.put("cumulativeGpa10", n2(last.map(Term::cumulativeGpa10).orElse(null)));
        s.put("cumulativeCredits", n2(last.map(Term::cumulativeCredits).orElse(null)));
        s.put("rank", last.map(Term::rank).orElse(null));
        s.put("band", AcademicEngine.bandOf(official, portal.properties().getGradeBands()));
        s.put("recomputedGpa4", n2(own.gpa4()));
        s.put("recomputedCredits", own.credits());
        s.put("gpaDifference", official == null || own.gpa4() == null ? null
            : n2(own.gpa4().subtract(official).abs()));
        return s;
    }

    /** Dashboard card: GPA · credits · compulsory credits still missing. */
    public Map<String, Object> summary(Long userId) {
        Context ctx = load(userId);
        Map<String, Object> out = new LinkedHashMap<>(summaryOf(ctx.terms()));
        List<ProgramItem> items = AcademicEngine.programStatus(programCourses(ctx.link().getStudyProgramId()),
            ctx.terms(), Map.of());
        out.put("remainingCompulsoryCredits", items.stream()
            .filter(i -> i.course().compulsory() && i.status() != CourseStatus.PASSED)
            .mapToInt(i -> AcademicEngine.credits(i.course())).sum());
        out.put("dataUntil", dataUntil(ctx.terms()));
        return out;
    }

    // ------------------------------------------------------------ P2 program progress
    public Map<String, Object> program(Long userId) {
        Context ctx = load(userId);
        String programId = ctx.link().getStudyProgramId();
        List<ProgramCourse> courses = programCourses(programId);
        Map<Long, String> lmsNames = enrolledCourseNames(userId);
        List<ProgramItem> items = AcademicEngine.programStatus(courses, ctx.terms(), lmsByCode(userId, lmsNames));

        int compulsory = 0, compulsoryPassed = 0, electivePassed = 0;
        Map<String, Integer> counts = new LinkedHashMap<>();
        for (CourseStatus s : CourseStatus.values()) counts.put(s.name(), 0);
        Map<String, List<Map<String, Object>>> bySemester = new TreeMap<>(Comparator.comparingInt(PortalStudentText::semesterOrder));
        List<Map<String, Object>> eligible = new ArrayList<>(), blocked = new ArrayList<>();
        for (ProgramItem i : items) {
            ProgramCourse c = i.course();
            int cr = AcademicEngine.credits(c);
            if (c.compulsory()) {
                compulsory += cr;
                if (i.status() == CourseStatus.PASSED) compulsoryPassed += cr;
            } else if (i.status() == CourseStatus.PASSED) electivePassed += cr;
            counts.merge(i.status().name(), 1, Integer::sum);
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("code", c.code());
            m.put("name", c.name());
            m.put("credits", c.credits());
            m.put("compulsory", c.compulsory());
            m.put("status", i.status().name());
            m.put("score10", n2(i.score10()));
            m.put("letter", i.letter());
            m.put("lmsCourseId", i.lmsCourseId());
            m.put("lmsCourseName", i.lmsCourseId() == null ? null : lmsNames.get(i.lmsCourseId()));
            m.put("prerequisites", c.prerequisites());
            m.put("priorCourses", c.priorCourses());
            m.put("missing", i.missingPrerequisites());
            bySemester.computeIfAbsent(c.semester() == null ? "" : c.semester(), k -> new ArrayList<>()).add(m);
            if (i.status() == CourseStatus.NOT_TAKEN || i.status() == CourseStatus.FAILED) {
                Map<String, Object> e = new LinkedHashMap<>();
                e.put("code", c.code());
                e.put("name", c.name());
                e.put("credits", c.credits());
                e.put("semester", c.semester());
                e.put("compulsory", c.compulsory());
                e.put("retake", i.status() == CourseStatus.FAILED);
                if (i.missingPrerequisites().isEmpty()) eligible.add(e);
                else {
                    e.put("missing", i.missingPrerequisites());
                    blocked.add(e);
                }
            }
        }
        Map<String, Object> summary = new LinkedHashMap<>();
        summary.put("compulsoryCredits", compulsory);
        summary.put("compulsoryPassedCredits", compulsoryPassed);
        summary.put("electivePassedCredits", electivePassed);
        summary.put("electiveGroupsKnown", false);
        summary.put("completionPercent", compulsory == 0 ? null
            : BigDecimal.valueOf(compulsoryPassed * 100.0 / compulsory).setScale(1, RoundingMode.HALF_UP).doubleValue());
        summary.put("statusCounts", counts);
        summary.put("courseCount", items.size());

        List<Map<String, Object>> semesters = new ArrayList<>();
        bySemester.forEach((sem, list) -> semesters.add(Map.of("semester", sem, "courses", list)));
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("programId", programId);
        out.put("dataUntil", dataUntil(ctx.terms()));
        out.put("summary", summary);
        out.put("semesters", semesters);
        out.put("eligible", eligible);
        out.put("blocked", blocked);
        return out;
    }

    // ------------------------------------------------------------ P3 GPA simulation
    public Map<String, Object> gpaSimulation(Long userId) {
        Context ctx = load(userId);
        PortalProperties props = portal.properties();
        List<Grade> table = AcademicEngine.conversionTable(ctx.terms());
        Map<Long, String> lmsNames = enrolledCourseNames(userId);
        List<ProgramItem> items = AcademicEngine.programStatus(programCourses(ctx.link().getStudyProgramId()),
            ctx.terms(), lmsByCode(userId, lmsNames));
        Optional<Term> last = AcademicEngine.latestScoredTerm(ctx.terms());
        BigDecimal gpa = last.map(Term::cumulativeGpa4).orElse(null);
        int credits = AcademicEngine.recompute(ctx.terms()).credits();

        // Remaining: compulsory courses not yet passed, plus electives already being studied.
        List<Map<String, Object>> remaining = new ArrayList<>();
        int remainingCredits = 0, projectedCredits = 0, lmsCount = 0;
        BigDecimal projectedPoints = BigDecimal.ZERO;
        for (ProgramItem i : items) {
            boolean active = i.status() == CourseStatus.IN_LMS || i.status() == CourseStatus.IN_PROGRESS;
            if (i.status() == CourseStatus.PASSED || (!i.course().compulsory() && !active)) continue;
            int cr = AcademicEngine.credits(i.course());
            if (cr <= 0) continue;
            remainingCredits += cr;
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("code", i.course().code());
            m.put("name", i.course().name());
            m.put("credits", cr);
            m.put("status", i.status().name());
            m.put("lmsCourseId", i.lmsCourseId());
            m.put("lmsCourseName", i.lmsCourseId() == null ? null : lmsNames.get(i.lmsCourseId()));
            if (i.lmsCourseId() != null) {
                Double pct = lmsPercent(userId, i.lmsCourseId());
                if (pct != null) {
                    BigDecimal s10 = BigDecimal.valueOf(pct).divide(BigDecimal.TEN, 2, RoundingMode.HALF_UP);
                    Grade g = AcademicEngine.toGrade(s10, table);
                    m.put("forecastPercent", round1(pct));
                    m.put("forecastScore10", n2(s10));
                    m.put("forecastLetter", g.letter());
                    m.put("forecastScore4", n2(g.score4()));
                    projectedPoints = projectedPoints.add(g.score4().multiply(BigDecimal.valueOf(cr)));
                    projectedCredits += cr;
                    lmsCount++;
                }
            }
            remaining.add(m);
        }
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("dataUntil", dataUntil(ctx.terms()));
        out.put("gpa4", n2(gpa));
        out.put("credits", credits);
        out.put("remainingCredits", remainingCredits);
        out.put("bands", props.getGradeBands().stream().map(b -> Map.of("name", b.getName(), "min", n2(b.getMin()))).toList());
        out.put("conversion", table.stream().map(g -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("letter", g.letter());
            m.put("min10", n2(g.min10()));
            m.put("max10", n2(g.max10()));
            m.put("score4", n2(g.score4()));
            m.put("derived", g.derived());
            return m;
        }).toList());
        out.put("courses", remaining);
        out.put("targets", targetsJson(AcademicEngine.targets(gpa, credits, remainingCredits, props.getGradeBands())));
        if (lmsCount > 0) {
            BigDecimal base = (gpa == null ? BigDecimal.ZERO : gpa).multiply(BigDecimal.valueOf(credits));
            int total = credits + projectedCredits;
            BigDecimal projectedGpa = base.add(projectedPoints).divide(BigDecimal.valueOf(total), 4, RoundingMode.HALF_UP);
            Map<String, Object> p = new LinkedHashMap<>();
            p.put("lmsCourses", lmsCount);
            p.put("projectedGpa4", n2(projectedGpa));
            p.put("projectedBand", AcademicEngine.bandOf(projectedGpa, props.getGradeBands()));
            p.put("remainingCredits", remainingCredits - projectedCredits);
            p.put("targets", targetsJson(AcademicEngine.targets(projectedGpa, total, remainingCredits - projectedCredits,
                props.getGradeBands())));
            out.put("projection", p);
        } else {
            out.put("projection", null);
        }
        return out;
    }

    private Double lmsPercent(Long userId, Long lmsCourseId) {
        try {
            Object v = forecasts.studentForecast(userId, lmsCourseId).get("current");
            return v instanceof Number n ? n.doubleValue() : null;
        } catch (RuntimeException e) {
            return null;
        }
    }

    private static List<Map<String, Object>> targetsJson(List<Target> targets) {
        return targets.stream().map(t -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("band", t.band());
            m.put("min", n2(t.min()));
            m.put("needed", n2(t.needed()));
            m.put("status", t.status().name());
            return m;
        }).toList();
    }

    // ------------------------------------------------------------ P4 conduct
    public Map<String, Object> conduct(Long userId) {
        Context ctx = load(userId);
        String me = ctx.link().getStudentId();
        TreeSet<String> years = new TreeSet<>();
        for (Term t : ctx.terms()) if (t.yearStudy() != null) years.add(t.yearStudy());
        List<Map<String, Object>> rows = new ArrayList<>();
        int calls = 0;
        outer:
        for (String y : years) {
            for (String term : REGULAR_TERMS) {
                if (calls++ >= MAX_CONDUCT_TERMS) break outer;
                for (Conduct c : PortalParser.conduct(portal.classConduct(y, term, ctx.link().getClassId()))) {
                    if (!me.equalsIgnoreCase(c.studentId()) || c.finalScore() == null) continue;
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("yearStudy", y);
                    m.put("termId", term);
                    m.put("selfScore", n2(c.selfScore()));
                    m.put("classScore", n2(c.classScore()));
                    m.put("departmentScore", n2(c.departmentScore()));
                    m.put("finalScore", n2(c.finalScore()));
                    m.put("classification", PortalStudentText.conductRank(c.finalScore()));
                    rows.add(m);
                }
            }
        }
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("terms", rows);
        out.put("average", rows.isEmpty() ? null : round1(rows.stream()
            .mapToDouble(r -> ((Number) r.get("finalScore")).doubleValue()).average().orElse(0)));
        return out;
    }

    // ------------------------------------------------------------ P5 decisions
    public Map<String, Object> decisions(Long userId) {
        PortalProperties.StudentLink link = identity.student(userId);
        List<Map<String, Object>> list = new ArrayList<>();
        int warnings = 0;
        for (Decision d : PortalParser.decisions(portal.decisions(link.getStudentId()))) {
            boolean warning = PortalStudentText.isAcademicWarning(d);
            if (warning) warnings++;
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("name", d.name());
            m.put("typeId", d.typeId());
            m.put("signDate", d.signDate() == null ? null : d.signDate().toString());
            m.put("yearStudy", d.yearStudy());
            m.put("termId", d.termId());
            m.put("fullText", d.fullText());
            m.put("academicWarning", warning);
            list.add(m);
        }
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("decisions", list);
        out.put("warningCount", warnings);
        return out;
    }

    // ------------------------------------------------------------ helpers
    static Double n2(BigDecimal v) {
        return v == null ? null : v.setScale(2, RoundingMode.HALF_UP).doubleValue();
    }

    static Double round1(double v) {
        return Math.round(v * 10.0) / 10.0;
    }
}
