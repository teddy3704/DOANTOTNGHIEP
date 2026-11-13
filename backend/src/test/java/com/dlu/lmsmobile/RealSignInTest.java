package com.dlu.lmsmobile;

import com.dlu.lmsmobile.config.DataProfile;
import com.dlu.lmsmobile.controller.AuthController;
import com.dlu.lmsmobile.security.JwtTokenProvider;
import com.dlu.lmsmobile.security.LocalDevelopmentSettings;
import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/** REAL-DATA-2: on the real export no sign-in skips the password; the demo profile keeps its demo mode. */
class RealSignInTest {

    static AuthController controller(DataProfile profile, JwtTokenProvider tokens) {
        LocalDevelopmentSettings settings = mock(LocalDevelopmentSettings.class);
        when(settings.studentId()).thenReturn(7L);
        when(settings.teacherId()).thenReturn(9L);
        return new AuthController(tokens, settings, profile);
    }

    @Test
    void realRefusesThePasswordlessDemoLoginForEveryRole() {
        JwtTokenProvider tokens = mock(JwtTokenProvider.class);
        AuthController real = controller(DataProfile.real(), tokens);
        for (String role : new String[]{"STUDENT", "TEACHER"}) {
            var r = real.demoLogin(Map.of("role", role));
            assertEquals(403, r.getStatusCode().value());
            assertEquals("DEMO_LOGIN_DISABLED", r.getBody().get("code"));
            assertFalse(r.getBody().containsKey("token"));
        }
        verifyNoInteractions(tokens);
    }

    @Test
    void demoKeepsItsDemoLogin() {
        JwtTokenProvider tokens = mock(JwtTokenProvider.class);
        when(tokens.generateToken(7L, "STUDENT")).thenReturn("t");
        var r = controller(DataProfile.demo(), tokens).demoLogin(Map.of("role", "STUDENT"));
        assertEquals(200, r.getStatusCode().value());
        assertEquals("t", r.getBody().get("token"));
        assertEquals("demo", r.getBody().get("dataProfile"));
    }
}
