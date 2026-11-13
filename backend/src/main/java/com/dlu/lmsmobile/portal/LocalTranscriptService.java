package com.dlu.lmsmobile.portal;

import com.dlu.lmsmobile.config.DataProfile;
import com.dlu.lmsmobile.portal.AcademicEngine.Grade;
import com.dlu.lmsmobile.portal.PortalModels.CourseResult;
import com.dlu.lmsmobile.portal.PortalModels.Term;
import com.dlu.lmsmobile.repository.StudentRepository;
import com.dlu.lmsmobile.service.GradeForecastService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.text.Normalizer;
import java.util.*;

/**
 * REAL-DATA-2: the student's own transcript, copied by the student from the School's training
 * Portal into {@code <dir>/<MSSV>_bangdiem.csv} (UTF-8, header
 * {@code hoc_ky,ma_hp,ten_hp,so_tc,diem_10,diem_4,diem_chu,tinh_gpa}). Read-only, only on the real
 * profile, directory from {@code app.real-transcript.dir} (env REAL_TRANSCRIPT_DIR), outside the
 * repository. Replaces the simulated Portal API, which is switched off on real. Courses still being
 * studied (no score) are matched to the student's real LMS courses by name, or by
 * {@code <MSSV>_anhxa.csv} ({@code ma_hp,lms_course_id}) in the same directory, so the projected GPA
 * uses the real current LMS percentage. No program (CTĐT), conduct or decisions: empty states.
 */
@Service
public class LocalTranscriptService {
    public static final String SOURCE = "Bảng điểm: sinh viên nhập từ Portal đào tạo";
    static final List<String> COLUMNS = List.of("hoc_ky", "ma_hp", "ten_hp", "so_tc", "diem_10", "diem_4", "diem_chu", "tinh_gpa");

    private final boolean active;
    private final Path dir;
    private final JdbcTemplate jdbc;
    private final StudentRepository students;
    private final GradeForecastService forecasts;
    private final PortalProperties props;

    @Autowired
    public LocalTranscriptService(DataProfile profile, @Value("${app.real-transcript.dir:}") String dir, JdbcTemplate jdbc,
                                  StudentRepository students, GradeForecastService forecasts, PortalProperties props) {
        this.active = profile.handInsOnly();
        this.dir = dir == null || dir.isBlank() ? null : Path.of(dir.trim());
        this.jdbc = jdbc;
        this.students = students;
        this.forecasts = forecasts;
        this.props = props;
    }

    /** True on the real profile: Portal screens are served from the local file (or an empty state). */
    public boolean active() { return active; }

    // ------------------------------------------------------------------ parsing (pure)

    /**
     * A row without a score yet (course being studied) that counts for the GPA. {@code previousScore4}
     * is set when the same course code was already PASSED: a grade-improvement retake, which only
     * replaces the old score if higher and adds no credits.
     */
    public record InProgress(String code, String name, int credits, String term,
                             BigDecimal previousScore4, BigDecimal previousScore10) {
        public InProgress(String code, String name, int credits, String term) {
            this(code, name, credits, term, null, null);
        }

        public boolean improvement() { return previousScore4 != null; }
    }

    /** Cumulative figures with the Portal rule (passed courses only, best attempt per code). */
    public record Cumulative(BigDecimal gpa4, BigDecimal gpa10, int credits) {
    }

    public record Parsed(List<Term> terms, List<InProgress> inProgress, Cumulative cumulative) {
    }

    /** Thrown for a file that cannot be read as the agreed format; the message is shown as is. */
    public static class FormatException extends RuntimeException {
        public FormatException(String message) { super(message); }
    }

    private static final java.util.regex.Pattern TERM =
        java.util.regex.Pattern.compile("(?i)\\s*HK\\s*(\\d)\\s+(\\d{4}\\s*-\\s*\\d{4})\\s*");

