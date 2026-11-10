package com.dlu.lmsmobile.portal;

import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.ExpectedCount;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

import java.io.IOException;
import java.net.SocketTimeoutException;
import java.time.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.*;
import static org.springframework.test.web.client.response.MockRestResponseCreators.*;

/** V3-P0 client: header, envelope, retry, cache, health and log hygiene. Fixtures are invented. */
class PortalClientTest {
    static final String BASE = "https://portal.test";
    static final String KEY = "test-key-NOT-REAL-9f3a";
    static final String FAKE_MSSV = "2399Z001";
    static final String SECRET_BODY_MARKER = "Nguyen Van A";
    static final String TRANSCRIPT = "{\"status\":200,\"ok\":true,\"body\":[{\"NamHoc\":\"2099-2100\",\"StudentName\":\""
        + SECRET_BODY_MARKER + "\",\"DanhSachDiem\":[]}]}";

    MockRestServiceServer server;
    PortalProperties props;
    PortalClient client;
    MutableClock clock;
    List<Long> sleeps;
    ListAppender<ILoggingEvent> logs;
    Level previousLevel;

    static class MutableClock extends Clock {
        Instant now = Instant.parse("2099-01-01T00:00:00Z");

        @Override public ZoneId getZone() { return ZoneOffset.UTC; }
        @Override public Clock withZone(ZoneId zone) { return this; }
        @Override public Instant instant() { return now; }
    }

    @BeforeEach
    void setup() {
        props = new PortalProperties();
        props.setEnabled(true);
        props.setBaseUrl(BASE);
        props.setApiKey(KEY);
        clock = new MutableClock();
        sleeps = new ArrayList<>();
        RestClient.Builder builder = RestClient.builder().baseUrl(BASE);
        server = MockRestServiceServer.bindTo(builder).build();
        client = new PortalClient(props, builder.build(), clock, sleeps::add);
        logs = new ListAppender<>();
        logs.start();
        rootLogger().addAppender(logs);
        // DEBUG on purpose: even Spring's HTTP debug output must not carry the key or bodies.
        previousLevel = rootLogger().getLevel();
        rootLogger().setLevel(Level.DEBUG);
    }

    @AfterEach
    void tearDown() {
        rootLogger().detachAppender(logs);
        rootLogger().setLevel(previousLevel);
        String all = String.join("\n", logs.list.stream().map(ILoggingEvent::getFormattedMessage).toList());
        assertFalse(all.contains(KEY), "API key leaked into logs");
        assertFalse(all.contains(SECRET_BODY_MARKER), "response body leaked into logs");
        assertFalse(all.contains(FAKE_MSSV), "request body leaked into logs");
    }

    private static Logger rootLogger() {
        return (Logger) LoggerFactory.getLogger(org.slf4j.Logger.ROOT_LOGGER_NAME);
    }

    private void expectTranscript(ExpectedCount count) {
        server.expect(count, requestTo(BASE + PortalClient.STUDENT_TRANSCRIPT))
            .andExpect(method(HttpMethod.POST))
            .andExpect(header("X-API-KEY", KEY))
            .andExpect(content().json("{\"p1\":\"" + FAKE_MSSV + "\",\"p2\":\"CQ99CT\",\"p3\":\"ALL\",\"p4\":\"ALL\"}"))
            .andRespond(withSuccess(TRANSCRIPT, MediaType.APPLICATION_JSON));
    }

    @Test
    void sendsKeyHeaderAndReturnsBody() {
        expectTranscript(ExpectedCount.once());
        JsonNode body = client.studentTranscript(FAKE_MSSV, "CQ99CT");
        assertEquals(1, body.size());
        assertEquals("2099-2100", body.get(0).get("NamHoc").asText());
        assertNotNull(client.lastSuccess());
        server.verify();
        String all = logs.list.stream().map(ILoggingEvent::getFormattedMessage).reduce("", String::concat);
        assertTrue(all.contains("records=1"), all);
    }

    @Test
    void withoutKeyPortalIsDisabledAndNothingIsCalled() {
        props.setApiKey("");
        assertEquals(PortalClient.Health.DISABLED, client.health());
        PortalUnavailableException e = assertThrows(PortalUnavailableException.class,
            () -> client.studentTranscript(FAKE_MSSV, "CQ99CT"));
        assertEquals("PORTAL_DISABLED", e.code());
        props.setApiKey(KEY);
        props.setEnabled(false);
        assertEquals(PortalClient.Health.DISABLED, client.health());
        server.verify();
    }

    @Test
    void timeoutIsRetriedOnceThenUnavailable() {
        server.expect(ExpectedCount.twice(), requestTo(BASE + PortalClient.DECISIONS))
            .andRespond(withException(new SocketTimeoutException("Read timed out")));
        PortalUnavailableException e = assertThrows(PortalUnavailableException.class, () -> client.decisions(FAKE_MSSV));
        assertEquals("PORTAL_UNAVAILABLE", e.code());
        assertEquals(List.of(PortalClient.RETRY_BACKOFF_MS), sleeps);
        server.verify();
    }

