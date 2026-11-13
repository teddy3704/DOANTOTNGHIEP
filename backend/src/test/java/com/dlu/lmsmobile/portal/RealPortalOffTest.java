package com.dlu.lmsmobile.portal;

import com.dlu.lmsmobile.config.DataProfile;
import com.dlu.lmsmobile.controller.StudentPortalController;
import org.junit.jupiter.api.Test;

import java.time.Clock;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * REAL-DATA-2: on the real profile the Portal API (simulated data) is never called. The client is
 * built switched off, so any call fails with PORTAL_DISABLED before a request exists (an attempted
 * request to the unroutable address below would instead fail as PORTAL_UNAVAILABLE after retries).
 */
class RealPortalOffTest {

    static PortalProperties configuredProps() {
        PortalProperties p = new PortalProperties();
        p.setEnabled(true);
        p.setApiKey("test-key-not-real");
        p.setBaseUrl("http://127.0.0.1:9");
        return p;
    }

    @Test
    void realProfileBuildsADisabledClientThatSendsNothing() {
        PortalClient client = new PortalConfig().portalClient(configuredProps(), Clock.systemUTC(), DataProfile.real());
        assertFalse(client.configured());
        for (Runnable call : List.<Runnable>of(
                () -> client.studentTranscript("0000000", "P"),
                () -> client.classStudents("C"),
                () -> client.programCourses("P"),
                () -> client.decisions("0000000"),
                () -> client.classConduct("2025-2026", "1", "C"))) {
            PortalUnavailableException e = assertThrows(PortalUnavailableException.class, call::run);
            assertEquals("PORTAL_DISABLED", e.code());
        }
        assertNull(client.lastSuccess());
    }

    @Test
    void demoProfileKeepsTheClientConfigured() {
        assertTrue(new PortalConfig().portalClient(configuredProps(), Clock.systemUTC(), DataProfile.demo()).configured());
    }

    @Test
    void realStudentEndpointsNeverReachThePortalService() {
        StudentPortalService portal = mock(StudentPortalService.class);
        LocalTranscriptService local = mock(LocalTranscriptService.class);
        when(local.active()).thenReturn(true);
        when(local.summary(1L)).thenReturn(Map.of("source", LocalTranscriptService.SOURCE));
        when(local.transcript(1L)).thenReturn(Map.of());
        when(local.gpaSimulation(1L)).thenReturn(Map.of());
        var controller = new StudentPortalController(portal, mock(PortalSourcesService.class), local);
        assertEquals(LocalTranscriptService.SOURCE, controller.summary(1L).get("source"));
        controller.transcript(1L);
        controller.gpaSimulation(1L);
        assertThrows(PortalNotLinkedException.class, () -> controller.program(1L));
        controller.conduct(1L);   // real: the student's own conduct file
        verify(local).conduct(1L);
        assertThrows(PortalNotLinkedException.class, () -> controller.decisions(1L));
        verifyNoInteractions(portal);
    }
}