    /**
     * Rules checked against the School's Portal on the owner's transcript (README_bangdiem.txt):
     * term average = every GPA row of the term, absent-from-exam (VT) counted as 0, weighted by credits;
     * cumulative average and credits = passed courses only (score4 > 0), GPA rows only, and for a course
     * code taken several times the attempt with the highest score4.
     */
    public static Parsed parse(List<String> lines) {
        List<List<String>> rows = new ArrayList<>();
        for (String raw : lines) {
            String line = raw.replace("﻿", "");
            if (line.isBlank() || line.replace(",", "").isBlank()) continue;   // blank line or ",,,,"
            rows.add(splitCsv(line));
        }
        if (rows.isEmpty()) return new Parsed(List.of(), List.of(), new Cumulative(null, null, 0));
        List<String> header = rows.get(0).stream().map(h -> h.trim().toLowerCase(Locale.ROOT)).toList();
        List<String> missing = COLUMNS.stream().filter(c -> !header.contains(c)).toList();
        if (!missing.isEmpty()) throw new FormatException("Bảng điểm thiếu cột: " + String.join(", ", missing));
        Map<String, Integer> at = new HashMap<>();
        for (String c : COLUMNS) at.put(c, header.indexOf(c));

        // key "yyyy-yyyy|HKn" keeps terms in chronological order whatever the file order is.
        TreeMap<String, List<CourseResult>> byTerm = new TreeMap<>();
        List<CourseResult> all = new ArrayList<>();
        for (int r = 1; r < rows.size(); r++) {
            List<String> row = rows.get(r);
            String term = cell(row, at.get("hoc_ky"));
            String code = cell(row, at.get("ma_hp"));
            String name = cell(row, at.get("ten_hp"));
            if (term == null && code == null && name == null) continue;
            if (term == null) throw new FormatException("Dòng " + (r + 1) + ": thiếu hoc_ky");
            Integer credits = integer(cell(row, at.get("so_tc")), r);
            BigDecimal s10 = decimal(cell(row, at.get("diem_10")), r);
            BigDecimal s4 = decimal(cell(row, at.get("diem_4")), r);
            String letter = cell(row, at.get("diem_chu"));
            String gpaFlag = cell(row, at.get("tinh_gpa"));
            boolean counts = gpaFlag == null || !"0".equals(gpaFlag.trim());
            String id = code != null ? code.toUpperCase(Locale.ROOT) : name;
            java.util.regex.Matcher m = TERM.matcher(term);
            boolean std = m.matches();
            String year = std ? m.group(2).replace(" ", "") : term;
            String termId = std ? "HK" + m.group(1) : term;
            CourseResult c = new CourseResult(id, name, credits, s10, s4, letter,
                s4 != null ? s4.signum() > 0 : letter != null && !letter.trim().equalsIgnoreCase("F"),
                counts, false, year, termId);
            byTerm.computeIfAbsent(year + "|" + termId, k -> new ArrayList<>()).add(c);
            all.add(c);
        }

        List<Term> terms = new ArrayList<>();
        List<CourseResult> soFar = new ArrayList<>();
        for (List<CourseResult> courses : byTerm.values()) {
            soFar.addAll(courses);
            List<CourseResult> graded = courses.stream()
                .filter(c -> c.gather() && c.score4() != null && c.credits() != null && c.credits() > 0).toList();
            boolean scored = !graded.isEmpty();
            Cumulative cum = cumulative(soFar);
            CourseResult first = courses.get(0);
            terms.add(new Term(first.yearStudy(), first.termId(), courses,
                scored ? weighted(graded, CourseResult::score4) : null,
                scored ? weighted(graded, CourseResult::score10) : null,
                scored ? cum.gpa4() : null, scored ? cum.gpa10() : null,
                scored ? BigDecimal.valueOf(graded.stream().mapToInt(CourseResult::credits).sum()) : null,
                scored ? BigDecimal.valueOf(cum.credits()) : null, null));
        }

        Map<String, CourseResult> best = bestPassed(all);
        List<InProgress> inProgress = new ArrayList<>();
        for (CourseResult c : all) {
            if (c.scored() || !c.gather() || c.credits() == null || c.credits() <= 0) continue;
            CourseResult old = best.get(c.courseId());
            inProgress.add(new InProgress(c.courseId(), c.name(), c.credits(), c.termId() + " " + c.yearStudy(),
                old == null ? null : old.score4(), old == null ? null : old.score10()));
        }
        return new Parsed(terms, inProgress, cumulative(all));
    }

    /** Best passed attempt (highest score4 > 0; a later equal attempt wins) of every GPA course code. */
    static Map<String, CourseResult> bestPassed(List<CourseResult> courses) {
        Map<String, CourseResult> best = new LinkedHashMap<>();
        for (CourseResult c : courses) {
            if (!c.gather() || c.score4() == null || c.score4().signum() <= 0 || c.credits() == null || c.credits() <= 0) continue;
            CourseResult b = best.get(c.courseId());
            if (b == null || c.score4().compareTo(b.score4()) >= 0) best.put(c.courseId(), c);
        }
        return best;
    }

