package com.dlu.lmsmobile.portal;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.*;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/** V3-P0 value parser, bounded cache and server-side identity mapping. Fixtures are invented. */
class PortalSupportTest {
    static final ObjectMapper JSON = new ObjectMapper();

    @Test
    void numbersAsStringsEmptyAndGarbage() throws Exception {
        JsonNode n = JSON.readTree("""
            {"a":"2.77","b":"3","c":"","d":null,"e":8.5,"f":"abc","g":"7,25","h":"  "}""");
        assertEquals(new BigDecimal("2.77"), PortalValues.decimal(n, "a"));
        assertEquals(3, PortalValues.integer(n, "b"));
        assertNull(PortalValues.decimal(n, "c"));
        assertNull(PortalValues.decimal(n, "d"));
        assertEquals(new BigDecimal("8.5"), PortalValues.decimal(n, "e"));
        assertNull(PortalValues.decimal(n, "f"));
        assertEquals(new BigDecimal("7.25"), PortalValues.decimal(n, "g"));
        assertNull(PortalValues.text(n, "h"));
        assertNull(PortalValues.decimal(n, "missing"));
        assertNull(PortalValues.integer(n, "a"));
    }

    @Test
    void datesAndBooleans() throws Exception {
        JsonNode n = JSON.readTree("""
            {"d1":"05/09/2099","d2":"31/02/2099","d3":"2099-09-05","d4":"05/09/2099 00:00:00",
             "b1":true,"b2":"True","b3":"0","b4":"","b5":1}""");
        assertEquals(LocalDate.of(2099, 9, 5), PortalValues.date(n, "d1"));
        assertNull(PortalValues.date(n, "d2"));
        assertNull(PortalValues.date(n, "d3"));
        assertEquals(LocalDate.of(2099, 9, 5), PortalValues.date(n, "d4"));
        assertTrue(PortalValues.bool(n, "b1"));
        assertTrue(PortalValues.bool(n, "b2"));
        assertFalse(PortalValues.bool(n, "b3"));
        assertNull(PortalValues.bool(n, "b4"));
        assertTrue(PortalValues.bool(n, "b5"));
    }

    @Test
    void maskKeepsTwoOfEveryFour() {
        assertEquals("23**Z0**", PortalValues.maskId("2399Z001"));
        assertEquals("ab", PortalValues.maskId("ab"));
        assertNull(PortalValues.maskId(null));
    }

    @Test
    void cacheIsBoundedAndEvictsOldest() {
        Instant[] now = {Instant.parse("2099-01-01T00:00:00Z")};
        Clock clock = new Clock() {
            @Override public ZoneId getZone() { return ZoneOffset.UTC; }
            @Override public Clock withZone(ZoneId z) { return this; }
            @Override public Instant instant() { return now[0]; }
        };
        PortalCache<String> cache = new PortalCache<>(Duration.ofMinutes(10), 2, clock);
        AtomicInteger loads = new AtomicInteger();
        cache.get("a", () -> "A" + loads.incrementAndGet());
        now[0] = now[0].plusSeconds(1);
        cache.get("b", () -> "B" + loads.incrementAndGet());
        now[0] = now[0].plusSeconds(1);
        cache.get("c", () -> "C" + loads.incrementAndGet());
        assertEquals(2, cache.size());
        assertFalse(cache.contains("a"));
        assertTrue(cache.contains("b") && cache.contains("c"));
        assertEquals("B2", cache.get("b", () -> "never"));
    }

    @Test
    void cacheDoesNotStoreFailures() {
        PortalCache<String> cache = new PortalCache<>(Duration.ofMinutes(10), 5, Clock.systemUTC());
        assertThrows(IllegalStateException.class, () -> cache.get("x", () -> {
            throw new IllegalStateException();
        }));
        assertEquals(0, cache.size());
    }

    private static PortalIdentity identity(boolean configured) {
        PortalProperties p = new PortalProperties();
        p.setEnabled(configured);
        p.setApiKey("k");
        p.getStudents().put(205L, new PortalProperties.StudentLink("2399Z001", "CQ99CT", "ITK99Z"));
        p.getStudents().put(206L, new PortalProperties.StudentLink("2399Z002", "", "ITK99Z"));
        p.getAdvisors().put(102L, List.of(" itk99z "));
        PortalClient client = mock(PortalClient.class);
        when(client.configured()).thenReturn(p.configured());
        when(client.properties()).thenReturn(p);
        return new PortalIdentity(client);
    }

    @Test
    void identityComesFromServerConfigOnly() {
        PortalIdentity id = identity(true);
        assertEquals("2399Z001", id.student(205L).getStudentId());
        assertThrows(PortalNotLinkedException.class, () -> id.student(999L));
        assertThrows(PortalNotLinkedException.class, () -> id.student(206L)); // incomplete mapping
        assertEquals(List.of("ITK99Z"), id.advisorClasses(102L));
        assertEquals("ITK99Z", id.advisorClass(102L, "itk99z"));
        assertThrows(PortalNotLinkedException.class, () -> id.advisorClass(102L, "ITK98A"));
        assertThrows(PortalNotLinkedException.class, () -> id.advisorClasses(103L));
    }

    @Test
    void identityWhenPortalDisabled() {
        PortalIdentity id = identity(false);
        PortalUnavailableException e = assertThrows(PortalUnavailableException.class, () -> id.student(205L));
        assertEquals("PORTAL_DISABLED", e.code());
    }
}
