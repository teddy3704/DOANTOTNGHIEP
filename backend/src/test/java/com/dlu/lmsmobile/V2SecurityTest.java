package com.dlu.lmsmobile;

import com.dlu.lmsmobile.config.DataProfile;
import com.dlu.lmsmobile.controller.*;
import com.dlu.lmsmobile.exception.InvalidRequestException;
import com.dlu.lmsmobile.exception.ResourceNotFoundException;
import com.dlu.lmsmobile.security.*;
import com.dlu.lmsmobile.service.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.security.servlet.UserDetailsServiceAutoConfiguration;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Map;

import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** V2 endpoints behind the real filter chain: 401 anonymous, 403 other identity, 404 not enrolled/roster. */
@WebMvcTest(controllers = {StudentForecastController.class, StudentHealthController.class,
        StudentRecommendationController.class, TeacherForecastController.class,
        StudentFlashcardReviewController.class, StudentStudyPlanController.class,
        StudentNotificationPreferenceController.class, StudentStudySessionController.class,
        TeacherQuizInsightsController.class, StudentCalendarController.class,
        SearchController.class, StudentWeeklyReportController.class,
        StudentAchievementController.class},
        excludeAutoConfiguration = UserDetailsServiceAutoConfiguration.class,
        properties = {"app.jwt.secret=isolated-test-only-secret-not-for-runtime-1234",
                "app.demo-auth.enabled=true", "app.demo-auth.student-id=205",
                "app.demo-auth.teacher-id=102", "server.address=127.0.0.1"})
@ActiveProfiles("local-development")
@Import({SecurityConfig.class, JwtAuthenticationFilter.class, JwtTokenProvider.class, LocalDevelopmentSettings.class, DataProfile.class})
class V2SecurityTest {
    @Autowired MockMvc mvc;
    @Autowired JwtTokenProvider tokens;
    @MockBean GradeForecastService forecasts;
    @MockBean LearningHealthService health;
    @MockBean StudyRecommendationService recommendations;
    @MockBean PeerComparisonService peers;
    @MockBean FlashcardReviewService reviews;
    @MockBean StudyPlanService studyPlans;
    @MockBean NotificationPreferenceService notificationPrefs;
    @MockBean StudySessionService studySessions;
    @MockBean QuizInsightsService quizInsights;
    @MockBean StudentCalendarService calendar;
    @MockBean SearchService search;
    @MockBean WeeklyReportService weeklyReports;
    @MockBean AchievementService achievements;

    private String student() {
        return "Bearer " + tokens.generateToken(205L, "STUDENT");
    }

    private String teacher() {
        return "Bearer " + tokens.generateToken(102L, "TEACHER");
    }

    static final String[] STUDENT_PATHS = {
        "/api/v1/dev/students/205/courses/13/grade-forecast",
        "/api/v1/dev/students/205/learning-health",
        "/api/v1/dev/students/205/courses/13/learning-health",
        "/api/v1/dev/students/205/courses/13/study-recommendations",
        "/api/v1/dev/students/205/study-recommendations?limit=3",
        "/api/v1/dev/students/205/courses/13/peer-comparison",
        "/api/v1/dev/students/205/flashcards/due",
        "/api/v1/dev/students/205/flashcards/due?courseId=13",
        "/api/v1/dev/students/205/study-plan?from=2026-11-16&to=2026-11-22",
        "/api/v1/dev/students/205/notification-preferences",
        "/api/v1/dev/students/205/study-sessions/summary",
        "/api/v1/dev/students/205/calendar?from=2026-11-01&to=2026-11-30",
        "/api/v1/dev/students/205/search?q=kiem",
        "/api/v1/dev/students/205/weekly-report",
        "/api/v1/dev/students/205/achievements",
    };

    @Test
    void anonymousIsUnauthorized() throws Exception {
        for (String p : STUDENT_PATHS) mvc.perform(get(p)).andExpect(status().isUnauthorized());
        verifyNoInteractions(forecasts, health, recommendations, peers, reviews, studyPlans, notificationPrefs, studySessions, calendar, search, weeklyReports, achievements);
    }

    @Test
    void otherStudentOrTeacherTokenIsForbidden() throws Exception {
        for (String p : STUDENT_PATHS) {
            mvc.perform(get(p.replace("/205/", "/206/")).header("Authorization", student()))
                .andExpect(status().isForbidden());
            mvc.perform(get(p).header("Authorization", teacher())).andExpect(status().isForbidden());
        }
        verifyNoInteractions(forecasts, health, recommendations, peers, reviews, studyPlans, notificationPrefs, studySessions, calendar, search, weeklyReports, achievements);
    }

    @Test
    void notEnrolledIsNotFound() throws Exception {
        when(forecasts.studentForecast(205L, 99L)).thenThrow(new ResourceNotFoundException("Student course not found"));
        mvc.perform(get("/api/v1/dev/students/205/courses/99/grade-forecast").header("Authorization", student()))
            .andExpect(status().isNotFound());
    }

