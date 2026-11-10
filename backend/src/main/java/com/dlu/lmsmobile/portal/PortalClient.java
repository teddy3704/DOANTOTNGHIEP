package com.dlu.lmsmobile.portal;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.JsonNodeFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestClientResponseException;

import java.time.Clock;
import java.time.Instant;
import java.util.Iterator;
import java.util.Map;
import java.util.TreeMap;
import java.util.function.LongConsumer;

/**
 * V3-P0: the only code that talks to the DLU training portal. Read-only POST calls with
 * X-API-KEY; envelope {status, ok, body}. Responses are cached in memory only.
 * Logs endpoint, HTTP status, duration and record count — never the key, a request body or a
 * response body (docs/V3_PORTAL_PROMPT.md §2.1, §2.5).
 */
public class PortalClient {
    public static final String CLASS_STUDENTS = "/api/v1/LayDanhSachSinhVienTheoLop";
    public static final String CLASS_GRADES = "/api/v1/LayBangDiemSinhVienTheoLop";
    public static final String CLASS_CONDUCT = "/api/v1/LayBangDiemRenLuyenTheoLop";
    public static final String STUDENT_TRANSCRIPT = "/api/v1/LayBangDiemSinhVien";
    public static final String PROGRAM_COURSES = "/api/v1/LayDanhSachHocPhanTheoCTDT";
    public static final String DECISIONS = "/api/v1/LayDanhSachQuyetDinh";
    static final long RETRY_BACKOFF_MS = 500;

    private static final Logger log = LoggerFactory.getLogger(PortalClient.class);
    private static final ObjectMapper JSON = new ObjectMapper();

    public enum Health { UP, DOWN, DISABLED }

    private final PortalProperties props;
    private final RestClient rest;
    private final Clock clock;
    private final LongConsumer sleeper;
    private final PortalCache<JsonNode> cache;
    private final PortalCache<Health> healthCache;
    private volatile Instant lastSuccess;

    public PortalClient(PortalProperties props, RestClient rest, Clock clock) {
        this(props, rest, clock, PortalClient::sleep);
    }

    PortalClient(PortalProperties props, RestClient rest, Clock clock, LongConsumer sleeper) {
        this.props = props;
        this.rest = rest;
        this.clock = clock;
        this.sleeper = sleeper;
        this.cache = new PortalCache<>(props.getCacheTtl(), props.getCacheMaxEntries(), clock);
        this.healthCache = new PortalCache<>(props.getHealthTtl(), 1, clock);
    }

    public boolean configured() {
        return props.configured();
    }

    public PortalProperties properties() {
        return props;
    }

    /** Time of the last successful business call (P7), or null. */
    public Instant lastSuccess() {
        return lastSuccess;
    }

    // ------------------------------------------------------------ endpoints (body only)
    public JsonNode classStudents(String classId) {
        return call(CLASS_STUDENTS, Map.of("Id", classId));
    }

    public JsonNode classGrades(String yearStudy, String termId, String classId) {
        return call(CLASS_GRADES, Map.of("YearStudy", yearStudy, "TermId", termId, "Id", classId));
    }

    public JsonNode classConduct(String yearStudy, String termId, String classId) {
        return call(CLASS_CONDUCT, Map.of("YearStudy", yearStudy, "TermId", termId, "Id", classId));
    }

    public JsonNode studentTranscript(String studentId, String studyProgramId) {
        return call(STUDENT_TRANSCRIPT, Map.of("p1", studentId, "p2", studyProgramId, "p3", "ALL", "p4", "ALL"));
    }

    public JsonNode programCourses(String studyProgramId) {
        return call(PROGRAM_COURSES, Map.of("p1", studyProgramId));
    }

    public JsonNode decisions(String studentId) {
        return call(DECISIONS, Map.of("p1", studentId));
    }

    /** True when this exact call is in the cache (E2 measurements, P7). */
    public boolean isCached(String endpoint, Map<String, String> body) {
        return cache.contains(key(endpoint, body));
    }