    @Test
    void serverErrorThenSuccessRecovers() {
        server.expect(requestTo(BASE + PortalClient.STUDENT_TRANSCRIPT))
            .andRespond(withServerError().body("{\"leak\":\"" + SECRET_BODY_MARKER + "\"}"));
        expectTranscript(ExpectedCount.once());
        assertEquals(1, client.studentTranscript(FAKE_MSSV, "CQ99CT").size());
        assertEquals(1, sleeps.size());
        server.verify();
    }

    @Test
    void twoServerErrorsAreUnavailable() {
        server.expect(ExpectedCount.twice(), requestTo(BASE + PortalClient.PROGRAM_COURSES))
            .andRespond(withStatus(HttpStatus.BAD_GATEWAY));
        assertThrows(PortalUnavailableException.class, () -> client.programCourses("CQ99CT"));
        server.verify();
    }

    @Test
    void clientErrorIsNotRetried() {
        server.expect(ExpectedCount.once(), requestTo(BASE + PortalClient.PROGRAM_COURSES))
            .andRespond(withStatus(HttpStatus.UNAUTHORIZED).body("bad key " + KEY));
        assertThrows(PortalUnavailableException.class, () -> client.programCourses("CQ99CT"));
        assertTrue(sleeps.isEmpty());
        server.verify();
    }

    @Test
    void okFalseInvalidJsonAndNonObjectAreUnavailable() {
        for (String bad : new String[]{
            "{\"status\":500,\"ok\":false,\"body\":\"" + SECRET_BODY_MARKER + "\"}",
            "{not json",
            "[1,2,3]",
            "{\"status\":200,\"body\":[]}",
        }) {
            server.reset();
            server.expect(requestTo(BASE + PortalClient.DECISIONS))
                .andRespond(withSuccess(bad, MediaType.APPLICATION_JSON));
            assertThrows(PortalUnavailableException.class, () -> client.decisions(FAKE_MSSV), bad);
            server.verify();
        }
    }

    @Test
    void nullBodyBecomesEmptyList() {
        server.expect(requestTo(BASE + PortalClient.DECISIONS))
            .andRespond(withSuccess("{\"status\":200,\"ok\":true,\"body\":null}", MediaType.APPLICATION_JSON));
        assertEquals(0, client.decisions(FAKE_MSSV).size());
    }

    @Test
    void cacheHitThenExpiry() {
        expectTranscript(ExpectedCount.twice());
        client.studentTranscript(FAKE_MSSV, "CQ99CT");
        assertTrue(client.isCached(PortalClient.STUDENT_TRANSCRIPT,
            Map.of("p1", FAKE_MSSV, "p2", "CQ99CT", "p3", "ALL", "p4", "ALL")));
        client.studentTranscript(FAKE_MSSV, "CQ99CT"); // hit, no request
        clock.now = clock.now.plus(Duration.ofMinutes(11));
        client.studentTranscript(FAKE_MSSV, "CQ99CT"); // expired, second request
        server.verify();
    }

    @Test
    void failuresAreNotCached() {
        server.expect(ExpectedCount.twice(), requestTo(BASE + PortalClient.DECISIONS))
            .andRespond(withServerError());
        server.expect(requestTo(BASE + PortalClient.DECISIONS))
            .andRespond(withSuccess("{\"ok\":true,\"body\":[]}", MediaType.APPLICATION_JSON));
        assertThrows(PortalUnavailableException.class, () -> client.decisions(FAKE_MSSV));
        assertEquals(0, client.decisions(FAKE_MSSV).size());
        server.verify();
    }

    @Test
    void healthIsCachedForSixtySeconds() {
        server.expect(ExpectedCount.once(), requestTo(BASE + "/health"))
            .andRespond(withSuccess("{\"app\":\"ok\",\"db\":\"ok\"}", MediaType.APPLICATION_JSON));
        server.expect(ExpectedCount.once(), requestTo(BASE + "/health"))
            .andRespond(withException(new IOException("down")));
        assertEquals(PortalClient.Health.UP, client.health());
        assertEquals(PortalClient.Health.UP, client.health());
        clock.now = clock.now.plusSeconds(61);
        assertEquals(PortalClient.Health.DOWN, client.health());
        server.verify();
    }

    @Test
    void recordCountShapes() {
        assertEquals(0, PortalClient.count(null));
        assertEquals(2, PortalClient.count(PortalClient.unwrap("{\"ok\":true,\"body\":[1,2]}")));
        assertEquals(3, PortalClient.count(PortalClient.unwrap(
            "{\"ok\":true,\"body\":{\"resultDanhSach\":[1,2,3]}}")));
        assertEquals(2, PortalClient.count(PortalClient.unwrap(
            "{\"ok\":true,\"body\":{\"groupSelection\":[],\"tbStudyPrograms\":[1,2]}}")));
    }

    @Test
    void propertiesToStringHidesSecrets() {
        props.getStudents().put(205L, new PortalProperties.StudentLink(FAKE_MSSV, "CQ99CT", "ITK99Z"));
        String s = props.toString();
        assertFalse(s.contains(KEY));
        assertFalse(s.contains(FAKE_MSSV));
    }
}
