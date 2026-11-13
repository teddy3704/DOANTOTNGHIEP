package com.dlu.lmsmobile.controller;

import com.dlu.lmsmobile.config.DataProfile;
import com.dlu.lmsmobile.exception.InvalidRequestException;
import com.dlu.lmsmobile.security.auth.AuthProvider;
import com.dlu.lmsmobile.security.auth.LoginService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;

/**
 * Sign-in with the student code (MSSV) or username and a password, like the School's LMS. The server decides
 * the role. The legacy demo-login (AuthController) only exists with the local-development flag.
 */
@RestController
@RequestMapping("/api/v1/auth")
public class LoginController {
    static final String FAILED = "Mã số hoặc mật khẩu không đúng";
    private static final int MAX_BODY_BYTES = 2048;
    private static final Set<String> FIELDS = Set.of("login", "password");
    private final LoginService logins;
    private final DataProfile profile;

    public LoginController(LoginService logins, DataProfile profile) {
        this.logins = logins;
        this.profile = profile;
    }

    @PostMapping("/login")
    public Map<String, String> login(@RequestBody Map<String, Object> body, HttpServletRequest request) {
        if (request.getContentLengthLong() > MAX_BODY_BYTES || !FIELDS.equals(body.keySet())
                || !(body.get("login") instanceof String rawLogin) || !(body.get("password") instanceof String password)) {
            throw new InvalidRequestException("Cần đúng hai trường login và password");
        }
        String login = rawLogin.trim();
        if (login.isEmpty() || login.length() > 64 || password.isEmpty() || password.length() > 128) {
            throw new InvalidRequestException("Mã số 1–64 ký tự, mật khẩu 1–128 ký tự");
        }
        // dataProfile tells the app which labels match how the numbers were computed (REAL-DATA-1).
        Map<String, String> out = new LinkedHashMap<>(logins.login(login, password, request.getRemoteAddr()));
        out.put("dataProfile", profile.name());
        return out;
    }

    @ExceptionHandler(LoginService.FailedException.class)
    public ResponseEntity<Map<String, Object>> failed() {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
            .body(Map.of("status", 401, "code", "INVALID_CREDENTIALS", "message", FAILED));
    }

    @ExceptionHandler(LoginService.LockedException.class)
    public ResponseEntity<Map<String, Object>> locked(LoginService.LockedException ex) {
        return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
            .header(HttpHeaders.RETRY_AFTER, Long.toString(ex.retryAfterSeconds()))
            .body(Map.of("status", 429, "code", "LOGIN_LOCKED", "retryAfterSeconds", ex.retryAfterSeconds(),
                "message", "Đăng nhập sai nhiều lần. Vui lòng thử lại sau."));
    }

    @ExceptionHandler(AuthProvider.UnavailableException.class)
    public ResponseEntity<Map<String, Object>> unavailable() {
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
            .body(Map.of("status", 503, "code", "LOGIN_UNAVAILABLE", "message", "Dịch vụ đăng nhập tạm thời không dùng được."));
    }
}
