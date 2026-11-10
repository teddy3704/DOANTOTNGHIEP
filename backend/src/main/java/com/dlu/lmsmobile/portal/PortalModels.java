package com.dlu.lmsmobile.portal;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Minimal typed view of Portal data. ONLY the fields listed in docs/V3_PORTAL_PROMPT.md §1 are
 * represented; contact, birth, gender, *_Eng, diploma and staff fields are never mapped.
 */
public final class PortalModels {
    private PortalModels() {
    }

    /** One course result row of LayBangDiemSinhVien. */
    public record CourseResult(String courseId, String name, Integer credits, BigDecimal score10,
                               BigDecimal score4, String letter, boolean passed, boolean gather,
                               boolean notComputed, String yearStudy, String termId) {
        public boolean scored() {
            return score10 != null || score4 != null || letter != null;
        }

        /** Counted in the 4-point GPA: gathered, computed, scored, has credits. */
        public boolean countsForGpa() {
            return gather && !notComputed && score4 != null && credits != null && credits > 0;
        }
    }

    /** One (year, term) of the transcript with the Portal's own aggregates. */
    public record Term(String yearStudy, String termId, List<CourseResult> courses, BigDecimal gpa4,
                       BigDecimal gpa10, BigDecimal cumulativeGpa4, BigDecimal cumulativeGpa10,
                       BigDecimal termCredits, BigDecimal cumulativeCredits, String rank) {
        public boolean hasScores() {
            return courses.stream().anyMatch(CourseResult::scored);
        }
    }

    /** One course of LayDanhSachHocPhanTheoCTDT. */
    public record ProgramCourse(String code, String name, Integer credits, Integer theory, Integer practice,
                                String semester, Integer semesterNo, boolean compulsory, List<String> prerequisites,
                                List<String> priorCourses, String programId) {
    }

    /** One row of LayBangDiemSinhVienTheoLop. */
    public record ClassGrade(String studentId, String lastName, String firstName, BigDecimal credits,
                             BigDecimal average10, BigDecimal average4, BigDecimal cumulative10,
                             BigDecimal cumulative4, String rank, BigDecimal behaviorScore, String behaviorRank) {
        public boolean hasData() {
            return average4 != null || average10 != null;
        }
    }

    /** One row of LayBangDiemRenLuyenTheoLop.resultDanhSach. */
    public record Conduct(String studentId, BigDecimal selfScore, BigDecimal classScore, BigDecimal departmentScore,
                          BigDecimal finalScore, String statusId) {
    }

    /** One row of LayDanhSachSinhVienTheoLop. */
    public record ClassMember(String studentId, String name, String classId, String studyProgramId,
                              boolean inClass, String classRole) {
    }

    /** One row of LayDanhSachQuyetDinh. */
    public record Decision(String name, Integer typeId, String fullText, LocalDate signDate, String yearStudy,
                           String termId) {
    }
}
