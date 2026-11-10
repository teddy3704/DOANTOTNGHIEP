package com.dlu.lmsmobile.portal;

import com.dlu.lmsmobile.portal.PortalModels.*;
import com.fasterxml.jackson.databind.JsonNode;

import java.math.BigDecimal;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static com.dlu.lmsmobile.portal.PortalValues.*;

/** Allow-list parsing of Portal bodies into {@link PortalModels}. Unknown fields are ignored. */
public final class PortalParser {
    private static final Pattern SEMESTER_NO = Pattern.compile("(\\d+)");
    private static final Pattern CODE_SPLIT = Pattern.compile("[,;\\s]+");

    private PortalParser() {
    }

    private static Iterable<JsonNode> rows(JsonNode n) {
        return n != null && n.isArray() ? n : List.of();
    }

    /** "x"/"True"/"1"/true → true; anything else false. */
    static boolean flag(JsonNode row, String field) {
        String s = text(row, field);
        if (s == null) return false;
        Boolean b = bool(row, field);
        return b != null ? b : "x".equalsIgnoreCase(s);
    }

    // ------------------------------------------------------------ transcript
    public static List<Term> transcript(JsonNode body) {
        List<Term> terms = new ArrayList<>();
        for (JsonNode year : rows(body)) {
            String yearName = text(year, "NamHoc");
            for (JsonNode term : rows(year.get("DanhSachDiem"))) {
                List<CourseResult> courses = new ArrayList<>();
                JsonNode first = null;
                for (JsonNode r : rows(term.get("DanhSachDiemHK"))) {
                    if (first == null) first = r;
                    courses.add(new CourseResult(
                        text(r, "CurriculumID"), text(r, "CurriculumName"), integer(r, "Credits"),
                        decimal(r, "DiemTK_10"), decimal(r, "DiemTK_4"), text(r, "DiemTK_Chu"),
                        flag(r, "IsPass"), flag(r, "IsGather"), flag(r, "NotComputeAverageScore"),
                        Optional.ofNullable(text(r, "YearStudy")).orElse(yearName),
                        Optional.ofNullable(text(r, "TermID")).orElse(text(term, "HocKy"))));
                }
                // The Portal repeats the term aggregates on every course row; take the first row's.
                terms.add(new Term(yearName, Optional.ofNullable(text(term, "HocKy")).orElse(text(first, "TermID")),
                    courses, decimal(first, "TB_HK_4"), decimal(first, "TB_HK_10"), decimal(first, "TB_TL_HK_4"),
                    decimal(first, "TB_TL_HK_10"), decimal(first, "Dat_HK"), decimal(first, "Dat_TL_HK"),
                    text(first, "TenXepLoai")));
            }
        }
        terms.sort(Comparator.comparing(Term::yearStudy, Comparator.nullsFirst(String::compareTo))
            .thenComparing(Term::termId, Comparator.nullsFirst(String::compareTo)));
        return terms;
    }

    // ------------------------------------------------------------ study program
    public static List<ProgramCourse> program(JsonNode body) {
        List<ProgramCourse> out = new ArrayList<>();
        JsonNode list = body == null ? null : body.get("tbStudyPrograms");
        for (JsonNode r : rows(list)) {
            String semester = text(r, "HocKy");
            Integer no = null;
            if (semester != null) {
                Matcher m = SEMESTER_NO.matcher(semester);
                if (m.find()) no = Integer.valueOf(m.group(1));
            }
            out.add(new ProgramCourse(text(r, "MaHP"), text(r, "TenHP"), integer(r, "STC"), integer(r, "LT"),
                integer(r, "TH"), semester, no, compulsory(text(r, "BatBuoc")), codes(text(r, "HPTienQuyet")),
                codes(text(r, "HPHocTruoc")), text(r, "MaCTDT")));
        }
        return out;
    }

    /** True for "Bắt Buộc", "x", "1", "true"; false for "Tự Chọn" and empty. */
    static boolean compulsory(String v) {
        if (v == null) return false;
        String s = v.trim().toLowerCase(Locale.ROOT);
        return s.startsWith("bắt") || s.startsWith("bat") || s.equals("x") || s.equals("1") || s.equals("true");
    }

    /** "A, B;C" → [A, B, C]; empty → []. */
    public static List<String> codes(String v) {
        if (v == null || v.isBlank()) return List.of();
        return Arrays.stream(CODE_SPLIT.split(v.trim())).filter(s -> !s.isBlank())
            .map(s -> s.toUpperCase(Locale.ROOT)).distinct().toList();
    }

    /** True when groupSelection/groupSelection2 carry anything (structure still unknown). */
    public static boolean hasElectiveGroups(JsonNode body) {
        if (body == null) return false;
        for (String f : List.of("groupSelection", "groupSelection2")) {
            JsonNode g = body.get(f);
            if (g != null && !g.isNull() && g.size() > 0) return true;
        }
        return false;
    }

    // ------------------------------------------------------------ class lists
    public static List<ClassGrade> classGrades(JsonNode body) {
        List<ClassGrade> out = new ArrayList<>();
        for (JsonNode r : rows(body)) {
            out.add(new ClassGrade(text(r, "StudentID"), text(r, "HoLot"), text(r, "FirstName"), decimal(r, "STC"),
                decimal(r, "AverageScore"), decimal(r, "AverageScore4"), decimal(r, "AverageGatherScore"),
                decimal(r, "AverageGatherScore4"), text(r, "Ranks"), decimal(r, "BehaviorScore"),
                text(r, "BehaviorScoreRank")));
        }
        return out;
    }

    public static List<Conduct> conduct(JsonNode body) {
        List<Conduct> out = new ArrayList<>();
        JsonNode list = body == null ? null : body.get("resultDanhSach");
        for (JsonNode r : rows(list)) {
            out.add(new Conduct(text(r, "StudentID"), decimal(r, "StudentScore"), decimal(r, "ClassScore"),
                decimal(r, "DepartmentScore"), decimal(r, "LastScore"), text(r, "StatusID")));
        }
        return out;
    }

    public static List<ClassMember> classMembers(JsonNode body) {
        List<ClassMember> out = new ArrayList<>();
        for (JsonNode r : rows(body)) {
            Boolean in = bool(r, "IsInClass");
            out.add(new ClassMember(text(r, "StudentID"), text(r, "StudentNameWithoutID"), text(r, "ClassStudentID"),
                text(r, "StudyProgramID"), in == null || in, text(r, "ClassRoleID")));
        }
        return out;
    }

    public static List<Decision> decisions(JsonNode body) {
        List<Decision> out = new ArrayList<>();
        for (JsonNode r : rows(body)) {
            out.add(new Decision(text(r, "DecisionName"), integer(r, "DecisionTypeID"), text(r, "FullText"),
                date(r, "SignDate"), text(r, "YearStudy"), text(r, "TermID")));
        }
        out.sort(Comparator.comparing(Decision::signDate, Comparator.nullsLast(Comparator.reverseOrder())));
        return out;
    }

    /** Display name from HoLot + FirstName. */
    public static String fullName(ClassGrade g) {
        String s = ((g.lastName() == null ? "" : g.lastName()) + " " + (g.firstName() == null ? "" : g.firstName())).trim();
        return s.isEmpty() ? null : s;
    }

    static BigDecimal nz(BigDecimal v) {
        return v == null ? BigDecimal.ZERO : v;
    }
}
