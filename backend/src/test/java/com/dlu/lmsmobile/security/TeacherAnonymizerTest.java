package com.dlu.lmsmobile.security;

import com.dlu.lmsmobile.config.DataProfile;
import com.dlu.lmsmobile.repository.FlashcardRepository;
import com.dlu.lmsmobile.repository.StudentRepository;
import com.dlu.lmsmobile.repository.TeacherRepository;
import com.dlu.lmsmobile.service.SearchService;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** REAL-DATA-2: anonymous teacher screens on real data. Codes below are invented. */
class TeacherAnonymizerTest {

    @RestController
    static class FakeTeacherApi {
        @GetMapping("/api/v1/dev/teachers/9/courses/1/students")
        public List<Map<String, Object>> students() {
            return List.of(
                Map.of("studentid", 501, "fullname", "1234567", "student_code", "1234567", "risk_score", 70),
                Map.of("studentid", 502, "fullname", "7654321", "student_code", "7654321", "risk_score", 10,
                    "notes", List.of(Map.of("student_id", 501, "fullname", "1234567", "note", "x"))));
        }

        @GetMapping("/api/v1/dev/students/501/dashboard")
        public Map<String, Object> own() {
            return Map.of("userid", 501, "firstname", "1234567");
        }
    }

    static MockMvc mvc(DataProfile profile) {
        return MockMvcBuilders.standaloneSetup(new FakeTeacherApi())
            .setControllerAdvice(new TeacherAnonymizer(profile)).build();
    }

    @Test
    void realTeacherResponsesContainNoStudentCodeOnlyStableAliases() throws Exception {
        String body = mvc(DataProfile.real()).perform(get("/api/v1/dev/teachers/9/courses/1/students"))
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        assertFalse(body.contains("1234567"), body);
        assertFalse(body.contains("7654321"), body);
        assertTrue(body.contains("\"fullname\":\"SV 01\""), body);
        assertTrue(body.contains("\"student_code\":\"SV 01\""), body);
        assertTrue(body.contains("\"fullname\":\"SV 02\""), body);
        // The same student keeps the same alias inside nested rows and in later responses.
        assertEquals(3, body.split("SV 01", -1).length - 1, body);
        String again = mvc(DataProfile.real()).perform(get("/api/v1/dev/teachers/9/courses/1/students"))
            .andReturn().getResponse().getContentAsString();
        assertTrue(again.contains("SV 01"));
    }

    @Test
    void studentOwnScreensAndDemoAreUntouched() throws Exception {
        assertTrue(mvc(DataProfile.real()).perform(get("/api/v1/dev/students/501/dashboard"))
            .andReturn().getResponse().getContentAsString().contains("1234567"));
        assertTrue(mvc(DataProfile.demo()).perform(get("/api/v1/dev/teachers/9/courses/1/students"))
            .andReturn().getResponse().getContentAsString().contains("1234567"));
    }

    @Test
    void realTeacherSearchNeverMatchesStudents() {
        TeacherRepository teachers = mock(TeacherRepository.class);
        when(teachers.findCoursesByTeacherId(9L)).thenReturn(List.of(Map.of("courseid", 1L, "course_name", "Môn A",
            "course_shortname", "MA")));
        when(teachers.findStudents(9L, 1L)).thenReturn(List.of(Map.of("userid", 501L, "fullname", "1234567",
            "student_code", "1234567")));
        var real = new SearchService(mock(StudentRepository.class), mock(FlashcardRepository.class), teachers, DataProfile.real());
        assertFalse(String.valueOf(real.teacher(9L, "1234567")).contains("1234567"));
        verify(teachers, never()).findStudents(anyLong(), anyLong());
        var demo = new SearchService(mock(StudentRepository.class), mock(FlashcardRepository.class), teachers, DataProfile.demo());
        assertTrue(String.valueOf(demo.teacher(9L, "1234567")).contains("1234567"));
    }

    @Test
    void realTeacherTextsSayHandInsNotAccess() {
        var a = new TeacherAnonymizer(DataProfile.real());
        Object out = a.anonymise(Map.of("signals", List.of("12 ngày chưa truy cập", "Chưa từng truy cập môn học",
            "Tiến độ 20%", "Tiến độ học tập dưới 30%", "Không có sự kiện học tập trong 7 ngày: +10 điểm")));
        String text = String.valueOf(out);
        assertFalse(text.contains("truy cập"), text);
        assertTrue(text.contains("12 ngày chưa nộp bài hoặc làm bài kiểm tra"), text);
        assertTrue(text.contains("Tiến độ (theo hoạt động có chấm điểm) 20%"), text);
        assertTrue(text.contains("Tiến độ (theo hoạt động có chấm điểm) dưới 30%"), text);
        assertFalse(text.contains("(theo hoạt động có chấm điểm) (theo"), text);
    }
}
