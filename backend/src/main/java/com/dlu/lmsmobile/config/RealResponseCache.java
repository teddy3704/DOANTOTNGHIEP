package com.dlu.lmsmobile.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.util.ContentCachingResponseWrapper;

import java.io.IOException;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.regex.Pattern;

/**
 * REAL-DATA-2: in-memory cache for the heavy read models on the real export, whose LMS rows never
 * change after the import. Only GET requests of the paths below are cached; app-owned rows (notes,
 * goals) only change through this backend and any write (POST/PUT/PATCH/DELETE) clears the whole
 * cache, so no answer goes stale. It runs after the Spring Security chain (default filter order), so a
 * request for another user's path is rejected before it can reach a cached answer. Off on the demo
 * profile. Warmed by tools/Start-Demo.ps1.
 */
@Component
public class RealResponseCache extends OncePerRequestFilter {
    static final List<Pattern> CACHED = List.of(
        Pattern.compile("^/api/v1/dev/students/\\d+/study-recommendations$"),
        Pattern.compile("^/api/v1/dev/students/\\d+/courses/\\d+/study-recommendations$"),
        Pattern.compile("^/api/v1/dev/students/\\d+/learning-health$"),
        Pattern.compile("^/api/v1/dev/students/\\d+/courses/\\d+/grade-forecast$"),
        Pattern.compile("^/api/v1/dev/students/\\d+/courses/\\d+/peer-comparison$"),
        Pattern.compile("^/api/v1/dev/teachers/\\d+/courses$"),
        Pattern.compile("^/api/v1/dev/teachers/\\d+/courses/\\d+/(engagement-heatmap|grade-forecast|quiz-insights|class-insights)$"));
    static final Duration TTL = Duration.ofHours(6);

    record Entry(byte[] body, String contentType, long at) {
    }

    private final boolean on;
    private final Map<String, Entry> cache = new ConcurrentHashMap<>();

    public RealResponseCache(@Value("${app.data-profile:demo}") String profile) {
        this.on = new DataProfile(profile).handInsOnly();
    }

    static boolean cacheable(String path) {
        return path != null && CACHED.stream().anyMatch(p -> p.matcher(path).matches());
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !on;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String method = request.getMethod();
        if (!"GET".equals(method)) {
            chain.doFilter(request, response);
            if (!"OPTIONS".equals(method) && !"HEAD".equals(method)) cache.clear();
            return;
        }
        String path = request.getRequestURI();
        if (!cacheable(path)) {
            chain.doFilter(request, response);
            return;
        }
        String key = path + "?" + (request.getQueryString() == null ? "" : request.getQueryString());
        Entry hit = cache.get(key);
        if (hit != null && System.currentTimeMillis() - hit.at() < TTL.toMillis()) {
            response.setStatus(200);
            if (hit.contentType() != null) response.setContentType(hit.contentType());
            response.setHeader("X-Real-Cache", "HIT");
            response.setContentLength(hit.body().length);
            response.getOutputStream().write(hit.body());
            return;
        }
        ContentCachingResponseWrapper wrapper = new ContentCachingResponseWrapper(response);
        chain.doFilter(request, wrapper);
        if (wrapper.getStatus() == 200) {
            cache.put(key, new Entry(wrapper.getContentAsByteArray(), wrapper.getContentType(), System.currentTimeMillis()));
        }
        wrapper.copyBodyToResponse();
    }

    int size() { return cache.size(); }
}
