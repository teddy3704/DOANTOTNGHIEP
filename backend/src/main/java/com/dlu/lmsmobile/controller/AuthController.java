package com.dlu.lmsmobile.controller;

import com.dlu.lmsmobile.exception.InvalidRequestException;
import com.dlu.lmsmobile.security.JwtTokenProvider;
import com.dlu.lmsmobile.security.LocalDevelopmentSettings;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Profile;
import org.springframework.web.bind.annotation.*;

import java.util.Locale;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/auth")
@Profile("local-development")
@ConditionalOnProperty(name = "app.demo-auth.enabled", havingValue = "true")
public class AuthController {
    private final JwtTokenProvider tokenProvider;
    private final LocalDevelopmentSettings settings;

    public AuthController(JwtTokenProvider tokenProvider, LocalDevelopmentSettings settings) {
        this.tokenProvider = tokenProvider;
        this.settings = settings;
    }

    @PostMapping("/demo-login")
    public Map<String, String> demoLogin(@RequestBody Map<String, String> payload) {
        if (payload.size() != 1 || payload.get("role") == null) {
            throw new InvalidRequestException("Supply role only; the server owns demo user IDs");
        }
        String role = payload.get("role").toUpperCase(Locale.ROOT);
        if (!"STUDENT".equals(role) && !"TEACHER".equals(role)) {
            throw new InvalidRequestException("Supported demo roles: STUDENT, TEACHER");
        }
        long userId = "TEACHER".equals(role) ? settings.teacherId() : settings.studentId();
        return Map.of("token", tokenProvider.generateToken(userId, role),
                "role", role, "userId", Long.toString(userId));
    }
}
