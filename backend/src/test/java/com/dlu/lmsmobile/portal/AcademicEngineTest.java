package com.dlu.lmsmobile.portal;

import com.dlu.lmsmobile.portal.AcademicEngine.*;
import com.dlu.lmsmobile.portal.PortalModels.*;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/** V3 pure engines on invented fixtures (expected values computed by hand). */
class AcademicEngineTest {
    static final List<Term> TERMS = PortalParser.transcript(PortalFixtures.transcript());
    static final List<PortalProperties.GradeBand> BANDS = new PortalProperties().getGradeBands();

    @Test
    void parsesTermsWithPortalAggregates() {
        assertEquals(4, TERMS.size());
        Term last = AcademicEngine.latestScoredTerm(TERMS).orElseThrow();
        assertEquals("2099-2100", last.yearStudy());
        assertEquals("HK01", last.termId());
        assertEquals(new BigDecimal("3.19"), last.cumulativeGpa4());
        assertFalse(TERMS.get(3).hasScores()); // in-progress term: registered, no scores yet
        CourseResult pe = TERMS.get(0).courses().get(2);
        assertTrue(pe.notComputed());
        assertFalse(pe.countsForGpa());
    }

    @Test
    void recomputedGpaMatchesPortalWithinRounding() {
        Gpa g = AcademicEngine.recompute(TERMS);
        assertEquals(16, g.credits()); // retake of TIN1004 replaces the F; PE is not computed
        assertEquals(new BigDecimal("3.1875"), g.gpa4());
        assertTrue(g.gpa4().subtract(new BigDecimal("3.19")).abs().compareTo(new BigDecimal("0.005")) < 0);
    }

    @Test
    void conversionTableIsDerivedFromTranscriptWithDefaultsForUnseenLetters() {
        List<Grade> table = AcademicEngine.conversionTable(TERMS);
        assertEquals(List.of("A", "B", "C", "D", "F"), table.stream().map(Grade::letter).toList());
        Grade a = table.get(0);
        assertTrue(a.derived());
        assertEquals(new BigDecimal("8.6"), a.min10());
        assertEquals(new BigDecimal("9.0"), a.max10());
        Grade b = table.get(1);
        assertEquals(new BigDecimal("7.0"), b.min10());
        assertEquals(new BigDecimal("7.5"), b.max10());
        assertFalse(table.get(3).derived()); // D never seen → default row
        assertTrue(table.get(4).derived());  // F seen once (3.5)
    }

    @ParameterizedTest
    @CsvSource({"9.5, A", "8.6, A", "8.5, B", "7.0, B", "6.9, C", "6.0, C", "5.9, D", "4.0, D", "3.9, F", "0, F"})
    void toGradeUsesLowerBounds(String score, String letter) {
        assertEquals(letter, AcademicEngine.toGrade(new BigDecimal(score), AcademicEngine.conversionTable(TERMS)).letter());
    }

    @Test
    void targetsForEachBand() {
        // G = 3.19 on C = 16, R = 13 remaining credits.
        List<Target> t = AcademicEngine.targets(new BigDecimal("3.19"), 16, 13, BANDS);
        assertEquals(TargetStatus.NOT_FEASIBLE, t.get(0).status()); // Xuất sắc needs 4.1046
        assertEquals(new BigDecimal("4.1046"), t.get(0).needed());
        assertEquals(TargetStatus.FEASIBLE, t.get(1).status());     // Giỏi 3.2123
        assertEquals(new BigDecimal("3.2123"), t.get(1).needed());
        assertEquals(new BigDecimal("1.6508"), t.get(2).needed());   // Khá
        assertEquals(new BigDecimal("0.5354"), t.get(3).needed());   // Trung bình
    }

    @ParameterizedTest(name = "[{index}] gpa={0} → {1}")
    @CsvSource({"3.70, ACHIEVED, -6.4", "3.60, FEASIBLE, 3.6", "3.59, NOT_FEASIBLE, 4.6"})
    void excellentBandAroundTheBoundaryWithOneCreditLeft(String gpa, String status, String need) {
        // C = 100, R = 1: need = 3.6 × 101 − GPA × 100. ACHIEVED only when even a 0 keeps the band.
        Target ex = AcademicEngine.targets(new BigDecimal(gpa), 100, 1, BANDS).get(0);
        assertEquals(TargetStatus.valueOf(status), ex.status());
        assertEquals(0, ex.needed().compareTo(new BigDecimal(need)));
    }

    @Test
    void gpaExactlyOnTheBandStillNeedsTheBandAverage() {
        Target ex = AcademicEngine.targets(new BigDecimal("3.2"), 30, 10, BANDS).get(1);
        assertEquals(0, ex.needed().compareTo(new BigDecimal("3.2")));
        assertEquals(TargetStatus.FEASIBLE, ex.status());
        Target done = AcademicEngine.targets(new BigDecimal("4.0"), 30, 10, BANDS).get(0);
        assertEquals(TargetStatus.FEASIBLE, done.status()); // 3.6 × 40 − 4 × 30 = 24 → 2.4 per credit
    }

