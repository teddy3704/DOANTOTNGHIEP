package com.dlu.lmsmobile.portal;

import com.dlu.lmsmobile.exception.ResourceNotFoundException;
import com.dlu.lmsmobile.repository.StudentRepository;
import com.dlu.lmsmobile.service.GradeForecastService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/** V3 P1–P5 with a mocked Portal client returning invented fixtures. */
@SuppressWarnings("unchecked")
class StudentPortalServiceTest {
    PortalClient client;
    PortalProperties props;
    GradeForecastService forecasts;
    StudentRepository students;
    StudentPortalService service;

    @BeforeEach
    void setup() {
        props = new PortalProperties();
        props.setEnabled(true);
        props.setApiKey("k");
        props.getStudents().put(205L, new PortalProperties.StudentLink(PortalFixtures.ME, "CQ99CT-PM", "ITK99Z"));
        props.getCourseMap().put(13L, "TIN3206");
        props.getCourseMap().put(14L, "TIN3301");
        props.getCourseMap().put(77L, "TIN2002"); // not enrolled → ignored
        client = mock(PortalClient.class);
        when(client.configured()).thenReturn(true);
        when(client.properties()).thenReturn(props);
        when(client.studentTranscript(PortalFixtures.ME, "CQ99CT-PM")).thenReturn(PortalFixtures.transcript());
        when(client.programCourses("CQ99CT")).thenReturn(PortalFixtures.programBase());
        when(client.programCourses("CQ99CT-PM")).thenReturn(PortalFixtures.programSpec());
        when(client.decisions(PortalFixtures.ME)).thenReturn(PortalFixtures.decisions());
        when(client.classConduct("2098-2099", "HK01", "ITK99Z")).thenReturn(PortalFixtures.conduct(82, 90));
        when(client.classConduct("2098-2099", "HK02", "ITK99Z")).thenReturn(PortalFixtures.conduct(75, 30));
        when(client.classConduct("2099-2100", "HK01", "ITK99Z")).thenReturn(PortalFixtures.conduct(88, 60));
        when(client.classConduct("2099-2100", "HK02", "ITK99Z")).thenReturn(PortalFixtures.conduct(null, 70));
        forecasts = mock(GradeForecastService.class);
        when(forecasts.studentForecast(205L, 13L)).thenReturn(Map.of("current", 82.0));
        when(forecasts.studentForecast(205L, 14L)).thenThrow(new ResourceNotFoundException("no grades"));
        students = mock(StudentRepository.class);
        when(students.findCoursesByUserId(205L)).thenReturn(List.of(
            Map.of("courseid", 13L, "course_name", "Software Testing"),
            Map.of("courseid", 14L, "course_name", "Mobile Application Development")));
        service = new StudentPortalService(client, new PortalIdentity(client), forecasts, students);
    }

    @Test
    void transcriptHasTermsCoursesAndOfficialGpaWithoutPrivateFields() throws Exception {
        Map<String, Object> out = service.transcript(205L);
        assertEquals(Map.of("yearStudy", "2099-2100", "termId", "HK01"), out.get("dataUntil"));
        Map<String, Object> s = (Map<String, Object>) out.get("summary");
        assertEquals(3.19, s.get("cumulativeGpa4"));
        assertEquals(3.19, s.get("recomputedGpa4"));
        assertEquals(0.0, s.get("gpaDifference"));
        assertEquals(16, s.get("recomputedCredits"));
        assertEquals("Khá", s.get("band"));
        List<Map<String, Object>> terms = (List<Map<String, Object>>) out.get("terms");
        assertEquals(4, terms.size());
        assertEquals(false, terms.get(3).get("hasScores"));
        String json = new ObjectMapper().writeValueAsString(out);
        for (String forbidden : List.of("0900000000", "01/01/2080", "Nơi bịa", "Nguyen Van An", "XX-0000", "QD-0000", "staff",
            "MobilePhone", "BirthDay")) {
            assertFalse(json.contains(forbidden), forbidden);
        }
    }

    @Test
    void summaryCountsMissingCompulsoryCredits() {
        Map<String, Object> s = service.summary(205L);
        assertEquals(10, s.get("remainingCompulsoryCredits")); // TIN2002 3 + TIN3206 3 + TIN3302 4
        assertEquals(3.19, s.get("cumulativeGpa4"));
    }