    @Test
    void learningHealthOfUnenrolledCourseIsNotFound() throws Exception {
        when(health.forCourse(205L, 99L)).thenThrow(new ResourceNotFoundException("Student course not found"));
        mvc.perform(get("/api/v1/dev/students/205/courses/99/learning-health").header("Authorization", student()))
            .andExpect(status().isNotFound());
    }

    @Test
    void recommendationsOfUnenrolledCourseAreNotFound() throws Exception {
        when(recommendations.forCourse(205L, 99L)).thenThrow(new ResourceNotFoundException("Student course not found"));
        mvc.perform(get("/api/v1/dev/students/205/courses/99/study-recommendations").header("Authorization", student()))
            .andExpect(status().isNotFound());
    }

    static final String[] TEACHER_PATHS = {
        "/api/v1/dev/teachers/102/courses/13/grade-forecast",
        "/api/v1/dev/teachers/102/courses/13/quiz-insights",
        "/api/v1/dev/teachers/102/search?q=nguyen",
    };

    @Test
    void teacherEndpointsRejectAnonymousOtherTeacherAndStudent() throws Exception {
        for (String p : TEACHER_PATHS) {
            mvc.perform(get(p)).andExpect(status().isUnauthorized());
            mvc.perform(get(p.replace("/102/", "/103/")).header("Authorization", teacher()))
                .andExpect(status().isForbidden());
            mvc.perform(get(p).header("Authorization", student())).andExpect(status().isForbidden());
        }
        verifyNoInteractions(forecasts, quizInsights, search);
    }

    @Test
    void teacherCourseNotOwnedIsNotFound() throws Exception {
        when(forecasts.teacherForecast(102L, 99L)).thenThrow(new ResourceNotFoundException("Teacher course not found"));
        mvc.perform(get("/api/v1/dev/teachers/102/courses/99/grade-forecast").header("Authorization", teacher()))
            .andExpect(status().isNotFound());
        when(forecasts.teacherForecast(102L, 13L)).thenReturn(Map.of("passPercent", 50.0));
        mvc.perform(get("/api/v1/dev/teachers/102/courses/13/grade-forecast").header("Authorization", teacher()))
            .andExpect(status().isOk()).andExpect(jsonPath("$.passPercent").value(50.0));
    }

    @Test
    void peerComparisonOfUnenrolledCourseIsNotFound() throws Exception {
        when(peers.compare(205L, 99L)).thenThrow(new ResourceNotFoundException("Student course not found"));
        mvc.perform(get("/api/v1/dev/students/205/courses/99/peer-comparison").header("Authorization", student()))
            .andExpect(status().isNotFound());
    }

    @Test
    void ownCourseIsAvailable() throws Exception {
        when(forecasts.studentForecast(205L, 13L)).thenReturn(Map.of("current", 64.0));
        mvc.perform(get("/api/v1/dev/students/205/courses/13/grade-forecast").header("Authorization", student()))
            .andExpect(status().isOk()).andExpect(jsonPath("$.current").value(64.0));
    }

    static final String REVIEW = "/api/v1/dev/students/205/courses/13/flashcards/7/review";

    @Test
    void flashcardReviewRejectsAnonymousOtherStudentAndTeacher() throws Exception {
        String body = "{\"rating\":4}";
        mvc.perform(post(REVIEW).contentType(MediaType.APPLICATION_JSON).content(body))
            .andExpect(status().isUnauthorized());
        mvc.perform(post(REVIEW.replace("/205/", "/206/")).header("Authorization", student())
                .contentType(MediaType.APPLICATION_JSON).content(body)).andExpect(status().isForbidden());
        mvc.perform(post(REVIEW).header("Authorization", teacher())
                .contentType(MediaType.APPLICATION_JSON).content(body)).andExpect(status().isForbidden());
        verifyNoInteractions(reviews);
    }

    @Test
    void flashcardReviewOfUnenrolledCourseOrForeignCardIsNotFound() throws Exception {
        when(reviews.review(205L, 99L, 7L, 4)).thenThrow(new ResourceNotFoundException("Student course not found"));
        mvc.perform(post(REVIEW.replace("/13/", "/99/")).header("Authorization", student())
                .contentType(MediaType.APPLICATION_JSON).content("{\"rating\":4}")).andExpect(status().isNotFound());
        when(reviews.review(205L, 13L, 8L, 4)).thenThrow(new ResourceNotFoundException("Flashcard not found"));
        mvc.perform(post(REVIEW.replace("/7/", "/8/")).header("Authorization", student())
                .contentType(MediaType.APPLICATION_JSON).content("{\"rating\":4}")).andExpect(status().isNotFound());
        when(reviews.due(205L, 99L)).thenThrow(new ResourceNotFoundException("Student course not found"));
        mvc.perform(get("/api/v1/dev/students/205/flashcards/due?courseId=99").header("Authorization", student()))
            .andExpect(status().isNotFound());
    }