    static Cumulative cumulative(List<CourseResult> courses) {
        List<CourseResult> best = new ArrayList<>(bestPassed(courses).values());
        int credits = best.stream().mapToInt(CourseResult::credits).sum();
        if (credits == 0) return new Cumulative(null, null, 0);
        return new Cumulative(weighted(best, CourseResult::score4),
            best.stream().allMatch(c -> c.score10() != null) ? weighted(best, CourseResult::score10) : null, credits);
    }

    private static BigDecimal weighted(List<CourseResult> courses, java.util.function.Function<CourseResult, BigDecimal> score) {
        BigDecimal points = BigDecimal.ZERO;
        int credits = 0;
        for (CourseResult c : courses) {
            BigDecimal v = score.apply(c);
            if (v == null) continue;
            points = points.add(v.multiply(BigDecimal.valueOf(c.credits())));
            credits += c.credits();
        }
        return credits == 0 ? null : points.divide(BigDecimal.valueOf(credits), 4, RoundingMode.HALF_UP);
    }

    static List<String> splitCsv(String line) {
        List<String> out = new ArrayList<>();
        StringBuilder cur = new StringBuilder();
        boolean quoted = false;
        for (int i = 0; i < line.length(); i++) {
            char ch = line.charAt(i);
            if (quoted) {
                if (ch == '"' && i + 1 < line.length() && line.charAt(i + 1) == '"') { cur.append('"'); i++; }
                else if (ch == '"') quoted = false;
                else cur.append(ch);
            } else if (ch == '"') quoted = true;
            else if (ch == ',') { out.add(cur.toString()); cur.setLength(0); }
            else cur.append(ch);
        }
        out.add(cur.toString());
        return out;
    }

    private static String cell(List<String> row, int i) {
        if (i >= row.size()) return null;
        String v = row.get(i).trim();
        return v.isEmpty() ? null : v;
    }

    private static Integer integer(String v, int r) {
        if (v == null) return null;
        try { return new BigDecimal(v.replace(',', '.')).intValueExact(); }
        catch (ArithmeticException | NumberFormatException e) { throw new FormatException("Dòng " + (r + 1) + ": so_tc không phải số nguyên"); }
    }

    private static BigDecimal decimal(String v, int r) {
        if (v == null) return null;
        try { return new BigDecimal(v.replace(',', '.')); }
        catch (NumberFormatException e) { throw new FormatException("Dòng " + (r + 1) + ": điểm không phải số"); }
    }

    /** Lower case, no diacritics, đ→d, only letters/digits/spaces: "Lập trình Python" ~ "lap trinh python". */
    public static String normalize(String s) {
        if (s == null) return "";
        String n = Normalizer.normalize(s.toLowerCase(Locale.ROOT).replace('đ', 'd'), Normalizer.Form.NFD)
            .replaceAll("\\p{M}", "");
        return n.replaceAll("[^a-z0-9 ]", " ").replaceAll("\\s+", " ").trim();
    }

    /**
     * LMS course for a course in progress: the manual map first, else the enrolled course whose
     * normalised name starts with or contains the normalised course name (longest name wins).
     */
    public static Long matchLms(InProgress c, Map<Long, String> lmsNames, Map<String, Long> manual) {
        return matchLms(c, lmsNames, manual, Map.of());
    }

    /**
     * Same, preferring the most recent course when several match (a retake is studied in the
     * current-term course, not the old one). "(Thực hành)" and other parenthesised parts of the
     * Portal name are ignored.
     */
    public static Long matchLms(InProgress c, Map<Long, String> lmsNames, Map<String, Long> manual,
                                Map<Long, Long> startByCourse) {
        Long m = manual.get(c.code());
        if (m != null && lmsNames.containsKey(m)) return m;
        String want = normalize(c.name() == null ? null : c.name().replaceAll("\\([^)]*\\)", " "));
        if (want.isEmpty()) return null;
        Long best = null;
        long bestStart = Long.MIN_VALUE;
        int bestLen = -1;
        for (Map.Entry<Long, String> e : lmsNames.entrySet()) {
            String have = normalize(e.getValue());
            if (!(have.startsWith(want) || have.contains(" " + want) || have.equals(want))) continue;
            long start = startByCourse.getOrDefault(e.getKey(), 0L);
            if (start > bestStart || (start == bestStart && have.length() > bestLen)) {
                best = e.getKey();
                bestStart = start;
                bestLen = have.length();
            }
        }
        return best;
    }

