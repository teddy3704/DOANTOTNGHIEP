package com.dlu.lmsmobile.portal;

import com.dlu.lmsmobile.exception.InvalidRequestException;
import com.dlu.lmsmobile.exception.ResourceNotFoundException;
import com.dlu.lmsmobile.repository.TeacherRepository;
import com.dlu.lmsmobile.service.LearningHealthService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/** V3-P6 advisor class on invented fixtures: term discovery, flags, masking, LMS bridge, CSV. */
@SuppressWarnings("unchecked")
class AdvisorPortalServiceTest {
    PortalClient client;
    PortalProperties props;
    TeacherRepository teachers;
    LearningHealthService health;
    AdvisorPortalService service;

    @BeforeEach
    void setup() {
        props = new PortalProperties();
        props.setEnabled(true);
        props.setApiKey("k");
        props.getAdvisors().put(102L, List.of("ITK99Z"));
        props.getStudents().put(205L, new PortalProperties.StudentLink("2399Z001", "CQ99CT-PM", "ITK99Z"));
        props.getLmsStudentLinks().put(207L, "2399Z002"); // 207 is not in teacher 102's courses
        client = mock(PortalClient.class);
        when(client.configured()).thenReturn(true);
        when(client.properties()).thenReturn(props);
        when(client.classGrades(anyString(), anyString(), eq("ITK99Z"))).thenReturn(PortalFixtures.classGradesEmpty());
        when(client.classGrades("2099-2100", "HK01", "ITK99Z")).thenReturn(PortalFixtures.classGradesCurrent());
        when(client.classGrades("2098-2099", "HK02", "ITK99Z")).thenReturn(PortalFixtures.classGradesPrevious());
        when(client.classConduct(anyString(), anyString(), eq("ITK99Z"))).thenReturn(PortalFixtures.json("{\"resultDanhSach\":[]}"));
        when(client.classConduct("2099-2100", "HK01", "ITK99Z")).thenReturn(PortalFixtures.classConductCurrent());
        when(client.classStudents("ITK99Z")).thenReturn(PortalFixtures.classMembers());
        teachers = mock(TeacherRepository.class);
        when(teachers.findCoursesByTeacherId(102L)).thenReturn(List.of(Map.of("courseid", 13L, "course_name", "Software Testing")));
        when(teachers.findStudents(102L, 13L)).thenReturn(List.of(
            Map.of("userid", 205L, "student_code", ""),
            Map.of("userid", 206L, "student_code", "2399Z003")));
        health = mock(LearningHealthService.class);
        when(health.overview(206L)).thenReturn(Map.of("courses", List.of(
            Map.of("courseId", 13L, "courseName", "Software Testing", "level", "YELLOW"),
            Map.of("courseId", 99L, "courseName", "Khóa của GV khác", "level", "RED"))));
        Clock clock = Clock.fixed(Instant.parse("2100-11-01T00:00:00Z"), ZoneId.of("Asia/Ho_Chi_Minh"));
        service = new AdvisorPortalService(client, new PortalIdentity(client), teachers, health, clock);
    }

    @Test
    void findsTheLatestTermsWithDataInsteadOfTrustingTheClock() {
        List<AdvisorPortalService.TermKey> terms = service.termsWithData("ITK99Z");
        assertEquals(List.of(new AdvisorPortalService.TermKey("2099-2100", "HK01"),
            new AdvisorPortalService.TermKey("2098-2099", "HK02")), terms);
    }

    @Test
    void overviewWithoutMask() {
        Map<String, Object> o = service.overview(102L, "itk99z", null, null, false);
        assertEquals("ITK99Z", o.get("classId"));
        assertEquals(Map.of("yearStudy", "2099-2100", "termId", "HK01"), o.get("term"));
        assertEquals(3L, o.get("size")); // one member no longer in class
        assertEquals(2.73, o.get("averageGpa4"));
        assertEquals(2.67, o.get("previousAverageGpa4"));
        assertEquals(0.06, o.get("trend"));
        assertEquals(2, o.get("attentionCount"));
        List<Map<String, Object>> students = (List<Map<String, Object>>) o.get("students");
        assertEquals(List.of(1, 2, 3, 4), students.stream().map(s -> s.get("no")).toList());
        assertEquals("Nguyễn Văn An", students.get(0).get("name"));
        assertEquals(List.of(), students.get(0).get("flags"));
        assertEquals(List.of("LOW_GPA", "WEAK_RANK", "LOW_CONDUCT"), students.get(1).get("flags"));
        assertEquals(List.of("NO_SCORE"), students.get(3).get("flags"));
        List<Map<String, Object>> hist = (List<Map<String, Object>>) o.get("histogram");
        assertEquals(List.of(0, 1, 0, 1, 1, 0), hist.stream().map(h -> h.get("count")).toList());
        assertEquals(Map.of("Giỏi", 1, "Khá", 1, "Yếu", 1, "KXL", 1), o.get("ranks"));
    }