    // ------------------------------------------------------------ core
    JsonNode call(String endpoint, Map<String, String> body) {
        if (!props.configured()) throw PortalUnavailableException.disabled();
        return cache.get(key(endpoint, body), () -> fetch(endpoint, body));
    }

    private static String key(String endpoint, Map<String, String> body) {
        return endpoint + '|' + new TreeMap<>(body);
    }

    private JsonNode fetch(String endpoint, Map<String, String> body) {
        for (int attempt = 1; ; attempt++) {
            long start = System.nanoTime();
            try {
                String raw = rest.post().uri(endpoint)
                    .header("X-API-KEY", props.getApiKey())
                    .contentType(MediaType.APPLICATION_JSON)
                    .accept(MediaType.APPLICATION_JSON)
                    .body(body)
                    .retrieve()
                    .body(String.class);
                JsonNode result = unwrap(raw);
                log.info("portal {} status=200 ms={} records={}", endpoint, ms(start), count(result));
                lastSuccess = clock.instant();
                return result;
            } catch (HttpServerErrorException e) {
                log.warn("portal {} status={} ms={} attempt={}", endpoint, e.getStatusCode().value(), ms(start), attempt);
                if (attempt >= 2) throw PortalUnavailableException.unavailable();
            } catch (ResourceAccessException e) {
                log.warn("portal {} status=IO_ERROR ms={} attempt={}", endpoint, ms(start), attempt);
                if (attempt >= 2) throw PortalUnavailableException.unavailable();
            } catch (RestClientResponseException e) {
                log.warn("portal {} status={} ms={}", endpoint, e.getStatusCode().value(), ms(start));
                throw PortalUnavailableException.unavailable();
            } catch (RestClientException e) {
                log.warn("portal {} status=CLIENT_ERROR ms={}", endpoint, ms(start));
                throw PortalUnavailableException.unavailable();
            } catch (PortalUnavailableException e) {
                log.warn("portal {} status=200 ms={} envelope=INVALID", endpoint, ms(start));
                throw e;
            }
            sleeper.accept(RETRY_BACKOFF_MS);
        }
    }

    /** Envelope must be an object with ok=true; returns body (null body → empty array). */
    static JsonNode unwrap(String raw) {
        JsonNode root;
        try {
            root = raw == null ? null : JSON.readTree(raw);
        } catch (Exception e) {
            throw PortalUnavailableException.unavailable();
        }
        if (root == null || !root.isObject() || !root.path("ok").asBoolean(false)) {
            throw PortalUnavailableException.unavailable();
        }
        JsonNode body = root.get("body");
        return body == null || body.isNull() ? JsonNodeFactory.instance.arrayNode() : body;
    }

    /** Array size; for an object, the size of its largest array field (e.g. tbStudyPrograms); scalar 1. */
    static int count(JsonNode n) {
        if (n == null || n.isNull()) return 0;
        if (n.isArray()) return n.size();
        if (n.isObject()) {
            int max = -1;
            for (Iterator<JsonNode> it = n.elements(); it.hasNext(); ) {
                JsonNode c = it.next();
                if (c.isArray()) max = Math.max(max, c.size());
            }
            if (max >= 0) return max;
        }
        return 1;
    }

    // ------------------------------------------------------------ health
    public Health health() {
        if (!props.configured()) return Health.DISABLED;
        return healthCache.get("health", () -> {
            long start = System.nanoTime();
            try {
                String raw = rest.get().uri("/health").accept(MediaType.APPLICATION_JSON).retrieve().body(String.class);
                JsonNode n = raw == null ? null : JSON.readTree(raw);
                boolean up = n != null && "ok".equalsIgnoreCase(n.path("app").asText());
                log.info("portal /health status=200 ms={} up={}", ms(start), up);
                return up ? Health.UP : Health.DOWN;
            } catch (Exception e) {
                log.warn("portal /health status=DOWN ms={}", ms(start));
                return Health.DOWN;
            }
        });
    }

    private static long ms(long startNanos) {
        return (System.nanoTime() - startNanos) / 1_000_000;
    }

    private static void sleep(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
