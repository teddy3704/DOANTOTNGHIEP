package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.exception.InvalidRequestException;
import com.dlu.lmsmobile.repository.FlashcardRepository;
import com.dlu.lmsmobile.repository.StudentRepository;
import com.dlu.lmsmobile.repository.TeacherRepository;
import com.dlu.lmsmobile.service.SearchService.Candidate;
import org.junit.jupiter.api.Test;

import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class SearchServiceTest {
    @Test
    void vietnameseFoldingBothWays() {
        assertEquals("nguyen van anh", SearchService.fold("  Nguyễn   Văn Ánh "));
        assertEquals("dang phuong linh", SearchService.fold("Đặng Phương Linh"));
        assertEquals("kiem thu phan mem", SearchService.fold("KIỂM THỬ PHẦN MỀM"));
        assertEquals(SearchService.fold("nguyen"), SearchService.fold("Nguyễn"));
    }

    @Test
    void queryLengthIsValidated() {
        for (String bad : new String[]{null, "", " a ", "x".repeat(101)}) {
            assertThrows(InvalidRequestException.class, () -> SearchService.validQuery(bad), String.valueOf(bad));
        }
        assertEquals("ab", SearchService.validQuery(" AB "));
    }

    static Candidate cand(String type, String title) {
        return new Candidate(type, title, "sub", title, Map.of());
    }

    @Test
    void everyWordMustMatchPrefixFirstGroupedAndCapped() {
        List<Candidate> c = new ArrayList<>();
        c.add(cand("task", "Bài tập Kiểm thử 2"));
        c.add(cand("course", "Kiểm thử phần mềm"));
        c.add(cand("course", "Học phần kiểm thử nâng cao"));
        c.add(cand("course", "Lập trình di động"));
        c.add(cand("course", "Kiểm thử phần mềm"));            // duplicate
        for (int i = 0; i < 30; i++) c.add(cand("activity", "Kiểm thử bài " + i));
        Map<String, Object> out = SearchService.rank(SearchService.fold("kiem thu"), c, SearchService.STUDENT_ORDER);
        @SuppressWarnings("unchecked") List<Map<String, Object>> r = (List<Map<String, Object>>) out.get("results");
        assertEquals(20, r.size());
        assertEquals("Kiểm thử phần mềm", r.get(0).get("title"));      // starts with the query
        assertEquals("Học phần kiểm thử nâng cao", r.get(1).get("title"));
        assertEquals("task", r.get(2).get("type"));                     // group order course, task, activity
        assertEquals(33, out.get("total"));
        assertEquals(true, out.get("truncated"));
        assertTrue(r.stream().noneMatch(m -> "Lập trình di động".equals(m.get("title"))));
    }

    @Test
    void sqlInjectionTextIsJustAStringThatMatchesNothing() {
        StudentRepository students = mock(StudentRepository.class);
        FlashcardRepository cards = mock(FlashcardRepository.class);
        when(students.findCoursesByUserId(205L)).thenReturn(List.of(Map.of("courseid", 14L, "course_name", "Mobile")));
        when(students.findLearningItemsByUserIdAndCourseId(205L, 14L)).thenReturn(List.of());
        when(cards.findByCourseIdAndUserId(14L, 205L)).thenReturn(List.of());
        when(students.findAllTasks(205L)).thenReturn(List.of());
        var service = new SearchService(students, cards, mock(TeacherRepository.class));
        Map<String, Object> out = service.student(205L, "' OR 1=1 --");
        assertEquals(List.of(), out.get("results"));
        // repositories only ever receive the caller's ids, never the query text
        verify(students).findCoursesByUserId(205L);
        verify(students).findAllTasks(205L);
        verify(students).findLearningItemsByUserIdAndCourseId(205L, 14L);
        verifyNoMoreInteractions(students);
    }

    @Test
    void studentFindsOwnCourseActivityTaskAndFlashcardWithoutAccents() {
        StudentRepository students = mock(StudentRepository.class);
        FlashcardRepository cards = mock(FlashcardRepository.class);
        when(students.findCoursesByUserId(205L)).thenReturn(
            List.of(Map.of("courseid", 13L, "course_name", "Kiểm thử phần mềm")));
        when(students.findLearningItemsByUserIdAndCourseId(205L, 13L)).thenReturn(List.of(
            Map.of("activity_name", "Tài liệu kiểm thử hộp đen", "section_name", "Chương 2",
                "moodle_path", "/mod/resource/view.php?id=5", "coursemoduleid", 5L)));
        when(cards.findByCourseIdAndUserId(13L, 205L)).thenReturn(List.of(
            Map.of("front_text", "Kiểm thử hộp trắng là gì?", "back_text", "...")));
        when(students.findAllTasks(205L)).thenReturn(List.of(Map.of("title", "Bài tập kiểm thử", "course_name",
            "Kiểm thử phần mềm", "courseid", 13L, "due_time", 0L, "task_status", "pending")));
        var service = new SearchService(students, cards, mock(TeacherRepository.class));
        @SuppressWarnings("unchecked") List<Map<String, Object>> r =
            (List<Map<String, Object>>) service.student(205L, "kiem thu").get("results");
        assertEquals(List.of("course", "task", "activity", "flashcard"), r.stream().map(m -> m.get("type")).toList());
        assertEquals(5L, r.get(2).get("courseModuleId"));
    }

    @Test
    void teacherFindsRosterStudentByNameWithoutAccentsOrByCode() {
        TeacherRepository teachers = mock(TeacherRepository.class);
        when(teachers.findCoursesByTeacherId(102L)).thenReturn(List.of(Map.of("courseid", 14L, "course_name", "Mobile")));
        when(teachers.findStudents(102L, 14L)).thenReturn(List.of(
            Map.of("userid", 205L, "fullname", "Nguyễn Văn Ánh", "student_code", "2312005"),
            Map.of("userid", 206L, "fullname", "Trần Bình", "student_code", "2312006")));
        when(teachers.findActivities(eq(102L), eq(14L), anyString())).thenReturn(List.of());
        var service = new SearchService(mock(StudentRepository.class), mock(FlashcardRepository.class), teachers);
        @SuppressWarnings("unchecked") List<Map<String, Object>> byName =
            (List<Map<String, Object>>) service.teacher(102L, "nguyen anh").get("results");
        assertEquals(1, byName.size());
        assertEquals(205L, byName.get(0).get("userId"));
        @SuppressWarnings("unchecked") List<Map<String, Object>> byCode =
            (List<Map<String, Object>>) service.teacher(102L, "2312006").get("results");
        assertEquals("Trần Bình", byCode.get(0).get("title"));
    }

    @Test
    void dStrokeAndCombiningMarksFoldLikePrecomposedText() {
        // "dao" must find "Đào", whether the name is stored precomposed or as base letter + combining marks.
        assertEquals("dao", SearchService.fold("Đào"));
        assertEquals("dao", SearchService.fold("\u0110a\u0300o"));
        assertEquals("nguyen", SearchService.fold("Nguye\u0302\u0303n"));
        assertEquals(SearchService.fold("đào"), SearchService.fold("ĐÀO"));
    }
}
