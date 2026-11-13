package com.dlu.lmsmobile.portal;

import com.dlu.lmsmobile.portal.LocalTranscriptService.InProgress;
import com.dlu.lmsmobile.portal.LocalTranscriptService.Parsed;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/**
 * REAL-DATA-2 local transcript parsing. Every row here is invented test data that lives only in
 * this test; the running app reads nothing but the student's own file outside the repository.
 */
class LocalTranscriptServiceTest {
    static final String HEADER = "hoc_ky,ma_hp,ten_hp,so_tc,diem_10,diem_4,diem_chu,tinh_gpa";

    @Test
    void missingColumnsAreNamed() {
        var e = assertThrows(LocalTranscriptService.FormatException.class,
            () -> LocalTranscriptService.parse(List.of("hoc_ky,ma_hp,ten_hp,so_tc,diem_10", "HK1,X1,Môn X,3,8")));
        assertEquals("Bảng điểm thiếu cột: diem_4, diem_chu, tinh_gpa", e.getMessage());
    }

    @Test
    void blankLinesAndHeaderOnlyFilesGiveNoData() {
        assertTrue(LocalTranscriptService.parse(List.of(HEADER, "", ",,,,,,,", "   ")).terms().isEmpty());
        assertTrue(LocalTranscriptService.parse(List.of()).terms().isEmpty());
    }

    @Test
    void gpaUsesCreditsAndSkipsCoursesThatDoNotCount() {
        Parsed p = LocalTranscriptService.parse(List.of(HEADER,
            "HK1 2022-2023,A1,Môn A,3,8.5,4,A,1",
            "",
            "HK1 2022-2023,B1,Môn B,2,7.0,3,B,1",
            "HK1 2022-2023,GDTC1,Giáo dục thể chất 1,1,9.0,4,A,0",
            "HK2 2022-2023,C1,Môn C,4,6.0,2,C,1"));
        assertEquals(2, p.terms().size());
        // (3×4 + 2×3) / 5 = 3.60 for the first term; physical education does not count.
        assertEquals(0, new BigDecimal("3.6").compareTo(p.terms().get(0).cumulativeGpa4()));
        // (12 + 6 + 8) / 9 = 2.8889 cumulative.
        assertEquals("2.8889", p.terms().get(1).cumulativeGpa4().toPlainString());
        assertEquals(0, new BigDecimal("9").compareTo(p.terms().get(1).cumulativeCredits()));
        assertFalse(p.terms().get(0).courses().get(2).countsForGpa());
    }

    @Test
    void aRetakeReplacesTheEarlierAttempt() {
        Parsed p = LocalTranscriptService.parse(List.of(HEADER,
            "HK1,A1,Môn A,3,3.0,0,F,1",
            "HK2,A1,Môn A,3,7.5,3,B,1"));
        assertEquals(0, new BigDecimal("3").compareTo(AcademicEngine.recompute(p.terms()).gpa4()));
    }

    @Test
    void coursesInProgressAreMatchedToLmsByNameOrManualMapOtherwiseLeftUnmatched() {
        Parsed p = LocalTranscriptService.parse(List.of(HEADER,
            "HK1,A1,Môn A,3,8,3.5,B+,1",
            "HK2,P1,Lập trình Python,3,,,,1",
            "HK2,Q1,Môn không có trên LMS,2,,,,1",
            "HK2,R1,Tên khác hẳn,2,,,,1",
            "HK2,GDQP,Giáo dục quốc phòng,4,,,,0"));
        List<InProgress> open = p.inProgress();
        assertEquals(List.of("P1", "Q1", "R1"), open.stream().map(InProgress::code).toList());
        Map<Long, String> lms = Map.of(10L, "Lập trình Python CTK46-PM", 11L, "Thiết kế web - CTK46A");
        assertEquals(10L, LocalTranscriptService.matchLms(open.get(0), lms, Map.of()));
        assertNull(LocalTranscriptService.matchLms(open.get(1), lms, Map.of()));
        assertEquals(11L, LocalTranscriptService.matchLms(open.get(2), lms, Map.of("R1", 11L)));
        assertNull(LocalTranscriptService.matchLms(open.get(2), lms, Map.of("R1", 99L)));
    }

    @Test
    void badNumbersNameTheLine() {
        var e = assertThrows(LocalTranscriptService.FormatException.class,
            () -> LocalTranscriptService.parse(List.of(HEADER, "HK1,A1,Môn A,ba,8,4,A,1")));
        assertEquals("Dòng 2: so_tc không phải số nguyên", e.getMessage());
    }

    @Test
    void quotedNamesWithCommasAndBomAreRead() {
        Parsed p = LocalTranscriptService.parse(List.of("﻿" + HEADER, "HK1,A1,\"Môn A, phần 1\",2,9,4,A,1"));
        assertEquals("Môn A, phần 1", p.terms().get(0).courses().get(0).name());
    }

