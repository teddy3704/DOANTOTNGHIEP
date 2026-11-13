package com.dlu.lmsmobile.config;

import com.dlu.lmsmobile.security.JwtTokenProvider;
import com.dlu.lmsmobile.security.auth.AuthProperties;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * REAL-DATA-2: warms {@link RealResponseCache} after start-up on the real profile, for the accounts in
 * the local sign-in list (app.auth.local.users). It signs a short internal token for each account
 * itself and calls its own GET endpoints over loopback; this is not a sign-in path (no endpoint, no
 * password check skipped for any client). Logs counts only. Off on the demo profile.
 */
@Component
public class RealCacheWarmer {
    private static final Logger log = LoggerFactory.getLogger(RealCacheWarmer.class);

    private final boolean on;
    private final AuthProperties auth;
    private final JwtTokenProvider tokens;
    private final int port;
    private final List<Long> teacherCourses;
    private final AtomicInteger ok = new AtomicInteger();
    private final AtomicInteger failed = new AtomicInteger();
    private volatile boolean done;

    public RealCacheWarmer(@Value("${app.data-profile:demo}") String profile, AuthProperties auth, JwtTokenProvider tokens,
                           @Value("${server.port:8081}") int port,
                           @Value("${app.real-warm.teacher-courses:13698,13429,12534,12918}") List<Long> teacherCourses) {
        this.on = new DataProfile(profile).handInsOnly();
        this.auth = auth;
        this.tokens = tokens;
        this.port = port;
        this.teacherCourses = teacherCourses;
    }

    /** "ok/failed, done|running" for /health; null when off. */
    public String status() {
        return on ? ok.get() + "/" + failed.get() + (done ? " done" : " running") : null;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void onReady() {
        if (!on || auth.getLocal().getUsers().isEmpty()) return;
        Thread t = new Thread(this::run, "real-cache-warm");
        t.setDaemon(true);
        t.start();
    }

    void run() {
        long start = System.currentTimeMillis();
        HttpClient http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();
        ObjectMapper json = new ObjectMapper();
        String base = "http://127.0.0.1:" + port + "/api/v1";
        for (AuthProperties.Account a : auth.getLocal().getUsers()) {
            String role = a.getRole() == null ? "" : a.getRole().trim().toUpperCase();
            String token = tokens.generateToken(a.getUserId(), role);
            List<String> paths = new ArrayList<>();
            if ("STUDENT".equals(role)) {
                String s = "/dev/students/" + a.getUserId();
                paths.add(s + "/study-recommendations?limit=3");
                paths.add(s + "/learning-health");
                JsonNode courses = get(http, json, base + s + "/courses", token);
                if (courses != null) {
                    for (JsonNode c : courses) {
                        long id = c.path("courseid").asLong();
                        for (String p : List.of("grade-forecast", "peer-comparison", "study-recommendations")) {
                            paths.add(s + "/courses/" + id + "/" + p);
                        }
                    }
                }
            } else if ("TEACHER".equals(role)) {
                String t = "/dev/teachers/" + a.getUserId();
                paths.add(t + "/courses");
                for (Long c : teacherCourses) {
                    for (String p : List.of("class-insights?weeks=8", "grade-forecast", "quiz-insights", "engagement-heatmap")) {
                        paths.add(t + "/courses/" + c + "/" + p);
                    }
                }
            }
            for (String p : paths) {
                if (get(http, json, base + p, token) != null) ok.incrementAndGet();
                else failed.incrementAndGet();
            }
        }
        done = true;
        log.info("real cache warm: ok={} failed={} ms={}", ok.get(), failed.get(), System.currentTimeMillis() - start);
    }

    private static JsonNode get(HttpClient http, ObjectMapper json, String url, String token) {
        try {
            HttpRequest req = HttpRequest.newBuilder(URI.create(url)).timeout(Duration.ofSeconds(60))
                .header("Authorization", "Bearer " + token).GET().build();
            HttpResponse<String> r = http.send(req, HttpResponse.BodyHandlers.ofString());
            return r.statusCode() == 200 ? json.readTree(r.body()) : null;
        } catch (Exception e) {
            if (e instanceof InterruptedException) Thread.currentThread().interrupt();
            return null;
        }
    }
}