    // ------------------------------------------------------------------ loading

    private String studentCode(Long userId) {
        List<String> codes = jdbc.queryForList("SELECT idnumber FROM lms.\"user\" WHERE id = ?", String.class, userId);
        return codes.isEmpty() || codes.get(0) == null || !codes.get(0).matches("\\d{7}") ? null : codes.get(0);
    }

    /** Empty when there is no file for this student: the caller answers with the "no data" state. */
    private Optional<Parsed> load(Long userId) {
        if (!active || dir == null) return Optional.empty();
        String code = studentCode(userId);
        if (code == null) return Optional.empty();
        Path file = dir.resolve(code + "_bangdiem.csv");
        if (!Files.isRegularFile(file)) return Optional.empty();
        try {
            Parsed p = parse(Files.readAllLines(file, StandardCharsets.UTF_8));
            return p.terms().isEmpty() ? Optional.empty() : Optional.of(p);
        } catch (IOException e) {
            throw new FormatException("Không đọc được tệp bảng điểm");
        }
    }

    private Map<String, Long> manualMap(Long userId) {
        String code = studentCode(userId);
        Path file = dir == null || code == null ? null : dir.resolve(code + "_anhxa.csv");
        Map<String, Long> out = new HashMap<>();
        if (file == null || !Files.isRegularFile(file)) return out;
        try {
            for (String line : Files.readAllLines(file, StandardCharsets.UTF_8)) {
                List<String> r = splitCsv(line.replace("﻿", ""));
                if (r.size() < 2) continue;
                try { out.put(r.get(0).trim().toUpperCase(Locale.ROOT), Long.parseLong(r.get(1).trim())); }
                catch (NumberFormatException ignored) { /* header or bad line */ }
            }
        } catch (IOException ignored) {
            // no manual map
        }
        return out;
    }

    private Parsed required(Long userId) {
        return load(userId).orElseThrow(PortalNotLinkedException::new);
    }

    // ------------------------------------------------------------------ endpoints (same shapes)

    public Map<String, Object> summary(Long userId) {
        Parsed p = required(userId);
        Map<String, Object> out = new LinkedHashMap<>(summaryOf(p.cumulative()));
        out.put("remainingCompulsoryCredits", null);   // no program (CTĐT) data
        out.put("dataUntil", dataUntil(p.terms()));
        out.put("source", SOURCE);
        return out;
    }

    private Map<String, Object> summaryOf(Cumulative cum) {
        Map<String, Object> s = new LinkedHashMap<>();
        s.put("cumulativeGpa4", n2(cum.gpa4()));
        s.put("cumulativeGpa10", n2(cum.gpa10()));
        s.put("cumulativeCredits", cum.credits());
        s.put("rank", null);
        s.put("band", AcademicEngine.bandOf(cum.gpa4(), props.getGradeBands()));
        s.put("recomputedGpa4", n2(cum.gpa4()));
        s.put("recomputedCredits", cum.credits());
        s.put("gpaDifference", null);
        return s;
    }

    private static Map<String, Object> dataUntil(List<Term> terms) {
        return AcademicEngine.latestScoredTerm(terms)
            .map(t -> Map.<String, Object>of("yearStudy", t.yearStudy(), "termId", t.termId())).orElse(null);
    }

