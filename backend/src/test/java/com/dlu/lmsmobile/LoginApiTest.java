package com.dlu.lmsmobile;

import com.dlu.lmsmobile.config.DataProfile;
import com.auth0.jwt.interfaces.DecodedJWT;
import com.dlu.lmsmobile.controller.LoginController;
import com.dlu.lmsmobile.controller.StudentWeeklyReportController;
import com.dlu.lmsmobile.security.JwtAuthenticationFilter;
import com.dlu.lmsmobile.security.JwtTokenProvider;
import com.dlu.lmsmobile.security.LocalDevelopmentSettings;
import com.dlu.lmsmobile.security.SecurityConfig;
import com.dlu.lmsmobile.security.auth.AuthConfig;
import com.dlu.lmsmobile.service.WeeklyReportService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.security.servlet.UserDetailsServiceAutoConfiguration;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** Login by student code / username + password: real filter chain, BCrypt accounts, lockout with a fake clock. */
@WebMvcTest(controllers = {LoginController.class, StudentWeeklyReportController.class},
        excludeAutoConfiguration = UserDetailsServiceAutoConfiguration.class,
        properties = {"app.jwt.secret=isolated-test-only-secret-not-for-runtime-1234", "server.address=127.0.0.1"})
@Import({SecurityConfig.class, JwtAuthenticationFilter.class, JwtTokenProvider.class, LocalDevelopmentSettings.class, DataProfile.class,
        AuthConfig.class, LoginApiTest.Clocks.class})
@ExtendWith(OutputCaptureExtension.class)
class LoginApiTest {
    static final String STUDENT_PW = "Sv205-test-only";
    static final String OTHER_PW = "Sv201-test-only";
    static final String TEACHER_PW = "Gv102-test-only";

    @DynamicPropertySource
    static void accounts(DynamicPropertyRegistry r) {
        BCryptPasswordEncoder enc = new BCryptPasswordEncoder(4);   // low cost only to keep the test fast
        r.add("app.auth.local.enabled", () -> "true");
        String[][] users = {{"2312005", "205", "STUDENT", STUDENT_PW}, {"2212001", "201", "STUDENT", OTHER_PW},
            {"teacher02", "102", "TEACHER", TEACHER_PW}};
        for (int i = 0; i < users.length; i++) {
            String p = "app.auth.local.users[" + i + "].";
            String[] u = users[i];
            r.add(p + "login", () -> u[0]);
            r.add(p + "user-id", () -> u[1]);
            r.add(p + "role", () -> u[2]);
            String hash = enc.encode(u[3]);
            r.add(p + "bcrypt", () -> hash);
        }
    }

    /** Clock the test can move forward. */
    static class MutableClock extends Clock {
        Instant now = Instant.parse("2026-11-20T01:00:00Z");
        @Override public ZoneId getZone() { return ZoneId.of("Asia/Ho_Chi_Minh"); }
        @Override public Clock withZone(ZoneId zone) { return this; }
        @Override public Instant instant() { return now; }
    }

    @TestConfiguration
    static class Clocks {
        @Bean MutableClock testClock() { return new MutableClock(); }
    }

    @Autowired MockMvc mvc;
    @Autowired JwtTokenProvider tokens;
    @Autowired MutableClock clock;
    @MockBean WeeklyReportService weeklyReports;
    final ObjectMapper json = new ObjectMapper();

    @BeforeEach
    void resetClock() {
        clock.now = clock.now.plus(Duration.ofHours(1));   // each test starts with no recent failures
    }

    ResultActions login(String login, String password) throws Exception {
        return mvc.perform(post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
            .content(json.writeValueAsString(Map.of("login", login, "password", password))));
    }

    DecodedJWT tokenOf(ResultActions r) throws Exception {
        Map<?, ?> body = json.readValue(r.andReturn().getResponse().getContentAsString(), Map.class);
        return tokens.validateToken((String) body.get("token"));
    }