    @Test
    void ownFlashcardReviewIsAccepted() throws Exception {
        when(reviews.review(205L, 13L, 7L, 4)).thenReturn(Map.of("intervalDays", 6));
        mvc.perform(post(REVIEW).header("Authorization", student())
                .contentType(MediaType.APPLICATION_JSON).content("{\"rating\":4}"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.intervalDays").value(6));
    }

    @Test
    void studyPlanWritesRejectAnonymousOtherStudentAndTeacher() throws Exception {
        String gen = "/api/v1/dev/students/205/study-plan/generate";
        String st = "/api/v1/dev/students/205/study-plan/items/9/status";
        mvc.perform(post(gen).contentType(MediaType.APPLICATION_JSON).content("{\"dailyMinutes\":60}"))
            .andExpect(status().isUnauthorized());
        mvc.perform(post(gen.replace("/205/", "/206/")).header("Authorization", student())
            .contentType(MediaType.APPLICATION_JSON).content("{\"dailyMinutes\":60}")).andExpect(status().isForbidden());
        mvc.perform(put(st).header("Authorization", teacher())
            .contentType(MediaType.APPLICATION_JSON).content("{\"status\":\"done\"}")).andExpect(status().isForbidden());
        verifyNoInteractions(studyPlans);
    }

    @Test
    void studyPlanItemOfAnotherStudentIsNotFound() throws Exception {
        when(studyPlans.setStatus(205L, 9L, "done")).thenThrow(new ResourceNotFoundException("Plan item not found"));
        mvc.perform(put("/api/v1/dev/students/205/study-plan/items/9/status").header("Authorization", student())
            .contentType(MediaType.APPLICATION_JSON).content("{\"status\":\"done\"}")).andExpect(status().isNotFound());
        when(studyPlans.generate(205L, 60)).thenReturn(Map.of("dailyMinutes", 60));
        mvc.perform(post("/api/v1/dev/students/205/study-plan/generate").header("Authorization", student())
            .contentType(MediaType.APPLICATION_JSON).content("{\"dailyMinutes\":60}"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.dailyMinutes").value(60));
    }

    @Test
    void notificationPreferencesWriteOnlyOwnRow() throws Exception {
        String p = "/api/v1/dev/students/205/notification-preferences";
        String body = "{\"reminderBeforeHours\":6}";
        mvc.perform(put(p).contentType(MediaType.APPLICATION_JSON).content(body)).andExpect(status().isUnauthorized());
        mvc.perform(put(p.replace("/205/", "/206/")).header("Authorization", student())
            .contentType(MediaType.APPLICATION_JSON).content(body)).andExpect(status().isForbidden());
        mvc.perform(put(p).header("Authorization", teacher())
            .contentType(MediaType.APPLICATION_JSON).content(body)).andExpect(status().isForbidden());
        verifyNoInteractions(notificationPrefs);
        when(notificationPrefs.put(eq(205L), anyMap())).thenReturn(Map.of("reminderBeforeHours", 6));
        mvc.perform(put(p).header("Authorization", student())
            .contentType(MediaType.APPLICATION_JSON).content(body))
            .andExpect(status().isOk()).andExpect(jsonPath("$.reminderBeforeHours").value(6));
        when(notificationPrefs.put(eq(205L), anyMap())).thenThrow(new InvalidRequestException("bad"));
        mvc.perform(put(p).header("Authorization", student())
            .contentType(MediaType.APPLICATION_JSON).content("{\"reminderBeforeHours\":-1}"))
            .andExpect(status().isBadRequest());
    }

    @Test
    void studySessionWritesAreOwnAndEnrolledOnly() throws Exception {
        String p = "/api/v1/dev/students/205/study-sessions";
        String body = "{\"startedAt\":\"2026-11-18T09:35:00+07:00\",\"endedAt\":\"2026-11-18T10:00:00+07:00\","
            + "\"focusMinutes\":25,\"courseId\":99}";
        mvc.perform(post(p).contentType(MediaType.APPLICATION_JSON).content(body)).andExpect(status().isUnauthorized());
        mvc.perform(post(p.replace("/205/", "/206/")).header("Authorization", student())
            .contentType(MediaType.APPLICATION_JSON).content(body)).andExpect(status().isForbidden());
        mvc.perform(post(p).header("Authorization", teacher())
            .contentType(MediaType.APPLICATION_JSON).content(body)).andExpect(status().isForbidden());
        verifyNoInteractions(studySessions);
        when(studySessions.record(eq(205L), anyMap())).thenThrow(new ResourceNotFoundException("Course not found"));
        mvc.perform(post(p).header("Authorization", student())
            .contentType(MediaType.APPLICATION_JSON).content(body)).andExpect(status().isNotFound());
    }

    @Test
    void quizInsightsOfAnotherTeachersCourseIsNotFound() throws Exception {
        when(quizInsights.insights(102L, 99L)).thenThrow(new ResourceNotFoundException("Teacher course not found"));
        mvc.perform(get("/api/v1/dev/teachers/102/courses/99/quiz-insights").header("Authorization", teacher()))
            .andExpect(status().isNotFound());
        when(quizInsights.insights(102L, 13L)).thenReturn(Map.of("courseId", 13));
        mvc.perform(get("/api/v1/dev/teachers/102/courses/13/quiz-insights").header("Authorization", teacher()))
            .andExpect(status().isOk()).andExpect(jsonPath("$.courseId").value(13));
    }
}