    @Test
    void noRemainingCredits() {
        List<Target> t = AcademicEngine.targets(new BigDecimal("3.25"), 120, 0, BANDS);
        assertEquals(TargetStatus.NOT_FEASIBLE, t.get(0).status());
        assertEquals(TargetStatus.ACHIEVED, t.get(1).status());
        assertNull(t.get(1).needed());
    }

    @Test
    void projectionAndBand() {
        BigDecimal p = AcademicEngine.project(new BigDecimal("3.19"), 16, Map.of(3, new BigDecimal("3")));
        assertEquals(new BigDecimal("3.1600"), p);
        assertEquals("Khá", AcademicEngine.bandOf(p, BANDS));
        assertEquals("Giỏi", AcademicEngine.bandOf(new BigDecimal("3.2"), BANDS));
        assertNull(AcademicEngine.bandOf(new BigDecimal("1.99"), BANDS));
    }

    @Test
    void programStatusPrecedenceAndPrerequisites() {
        List<ProgramCourse> program = AcademicEngine.merge(PortalParser.program(PortalFixtures.programBase()),
            PortalParser.program(PortalFixtures.programSpec()));
        assertEquals(9, program.size()); // TIN1001 appears in both lists once
        Map<String, Long> lms = Map.of("TIN3206", 13L, "TIN3301", 14L);
        Map<String, ProgramItem> byCode = new java.util.HashMap<>();
        for (ProgramItem i : AcademicEngine.programStatus(program, TERMS, lms)) byCode.put(i.course().code(), i);
        assertEquals(CourseStatus.PASSED, byCode.get("TIN1004").status()); // failed then passed
        assertEquals(CourseStatus.IN_LMS, byCode.get("TIN3206").status());
        assertEquals(CourseStatus.NOT_TAKEN, byCode.get("TIN2002").status());
        assertEquals(List.of(), byCode.get("TIN2002").missingPrerequisites()); // "TIN1003; TIN1004" both passed
        assertEquals(List.of("TIN9999"), byCode.get("TIN3301").missingPrerequisites()); // "TIN2001, TIN9999"
        assertEquals(List.of("TIN3206"), byCode.get("TIN3302").missingPrerequisites()); // studied-before not attempted
        // Without an LMS mapping the registered-but-unscored course is IN_PROGRESS.
        ProgramItem t = AcademicEngine.programStatus(program, TERMS, Map.of()).stream()
            .filter(i -> i.course().code().equals("TIN3206")).findFirst().orElseThrow();
        assertEquals(CourseStatus.IN_PROGRESS, t.status());
    }

    @Test
    void failedCourseWithoutRetake() {
        List<Term> onlyFirstYear = TERMS.subList(0, 2);
        ProgramItem db = AcademicEngine.programStatus(PortalParser.program(PortalFixtures.programBase()), onlyFirstYear, Map.of())
            .stream().filter(i -> i.course().code().equals("TIN1004")).findFirst().orElseThrow();
        assertEquals(CourseStatus.FAILED, db.status());
        assertEquals("F", db.letter());
    }

    @Test
    void codesAndProgramHelpers() {
        assertEquals(List.of("A1", "B2", "C3"), PortalParser.codes(" a1, B2;c3 "));
        assertEquals(List.of(), PortalParser.codes(""));
        assertEquals("CQ23CT", AcademicEngine.baseProgram("CQ23CT-PM").orElseThrow());
        assertTrue(AcademicEngine.baseProgram("CQ25CT").isEmpty());
        assertTrue(PortalParser.compulsory("Bắt Buộc"));
        assertFalse(PortalParser.compulsory("Tự Chọn"));
        assertFalse(PortalParser.hasElectiveGroups(PortalFixtures.programBase()));
        assertEquals(5, PortalStudentText.semesterOrder("Học kỳ 5"));
    }

    @Test
    void conductRanksAndWarnings() {
        assertEquals("Xuất sắc", PortalStudentText.conductRank(new BigDecimal("90")));
        assertEquals("Tốt", PortalStudentText.conductRank(new BigDecimal("89")));
        assertEquals("Trung bình", PortalStudentText.conductRank(new BigDecimal("50")));
        assertEquals("Yếu", PortalStudentText.conductRank(new BigDecimal("49")));
        List<Decision> d = PortalParser.decisions(PortalFixtures.decisions());
        assertEquals("Cảnh báo học vụ lần 1", d.get(0).name()); // newest first
        assertTrue(PortalStudentText.isAcademicWarning(d.get(0)));
        assertFalse(PortalStudentText.isAcademicWarning(d.get(1)));
    }
}
