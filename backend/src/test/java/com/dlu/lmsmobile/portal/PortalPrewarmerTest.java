package com.dlu.lmsmobile.portal;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.boot.context.properties.bind.Binder;
import org.springframework.boot.context.properties.source.MapConfigurationPropertySource;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;
import org.springframework.mock.env.MockEnvironment;

import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/** POLISH-1: configurable Portal cache TTL and the opt-in, sequential, counts-only warm-up. */
@ExtendWith(OutputCaptureExtension.class)
class PortalPrewarmerTest {
    AdvisorPortalService advisors;
    PortalClient client;
    PortalProperties props;
    final AtomicInteger pauses = new AtomicInteger();

    @BeforeEach
    void setUp() {
        advisors = mock(AdvisorPortalService.class);
        client = mock(PortalClient.class);
        props = new PortalProperties();
        props.getAdvisors().put(102L, List.of("ITK99Z"));
        when(client.configured()).thenReturn(true);
        when(client.properties()).thenReturn(props);
        when(advisors.identityClasses(102L)).thenReturn(List.of("ITK99Z"));
    }

    PortalPrewarmer prewarmer(boolean on) {
        MockEnvironment env = new MockEnvironment().withProperty("app.demo-auth.teacher-id", "102");
        if (on) env.setProperty("app.portal.prewarm", "true");
        PortalPrewarmer p = new PortalPrewarmer(advisors, client, env);
        p.setPause(ms -> pauses.incrementAndGet(), 1000);
        return p;
    }

    @Test
    void cacheTtlIsReadFromConfigurationWithTenMinutesAsDefault() {
        assertEquals(Duration.ofMinutes(10), new PortalProperties().getCacheTtl());
        PortalProperties bound = new Binder(new MapConfigurationPropertySource(Map.of("app.portal.cache-ttl", "6h")))
            .bind("app.portal", PortalProperties.class).get();
        assertEquals(Duration.ofHours(6), bound.getCacheTtl());
    }

    @Test
    void offByDefault() {
        PortalPrewarmer p = prewarmer(false);
        p.onReady();
        assertNull(p.status());
        verifyNoInteractions(advisors);
    }

    @Test
    void warmsTheOverviewThenEveryStudentOnceThroughTheSameService() {
        when(advisors.overview(102L, "ITK99Z", null, null, true)).thenReturn(Map.of("students", List.of(
            Map.of("no", 1), Map.of("no", 2), Map.of("no", 3))));
        when(advisors.student(eq(102L), eq("ITK99Z"), anyInt(), isNull(), isNull(), eq(true))).thenReturn(Map.of());
        PortalPrewarmer p = prewarmer(true);
        p.run();
        verify(advisors, times(1)).overview(102L, "ITK99Z", null, null, true);
        for (int no = 1; no <= 3; no++) verify(advisors).student(102L, "ITK99Z", no, null, null, true);
        assertEquals("4/4", p.status());
        assertEquals(4, pauses.get());   // one pause after every call: at most one call per interval
    }

    @Test
    void portalDownIsSkippedAndCountedWithoutFailing() {
        when(advisors.overview(anyLong(), anyString(), any(), any(), any())).thenThrow(PortalUnavailableException.disabled());
        PortalPrewarmer p = prewarmer(true);
        assertDoesNotThrow(p::run);
        assertEquals("0/1", p.status());
        assertEquals(1, p.failedCount());
        verify(advisors, never()).student(anyLong(), anyString(), anyInt(), any(), any(), any());
    }

    @Test
    void oneFailingStudentDoesNotStopTheOthers() {
        when(advisors.overview(102L, "ITK99Z", null, null, true)).thenReturn(Map.of("students", List.of(
            Map.of("no", 1), Map.of("no", 2))));
        when(advisors.student(102L, "ITK99Z", 1, null, null, true)).thenThrow(new RuntimeException("upstream 500"));
        when(advisors.student(102L, "ITK99Z", 2, null, null, true)).thenReturn(Map.of());
        PortalPrewarmer p = prewarmer(true);
        p.run();
        assertEquals("2/3", p.status());
        assertEquals(1, p.failedCount());
    }

    @Test
    void logsCountsOnlyNeverClassOrStudentData(CapturedOutput out) {
        when(advisors.overview(102L, "ITK99Z", null, null, true)).thenReturn(Map.of("students", List.of(
            Map.of("no", 1, "studentId", "2399Z001", "name", "Nguyễn Văn An"))));
        when(advisors.student(anyLong(), anyString(), anyInt(), any(), any(), any())).thenReturn(Map.of("gpa", 3.1));
        prewarmer(true).run();
        String logs = out.getAll();
        assertTrue(logs.contains("Portal prewarm finished: ok=2 failed=0 total=2"));
        assertFalse(logs.contains("ITK99Z"));
        assertFalse(logs.contains("2399Z001"));
        assertFalse(logs.contains("Nguyễn"));
    }
}