    @Test
    void normaliseIgnoresCaseDiacriticsAndPunctuation() {
        assertEquals("lap trinh di dong k46", LocalTranscriptService.normalize("Lập trình di động - K46"));
        assertEquals("do an", LocalTranscriptService.normalize("Đồ án"));
    }

    @Test
    void absentFromExamCountsInTheTermButNotInTheCumulative() {
        Parsed p = LocalTranscriptService.parse(List.of(HEADER,
            "HK1 2022-2023,A1,Môn A,2,8,3,B,1",
            "HK1 2022-2023,B1,Môn B,2,0,0,VT,1"));
        // Term: (2×3 + 2×0) / 4 = 1.5; cumulative: passed only → 3.0 on 2 credits.
        assertEquals("1.5000", p.terms().get(0).gpa4().toPlainString());
        assertEquals("3.0000", p.cumulative().gpa4().toPlainString());
        assertEquals(2, p.cumulative().credits());
        assertEquals("HK1", p.terms().get(0).termId());
        assertEquals("2022-2023", p.terms().get(0).yearStudy());
    }

    @Test
    void theBestPassedAttemptCountsEvenIfALaterOneIsLower() {
        Parsed p = LocalTranscriptService.parse(List.of(HEADER,
            "HK1 2022-2023,A1,Môn A,3,6.0,2,C,1",
            "HK2 2022-2023,A1,Môn A,3,5.0,1,D,1"));
        assertEquals("2.0000", p.cumulative().gpa4().toPlainString());
        assertEquals(3, p.cumulative().credits());
        assertEquals("6.0000", p.cumulative().gpa10().toPlainString());
    }

    @Test
    void anImprovementRetakeReplacesTheOldScoreWithoutAddingCredits() {
        Parsed p = LocalTranscriptService.parse(List.of(HEADER,
            "HK1 2024-2025,D1,Môn D,4,4.5,1,D,1",
            "HK1 2024-2025,E1,Môn E,4,8.5,4,A,1",
            "HK1 2026-2027,D1,Môn D,4,,,,1",
            "HK1 2026-2027,N1,Môn mới,10,,,,1"));
        List<InProgress> open = p.inProgress();
        assertTrue(open.get(0).improvement());
        assertEquals(0, new BigDecimal("1").compareTo(open.get(0).previousScore4()));
        assertFalse(open.get(1).improvement());
        // Base (4×1 + 4×4)/8 = 2.5. D1 → 3 replaces 1 (no credits), N1 → 2 adds 10 credits:
        // (20 + 4×2 + 10×2) / 18 = 2.6667.
        assertEquals("2.6667", LocalTranscriptService.project(p.cumulative(), open,
            Map.of("D1", new BigDecimal("3"), "N1", new BigDecimal("2"))).toPlainString());
        // A lower improvement score keeps the old one.
        assertEquals("2.5000", LocalTranscriptService.project(p.cumulative(), open,
            Map.of("D1", new BigDecimal("0"))).toPlainString());
    }

    @Test
    void conductFileIsReadInTermOrder() {
        Map<String, Object> c = LocalTranscriptService.conductOf(List.of("hoc_ky,diem_ren_luyen",
            "HK2 2022-2023,80", "HK1 2022-2023,70", ""));
        List<?> terms = (List<?>) c.get("terms");
        assertEquals(2, terms.size());
        assertEquals("HK1", ((Map<?, ?>) terms.get(0)).get("termId"));
        assertEquals(75.0, c.get("average"));
        assertThrows(LocalTranscriptService.FormatException.class,
            () -> LocalTranscriptService.conductOf(List.of("ky,diem", "HK1 2022-2023,80")));
    }

    @Test
    void theCurrentTermCourseWinsAndParenthesesAreIgnored() {
        Parsed p = LocalTranscriptService.parse(List.of(HEADER,
            "HK1 2024-2025,D1,Phát triển ứng dụng Desktop,4,4.5,1,D,1",
            "HK1 2026-2027,D1,Phát triển ứng dụng Desktop,4,,,,1",
            "HK1 2026-2027,T1,Đồ án tốt nghiệp (Thực hành),10,,,,1"));
        Map<Long, String> lms = Map.of(1L, "Phát triển ứng dụng Desktop - K46", 2L, "Phát triển ứng dụng Desktop - K48",
            3L, "Đồ án tốt nghiệp CTK46");
        Map<Long, Long> starts = Map.of(1L, 100L, 2L, 300L, 3L, 300L);
        assertEquals(2L, LocalTranscriptService.matchLms(p.inProgress().get(0), lms, Map.of(), starts));
        assertEquals(3L, LocalTranscriptService.matchLms(p.inProgress().get(1), lms, Map.of(), starts));
    }
}