    @Test
    void presentationMaskHidesNamesAndIdsByServerDefault() throws Exception {
        props.setPresentationMask(true);
        Map<String, Object> o = service.overview(102L, "ITK99Z", null, null, null);
        assertEquals(true, o.get("mask"));
        String json = new ObjectMapper().writeValueAsString(o);
        for (String secret : List.of("Nguyễn Văn An", "Lê", "Trần Thị", "2399Z001", "2399Z002")) {
            assertFalse(json.contains(secret), secret);
        }
        List<Map<String, Object>> students = (List<Map<String, Object>>) o.get("students");
        assertEquals("SV 01", students.get(0).get("name"));
        assertEquals("23**Z0**", students.get(0).get("studentId"));
        assertEquals(false, service.overview(102L, "ITK99Z", null, null, false).get("mask"));
    }

    @Test
    void otherClassOrTeacherIsNotLinked() {
        assertThrows(PortalNotLinkedException.class, () -> service.overview(102L, "ITK98A", null, null, false));
        assertThrows(PortalNotLinkedException.class, () -> service.overview(103L, "ITK99Z", null, null, false));
        assertThrows(ResourceNotFoundException.class, () -> service.overview(102L, "ITK99Z", "2097-2098", "HK01", false));
    }

    @Test
    void studentDetailShowsLmsSignalsOnlyForTheTeachersOwnCourses() {
        Map<String, Object> d = service.student(102L, "ITK99Z", 3, null, null, false); // 2399Z003 = Moodle 206 by idnumber
        Map<String, Object> lms = (Map<String, Object>) d.get("lms");
        assertEquals(true, lms.get("linked"));
        List<Map<String, Object>> courses = (List<Map<String, Object>>) lms.get("courses");
        assertEquals(List.of(13L), courses.stream().map(c -> c.get("courseId")).toList());
        assertEquals(2, ((List<?>) d.get("history")).size());
    }

    @Test
    void configuredLinksOnlyCountWhenTheStudentIsOnTheTeachersRoster() {
        Map<String, Object> viaConfig = (Map<String, Object>) service.student(102L, "ITK99Z", 1, null, null, false).get("lms");
        assertEquals(true, viaConfig.get("linked"));   // 2399Z001 ↔ 205 (server config), 205 is on the roster
        Map<String, Object> offRoster = (Map<String, Object>) service.student(102L, "ITK99Z", 2, null, null, false).get("lms");
        assertEquals(false, offRoster.get("linked")); // 2399Z002 ↔ 207, but 207 is not in the teacher's course
        verify(health, never()).overview(207L);
        assertThrows(ResourceNotFoundException.class, () -> service.student(102L, "ITK99Z", 99, null, null, false));
    }

    @Test
    void csvNeedsConfirmationAndMaskOff() {
        assertThrows(InvalidRequestException.class, () -> service.exportCsv(102L, "ITK99Z", null, null, false, false));
        props.setPresentationMask(true);
        assertThrows(InvalidRequestException.class, () -> service.exportCsv(102L, "ITK99Z", null, null, null, true));
        String csv = service.exportCsv(102L, "ITK99Z", null, null, false, true);
        String[] lines = csv.split("\r\n");
        assertEquals(5, lines.length);
        assertTrue(lines[0].startsWith("﻿STT,MSSV,Họ tên"));
        assertTrue(lines[2].contains("2399Z002") && lines[2].contains("ĐTB<2.0 Yếu/Kém Rèn luyện thấp"));
    }

    @Test
    void csvEscapesFormulasAndCommas() {
        assertEquals("'=1+1", AdvisorPortalService.csv("=1+1"));
        assertEquals("\"a,b\"", AdvisorPortalService.csv("a,b"));
        assertEquals("", AdvisorPortalService.csv(null));
    }
}