    @Test
    void studentAndTeacherGetTheirOwnIdentityAndRoleFromTheServer() throws Exception {
        DecodedJWT sv = tokenOf(login(" 2312005 ", STUDENT_PW).andExpect(status().isOk())
            .andExpect(jsonPath("$.role").value("STUDENT")).andExpect(jsonPath("$.userId").value("205"))
            .andExpect(jsonPath("$.dataProfile").value("demo")));
        assertEquals("205", sv.getSubject());
        assertEquals("STUDENT", sv.getClaim("role").asString());
        DecodedJWT gv = tokenOf(login("TEACHER02", TEACHER_PW).andExpect(status().isOk()));
        assertEquals("102", gv.getSubject());
        assertEquals("TEACHER", gv.getClaim("role").asString());
    }

    @Test
    void wrongPasswordAndUnknownAccountGetTheSameAnswer() throws Exception {
        String wrong = login("2312005", "not-the-password").andExpect(status().isUnauthorized())
            .andReturn().getResponse().getContentAsString(java.nio.charset.StandardCharsets.UTF_8);
        String unknown = login("9999999", "not-the-password").andExpect(status().isUnauthorized())
            .andReturn().getResponse().getContentAsString(java.nio.charset.StandardCharsets.UTF_8);
        assertEquals(wrong, unknown);
        assertTrue(wrong.contains("Mã số hoặc mật khẩu không đúng"));
    }

    @Test
    void fiveFailuresLockForFifteenMinutesThenItOpensAgain() throws Exception {
        for (int i = 0; i < 5; i++) login("2212001", "wrong-" + i).andExpect(status().isUnauthorized());
        // Locked even with the right password.
        login("2212001", OTHER_PW).andExpect(status().isTooManyRequests())
            .andExpect(header().string("Retry-After", "900"))
            .andExpect(jsonPath("$.code").value("LOGIN_LOCKED"));
        // Another account from the same address is not affected.
        login("2312005", STUDENT_PW).andExpect(status().isOk());
        clock.now = clock.now.plus(Duration.ofMinutes(15)).plusSeconds(1);
        login("2212001", OTHER_PW).andExpect(status().isOk());
    }

    @Test
    void malformedBodiesAre400() throws Exception {
        mvc.perform(post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON).content("{\"login\":\"2312005\"}"))
            .andExpect(status().isBadRequest());
        mvc.perform(post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content("{\"login\":\"2312005\",\"password\":\"x\",\"role\":\"TEACHER\"}"))
            .andExpect(status().isBadRequest());
        login("x".repeat(65), "pw").andExpect(status().isBadRequest());
        login("2312005", "p".repeat(129)).andExpect(status().isBadRequest());
        login("   ", "pw").andExpect(status().isBadRequest());
        mvc.perform(post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content(json.writeValueAsString(Map.of("login", "2312005", "password", "p", "pad", "z".repeat(3000)))))
            .andExpect(status().isBadRequest());
    }

    @Test
    void logsNeverContainTheLoginOrThePassword(CapturedOutput output) throws Exception {
        login("2312005", STUDENT_PW).andExpect(status().isOk());
        login("2312005", "Secret-wrong-pw").andExpect(status().isUnauthorized());
        String logs = output.getAll();
        assertTrue(logs.contains("login result=OK userId=205"));
        assertTrue(logs.contains("login result=FAIL loginLength=7"));
        assertFalse(logs.contains(STUDENT_PW), "password in logs");
        assertFalse(logs.contains("Secret-wrong-pw"), "wrong password in logs");
        assertFalse(logs.contains("2312005"), "login in logs: " + logs.substring(Math.max(0, logs.indexOf("2312005") - 300), Math.min(logs.length(), logs.indexOf("2312005") + 100)));
    }

    @Test
    void demoLoginDoesNotExistWithoutTheLocalFlag() throws Exception {
        mvc.perform(post("/api/v1/auth/demo-login").contentType(MediaType.APPLICATION_JSON).content("{\"role\":\"STUDENT\"}"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void aTokenFromTheNewLoginStillPassesPathIdentity() throws Exception {
        DecodedJWT other = tokenOf(login("2212001", OTHER_PW).andExpect(status().isOk()));
        String bearer = "Bearer " + other.getToken();
        mvc.perform(get("/api/v1/dev/students/205/weekly-report").header("Authorization", bearer))
            .andExpect(status().isForbidden());
        mvc.perform(get("/api/v1/dev/students/201/weekly-report").header("Authorization", bearer))
            .andExpect(status().isOk());
    }
}
