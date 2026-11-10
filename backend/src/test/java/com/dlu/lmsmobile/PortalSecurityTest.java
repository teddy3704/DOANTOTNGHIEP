package com.dlu.lmsmobile;

import com.dlu.lmsmobile.controller.StudentPortalController;
import com.dlu.lmsmobile.controller.TeacherPortalController;
import com.dlu.lmsmobile.portal.*;
import com.dlu.lmsmobile.security.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.security.servlet.UserDetailsServiceAutoConfiguration;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Map;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** V3 Portal endpoints behind the real filter chain: 401, 403, 404 PORTAL_NOT_LINKED, 503 codes. */
@WebMvcTest(controllers = {StudentPortalController.class, TeacherPortalController.class},
        excludeAutoConfiguration = UserDetailsServiceAutoConfiguration.class,
        properties = {"app.jwt.secret=isolated-test-only-secret-not-for-runtime-1234",
                "app.demo-auth.enabled=true", "app.demo-auth.student-id=205",
                "app.demo-auth.teacher-id=102", "server.address=127.0.0.1"})
@ActiveProfiles("local-development")
@Import({SecurityConfig.class, JwtAuthenticationFilter.class, JwtTokenProvider.class, LocalDevelopmentSettings.class})
class PortalSecurityTest {
    @Autowired MockMvc mvc;
    @Autowired JwtTokenProvider tokens;
    @MockBean StudentPortalService students;
    @MockBean AdvisorPortalService advisor;
    @MockBean PortalSourcesService sources;

    private String student() {
        return "Bearer " + tokens.generateToken(205L, "STUDENT");
    }

    private String teacher() {
        return "Bearer " + tokens.generateToken(102L, "TEACHER");
    }

    static final String[] STUDENT = {"summary", "transcript", "program", "gpa-simulation", "conduct", "decisions", "sources"};
    static final String[] TEACHER = {"advisor/classes", "advisor/classes/ITK99Z", "advisor/classes/ITK99Z/students/1",
        "advisor/classes/ITK99Z/export?confirm=true&mask=false", "sources"};

    @Test
    void anonymousOtherIdentityAndWrongRole() throws Exception {
        for (String p : STUDENT) {
            String path = "/api/v1/dev/students/205/portal/" + p;
            mvc.perform(get(path)).andExpect(status().isUnauthorized());
            mvc.perform(get(path.replace("/205/", "/206/")).header("Authorization", student())).andExpect(status().isForbidden());
            mvc.perform(get(path).header("Authorization", teacher())).andExpect(status().isForbidden());
        }
        for (String p : TEACHER) {
            String path = "/api/v1/dev/teachers/102/portal/" + p;
            mvc.perform(get(path)).andExpect(status().isUnauthorized());
            mvc.perform(get(path.replace("/102/", "/103/")).header("Authorization", teacher())).andExpect(status().isForbidden());
            mvc.perform(get(path).header("Authorization", student())).andExpect(status().isForbidden());
        }
        verifyNoInteractions(students, advisor, sources);
    }

    @Test
    void unlinkedStudentIsNotFoundWithCode() throws Exception {
        when(students.transcript(205L)).thenThrow(new PortalNotLinkedException());
        mvc.perform(get("/api/v1/dev/students/205/portal/transcript").header("Authorization", student()))
            .andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value("PORTAL_NOT_LINKED"));
    }

    @Test
    void foreignAdvisorClassIsNotFound() throws Exception {
        when(advisor.overview(eq(102L), eq("ITK98A"), any(), any(), any())).thenThrow(new PortalNotLinkedException());
        mvc.perform(get("/api/v1/dev/teachers/102/portal/advisor/classes/ITK98A").header("Authorization", teacher()))
            .andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value("PORTAL_NOT_LINKED"));
    }

    @Test
    void portalDownOrDisabledIs503WithCode() throws Exception {
        when(students.program(205L)).thenThrow(PortalUnavailableException.unavailable());
        mvc.perform(get("/api/v1/dev/students/205/portal/program").header("Authorization", student()))
            .andExpect(status().isServiceUnavailable()).andExpect(jsonPath("$.code").value("PORTAL_UNAVAILABLE"));
        when(students.summary(205L)).thenThrow(PortalUnavailableException.disabled());
        mvc.perform(get("/api/v1/dev/students/205/portal/summary").header("Authorization", student()))
            .andExpect(status().isServiceUnavailable()).andExpect(jsonPath("$.code").value("PORTAL_DISABLED"));
    }

    @Test
    void ownDataAndCsvExport() throws Exception {
        when(students.summary(205L)).thenReturn(Map.of("cumulativeGpa4", 3.19));
        mvc.perform(get("/api/v1/dev/students/205/portal/summary").header("Authorization", student()))
            .andExpect(status().isOk()).andExpect(jsonPath("$.cumulativeGpa4").value(3.19));
        when(advisor.exportCsv(102L, "ITK99Z", null, null, false, true)).thenReturn("﻿STT\r\n");
        mvc.perform(get("/api/v1/dev/teachers/102/portal/advisor/classes/ITK99Z/export?confirm=true&mask=false")
                .header("Authorization", teacher()))
            .andExpect(status().isOk())
            .andExpect(header().string("Content-Type", org.hamcrest.Matchers.startsWith("text/csv")))
            .andExpect(header().string("Cache-Control", "no-store"));
    }
}
