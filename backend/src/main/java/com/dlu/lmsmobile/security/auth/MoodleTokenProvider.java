package com.dlu.lmsmobile.security.auth;

import org.springframework.http.MediaType;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.util.Map;
import java.util.Optional;
import java.util.function.LongFunction;

/**
 * Login against the School's Moodle, the same way the official Moodle app does:
 * 1. POST {lms}/login/token.php (username, password, service=moodle_mobile_app) -> {token} or {error, errorcode};
 * 2. POST {lms}/webservice/rest/server.php wsfunction=core_webservice_get_site_info -> {userid, username}.
 * The role is then decided by the server from LMS data (teacher of at least one course -> TEACHER).
 * OFF by default (app.auth.moodle.enabled=false) and only exercised with a mocked server in tests:
 * it must not be pointed at lms.dlu.edu.vn without the School's written permission.
 * The Moodle token is used once to identify the user and is never stored or returned to the app.
 */
public class MoodleTokenProvider implements AuthProvider {
    private final RestClient rest;
    private final String service;
    private final LongFunction<String> roleOf;

    public MoodleTokenProvider(RestClient rest, String service, LongFunction<String> roleOf) {
        this.rest = rest;
        this.service = service;
        this.roleOf = roleOf;
    }

    @Override
    public Optional<AuthenticatedUser> authenticate(String login, String password) {
        Map<?, ?> token = post("/login/token.php", form("username", login, "password", password, "service", service));
        Object value = token.get("token");
        if (!(value instanceof String moodleToken) || moodleToken.isBlank()) {
            String code = String.valueOf(token.get("errorcode"));
            if ("invalidlogin".equals(code)) return Optional.empty();
            // e.g. enablewsdescription / servicenotavailable: the LMS does not offer the mobile service.
            throw new UnavailableException("LMS login service unavailable: " + code);
        }
        Map<?, ?> info = post("/webservice/rest/server.php", form("wstoken", moodleToken,
            "wsfunction", "core_webservice_get_site_info", "moodlewsrestformat", "json"));
        if (!(info.get("userid") instanceof Number id) || id.longValue() <= 0) {
            throw new UnavailableException("LMS site info without a user id");
        }
        return Optional.of(new AuthenticatedUser(id.longValue(), roleOf.apply(id.longValue())));
    }

    private Map<?, ?> post(String path, MultiValueMap<String, String> body) {
        try {
            Map<?, ?> map = rest.post().uri(path).contentType(MediaType.APPLICATION_FORM_URLENCODED)
                .body(body).retrieve().body(Map.class);
            if (map == null) throw new UnavailableException("Empty LMS response");
            return map;
        } catch (RestClientException e) {
            throw new UnavailableException("LMS not reachable");
        }
    }

    private static MultiValueMap<String, String> form(String... pairs) {
        MultiValueMap<String, String> m = new LinkedMultiValueMap<>();
        for (int i = 0; i < pairs.length; i += 2) m.add(pairs[i], pairs[i + 1]);
        return m;
    }
}