    public Map<String, Object> transcript(Long userId) {
        Parsed p = required(userId);
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("dataUntil", dataUntil(p.terms()));
        out.put("summary", summaryOf(p.cumulative()));
        out.put("source", SOURCE);
        List<Map<String, Object>> terms = new ArrayList<>();
        for (Term t : p.terms()) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("yearStudy", t.yearStudy());
            m.put("termId", t.termId());
            m.put("gpa4", n2(t.gpa4()));
            m.put("gpa10", n2(t.gpa10()));
            m.put("cumulativeGpa4", n2(t.cumulativeGpa4()));
            m.put("cumulativeGpa10", n2(t.cumulativeGpa10()));
            m.put("termCredits", n2(t.termCredits()));
            m.put("cumulativeCredits", n2(t.cumulativeCredits()));
            m.put("rank", null);
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

    /** Letter rows only (A..F, with +); VT and other marks never enter the conversion table. */
    static List<Term> lettersOnly(List<Term> terms) {
        List<Term> out = new ArrayList<>();
        for (Term t : terms) {
            List<CourseResult> keep = t.courses().stream()
                .filter(c -> c.letter() != null && c.letter().trim().toUpperCase(Locale.ROOT).matches("[A-F]\\+?")).toList();
            out.add(new Term(t.yearStudy(), t.termId(), keep, null, null, null, null, null, null, null));
        }
        return out;
    }

    /**
     * Projected cumulative GPA: new courses add their credits; a grade-improvement retake replaces
     * the old score only when higher and adds no credits (README_bangdiem.txt).
     */
    public static BigDecimal project(Cumulative cum, List<InProgress> courses, Map<String, BigDecimal> score4ByCode) {
        BigDecimal points = (cum.gpa4() == null ? BigDecimal.ZERO : cum.gpa4()).multiply(BigDecimal.valueOf(cum.credits()));
        int credits = cum.credits();
        for (InProgress c : courses) {
            BigDecimal s4 = score4ByCode.get(c.code());
            if (s4 == null) continue;
            if (c.improvement()) {
                if (s4.compareTo(c.previousScore4()) > 0) {
                    points = points.add(s4.subtract(c.previousScore4()).multiply(BigDecimal.valueOf(c.credits())));
                }
            } else if (s4.signum() > 0) {
                points = points.add(s4.multiply(BigDecimal.valueOf(c.credits())));
                credits += c.credits();
            }
        }
        return credits == 0 ? null : points.divide(BigDecimal.valueOf(credits), 4, RoundingMode.HALF_UP);
    }

    /**
     * GPA simulation over the courses being studied (listed in the file without a score). Without
     * the program (CTĐT) the remaining credits are only these new courses; the app says so.
     */
    public Map<String, Object> gpaSimulation(Long userId) {
        Parsed p = required(userId);
        List<Grade> table = AcademicEngine.conversionTable(lettersOnly(p.terms()));
        Cumulative cum = p.cumulative();
        BigDecimal gpa = cum.gpa4();
        int credits = cum.credits();
        Map<Long, String> lmsNames = new LinkedHashMap<>();
        Map<Long, Long> starts = new HashMap<>();
        for (Map<String, Object> c : students.findCoursesByUserId(userId)) {
            if (c.get("courseid") instanceof Number n) {
                lmsNames.put(n.longValue(), Objects.toString(c.get("course_name"), null));
                if (c.get("startdate") instanceof Number sd) starts.put(n.longValue(), sd.longValue());
            }
        }
        Map<String, Long> manual = manualMap(userId);

        List<Map<String, Object>> remaining = new ArrayList<>();
        Map<String, BigDecimal> forecast4 = new HashMap<>();
        int remainingCredits = 0, forecastNewCredits = 0, lmsCount = 0;
        for (InProgress c : p.inProgress()) {
            if (!c.improvement()) remainingCredits += c.credits();
            Long lms = matchLms(c, lmsNames, manual, starts);
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("code", c.code());
            m.put("name", c.name());
            m.put("credits", c.credits());
            m.put("status", lms == null ? "IN_PROGRESS" : "IN_LMS");
            m.put("lmsCourseId", lms);
            m.put("lmsCourseName", lms == null ? null : lmsNames.get(lms));
            m.put("improvement", c.improvement());
            m.put("previousScore4", n2(c.previousScore4()));
            m.put("previousScore10", n2(c.previousScore10()));
            if (lms != null) {
                Double pct = lmsPercent(userId, lms);
                if (pct != null) {
                    BigDecimal s10 = BigDecimal.valueOf(pct).divide(BigDecimal.TEN, 2, RoundingMode.HALF_UP);
                    Grade g = AcademicEngine.toGrade(s10, table);
                    m.put("forecastPercent", Math.round(pct * 10.0) / 10.0);
                    m.put("forecastScore10", n2(s10));
                    m.put("forecastLetter", g.letter());
                    m.put("forecastScore4", n2(g.score4()));
                    forecast4.put(c.code(), g.score4());
                    if (!c.improvement()) forecastNewCredits += c.credits();
                    lmsCount++;
                }
            }
            remaining.add(m);
        }
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("source", SOURCE);
        out.put("remainingScope", "IN_PROGRESS_ONLY");
        out.put("dataUntil", dataUntil(p.terms()));
        // Unrounded (4 decimals) so the app's targets match the exact need; the app shows 2 decimals.
        out.put("gpa4", gpa);
        out.put("gpa10", n2(cum.gpa10()));
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
            BigDecimal projectedGpa = project(cum, p.inProgress(), forecast4);
            int total = credits + forecastNewCredits;
            Map<String, Object> pr = new LinkedHashMap<>();
            pr.put("lmsCourses", lmsCount);
            pr.put("projectedGpa4", n2(projectedGpa));
            pr.put("projectedBand", AcademicEngine.bandOf(projectedGpa, props.getGradeBands()));
            pr.put("remainingCredits", remainingCredits - forecastNewCredits);
            pr.put("targets", targetsJson(AcademicEngine.targets(projectedGpa, total, remainingCredits - forecastNewCredits,
                props.getGradeBands())));
            out.put("projection", pr);
        } else {
            out.put("projection", null);
        }
        return out;
    }