    @Test
    void programMergesBaseAndSpecialisationWithLmsStatus() {
        Map<String, Object> out = service.program(205L);
        Map<String, Object> s = (Map<String, Object>) out.get("summary");
        assertEquals(23, s.get("compulsoryCredits"));
        assertEquals(13, s.get("compulsoryPassedCredits"));
        assertEquals(3, s.get("electivePassedCredits"));
        assertEquals(56.5, s.get("completionPercent"));
        assertEquals(false, s.get("electiveGroupsKnown"));
        Map<String, Integer> counts = (Map<String, Integer>) s.get("statusCounts");
        assertEquals(5, counts.get("PASSED"));
        assertEquals(2, counts.get("IN_LMS"));
        List<Map<String, Object>> eligible = (List<Map<String, Object>>) out.get("eligible");
        assertEquals(List.of("TIN2002"), eligible.stream().map(e -> e.get("code")).toList());
        List<Map<String, Object>> blocked = (List<Map<String, Object>>) out.get("blocked");
        assertEquals(List.of("TIN3302"), blocked.stream().map(e -> e.get("code")).toList());
        assertEquals(List.of("TIN3206"), blocked.get(0).get("missing"));
        List<Map<String, Object>> semesters = (List<Map<String, Object>>) out.get("semesters");
        assertEquals("Học kỳ 1", semesters.get(0).get("semester"));
        Map<String, Object> testing = ((List<Map<String, Object>>) semesters.stream()
            .filter(x -> x.get("semester").equals("Học kỳ 5")).findFirst().orElseThrow().get("courses")).get(0);
        assertEquals("IN_LMS", testing.get("status"));
        assertEquals("Software Testing", testing.get("lmsCourseName"));
    }

    @Test
    void gpaSimulationBridgesTheLmsForecast() {
        Map<String, Object> out = service.gpaSimulation(205L);
        assertEquals(3.19, out.get("gpa4"));
        assertEquals(16, out.get("credits"));
        assertEquals(13, out.get("remainingCredits")); // 3 compulsory courses (10) + elective already on LMS (3)
        List<Map<String, Object>> courses = (List<Map<String, Object>>) out.get("courses");
        Map<String, Object> testing = courses.stream().filter(c -> c.get("code").equals("TIN3206")).findFirst().orElseThrow();
        assertEquals(82.0, testing.get("forecastPercent"));
        assertEquals(8.2, testing.get("forecastScore10"));
        assertEquals("B", testing.get("forecastLetter"));
        Map<String, Object> mobile = courses.stream().filter(c -> c.get("code").equals("TIN3301")).findFirst().orElseThrow();
        assertNull(mobile.get("forecastLetter")); // no grades on Moodle yet
        Map<String, Object> p = (Map<String, Object>) out.get("projection");
        assertEquals(1, p.get("lmsCourses"));
        assertEquals(3.16, p.get("projectedGpa4"));
        assertEquals("Khá", p.get("projectedBand"));
        assertEquals(10, p.get("remainingCredits"));
        List<Map<String, Object>> targets = (List<Map<String, Object>>) out.get("targets");
        assertEquals("NOT_FEASIBLE", targets.get(0).get("status"));
        assertEquals(3.21, targets.get(1).get("needed"));
    }

    @Test
    void gpaSimulationWithoutAnyLmsCourseHasNoProjection() {
        props.getCourseMap().clear();
        Map<String, Object> out = service.gpaSimulation(205L);
        assertNull(out.get("projection"));
        assertEquals(10, out.get("remainingCredits")); // the elective is no longer counted
    }

    @Test
    void conductKeepsOnlyOwnRows() {
        Map<String, Object> out = service.conduct(205L);
        List<Map<String, Object>> terms = (List<Map<String, Object>>) out.get("terms");
        assertEquals(3, terms.size());
        assertEquals(List.of(82.0, 75.0, 88.0), terms.stream().map(t -> t.get("finalScore")).toList());
        assertEquals(81.7, out.get("average"));
        assertEquals("Tốt", terms.get(0).get("classification"));
        verify(client, times(4)).classConduct(anyString(), anyString(), eq("ITK99Z"));
    }

    @Test
    void decisionsFlagAcademicWarnings() {
        Map<String, Object> out = service.decisions(205L);
        assertEquals(1, out.get("warningCount"));
        List<Map<String, Object>> list = (List<Map<String, Object>>) out.get("decisions");
        assertEquals("2100-02-15", list.get(0).get("signDate"));
        assertEquals(true, list.get(0).get("academicWarning"));
    }

    @Test
    void unlinkedOrDisabled() {
        assertThrows(PortalNotLinkedException.class, () -> service.transcript(206L));
        when(client.configured()).thenReturn(false);
        PortalUnavailableException e = assertThrows(PortalUnavailableException.class, () -> service.transcript(205L));
        assertEquals("PORTAL_DISABLED", e.code());
        verify(client, never()).studentTranscript(eq("x"), anyString());
    }

    @Test
    void portalDownPropagatesAsUnavailable() {
        when(client.studentTranscript(anyString(), anyString())).thenThrow(PortalUnavailableException.unavailable());
        assertThrows(PortalUnavailableException.class, () -> service.summary(205L));
    }
}