    /**
     * Conduct (điểm rèn luyện) from {@code <MSSV>_renluyen.csv} ({@code hoc_ky,diem_ren_luyen}), copied by
     * the student from the Portal. Only the final score is known; self/class/department scores stay null.
     */
    public Map<String, Object> conduct(Long userId) {
        if (!active || dir == null) throw new PortalNotLinkedException();
        String code = studentCode(userId);
        Path file = code == null ? null : dir.resolve(code + "_renluyen.csv");
        if (file == null || !Files.isRegularFile(file)) throw new PortalNotLinkedException();
        List<String> lines;
        try {
            lines = Files.readAllLines(file, StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new FormatException("Không đọc được tệp điểm rèn luyện");
        }
        Map<String, Object> out = conductOf(lines);
        if (((List<?>) out.get("terms")).isEmpty()) throw new PortalNotLinkedException();
        return out;
    }

    public static Map<String, Object> conductOf(List<String> lines) {
        TreeMap<String, Map<String, Object>> rows = new TreeMap<>();
        boolean header = true;
        for (String raw : lines) {
            String line = raw.replace("﻿", "").trim();
            if (line.isEmpty()) continue;
            List<String> r = splitCsv(line);
            if (header) {
                header = false;
                if (r.size() < 2 || !r.get(0).trim().equalsIgnoreCase("hoc_ky")
                        || !r.get(1).trim().equalsIgnoreCase("diem_ren_luyen")) {
                    throw new FormatException("Tệp rèn luyện cần cột: hoc_ky, diem_ren_luyen");
                }
                continue;
            }
            if (r.size() < 2 || r.get(1).isBlank()) continue;
            java.util.regex.Matcher m = TERM.matcher(r.get(0));
            String year = m.matches() ? m.group(2).replace(" ", "") : r.get(0).trim();
            String termId = m.matches() ? "HK" + m.group(1) : r.get(0).trim();
            BigDecimal score;
            try { score = new BigDecimal(r.get(1).trim().replace(',', '.')); }
            catch (NumberFormatException e) { throw new FormatException("Điểm rèn luyện không phải số: " + r.get(0)); }
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("yearStudy", year);
            row.put("termId", termId);
            row.put("selfScore", null);
            row.put("classScore", null);
            row.put("departmentScore", null);
            row.put("finalScore", n2(score));
            row.put("classification", PortalStudentText.conductRank(score));
            rows.put(year + "|" + termId, row);
        }
        List<Map<String, Object>> list = new ArrayList<>(rows.values());
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("terms", list);
        out.put("average", list.isEmpty() ? null : Math.round(list.stream()
            .mapToDouble(x -> ((BigDecimal) x.get("finalScore")).doubleValue()).average().orElse(0) * 10.0) / 10.0);
        out.put("source", "Điểm rèn luyện: sinh viên nhập từ Portal đào tạo");
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

    private static List<Map<String, Object>> targetsJson(List<AcademicEngine.Target> targets) {
        return targets.stream().map(t -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("band", t.band());
            m.put("min", n2(t.min()));
            m.put("needed", n2(t.needed()));
            m.put("status", t.status().name());
            return m;
        }).toList();
    }

    private static BigDecimal n2(BigDecimal v) {
        return v == null ? null : v.setScale(2, RoundingMode.HALF_UP);
    }
}
