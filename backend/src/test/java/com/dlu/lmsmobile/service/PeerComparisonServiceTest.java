package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.exception.ResourceNotFoundException;
import com.dlu.lmsmobile.repository.ForecastRepository;
import com.dlu.lmsmobile.repository.InsightsRepository;
import com.dlu.lmsmobile.service.PeerComparisonService.Point;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@SuppressWarnings("unchecked")
class PeerComparisonServiceTest {
    static List<Point> classOf(double mine, double... others) {
        List<Point> p = new ArrayList<>();
        p.add(new Point(true, mine));
        for (double o : others) p.add(new Point(false, o));
        return p;
    }

    @Test
    void fourStudentsAreSuppressedAndRevealNothing() {
        Map<String, Object> m = PeerComparisonService.metric(classOf(50, 10, 20, 90));
        assertEquals(true, m.get("suppressed"));
        assertEquals(4, m.get("classSize"));
        assertFalse(m.containsKey("mine"));
        assertFalse(m.containsKey("median"));
        assertFalse(m.containsKey("histogram"));
        assertFalse(m.containsKey("percentBelow"));
    }

    @Test
    void fifteenStudentsGiveTheShareBelowMedianAndHistogram() {
        // Mine 65; others: 14 values, 9 of them below 65.
        Map<String, Object> m = PeerComparisonService.metric(
            classOf(65, 0, 10, 15, 25, 30, 40, 45, 55, 60, 65, 70, 80, 95, 100));
        assertEquals(false, m.get("suppressed"));
        assertEquals(15, m.get("classSize"));
        assertEquals(64.3, m.get("percentBelow"));  // 9 / 14
        assertEquals(55.0, m.get("median"));         // 8th of 15 sorted values
        assertEquals(65.0, m.get("mine"));
        assertEquals(3, m.get("myBin"));             // [60,80)
        List<Map<String, Object>> h = (List<Map<String, Object>>) m.get("histogram");
        // [0,20): 0,10,15 · [20,40): 25,30 · [40,60): 40,45,55 · [60,80): 60,65,65,70 · [80,100]: 80,95,100
        assertEquals(List.of(3, 2, 3, 4, 3), h.stream().map(x -> x.get("count")).toList());
        assertEquals(15, h.stream().mapToInt(x -> (int) x.get("count")).sum());
    }

    @Test
    void binBoundariesAndEvenMedian() {
        assertEquals(0, PeerComparisonService.bin(0));
        assertEquals(0, PeerComparisonService.bin(19.99));
        assertEquals(1, PeerComparisonService.bin(20));
        assertEquals(4, PeerComparisonService.bin(80));
        assertEquals(4, PeerComparisonService.bin(100));
        Map<String, Object> m = PeerComparisonService.metric(classOf(10, 20, 30, 40, 50, 60));
        assertEquals(35.0, m.get("median"));
        assertEquals(0.0, m.get("percentBelow"));
    }

    @Test
    void callerWithoutDataStillSeesTheClassButNoPosition() {
        List<Point> p = new ArrayList<>();
        for (double v : new double[] {10, 30, 50, 70, 90}) p.add(new Point(false, v));
        Map<String, Object> m = PeerComparisonService.metric(p);
        assertEquals(false, m.get("suppressed"));
        assertNull(m.get("mine"));
        assertNull(m.get("percentBelow"));
        assertNull(m.get("myBin"));
    }

    @Test
    void responseJsonHasNoIdentifiersOrPerStudentValues() throws Exception {
        ForecastRepository repo = mock(ForecastRepository.class);
        InsightsRepository insights = mock(InsightsRepository.class);
        when(insights.isEnrolled(205L, 3000015L)).thenReturn(true);
        List<Map<String, Object>> rows = new ArrayList<>();
        for (int k = 0; k < 15; k++) {
            Map<String, Object> r = new HashMap<>();
            r.put("mine", k == 0);
            r.put("progress_percentage", 10.0 * (k % 10));
            r.put("average_percentage", 5.0 * k);
            rows.add(r);
        }
        when(repo.findClassProgress(205L, 3000015L)).thenReturn(rows);
        when(repo.findClassAverageGrades(205L, 3000015L)).thenReturn(rows);
        Map<String, Object> out = new PeerComparisonService(repo, insights).compare(205L, 3000015L);
        String json = new ObjectMapper().writeValueAsString(out).toLowerCase(Locale.ROOT);
        for (String banned : List.of("userid", "\"name\"", "fullname", "email", "student_code", "values")) {
            assertFalse(json.contains(banned), banned);
        }
        assertEquals(false, ((Map<String, Object>) out.get("progress")).get("suppressed"));
    }

    @Test
    void notEnrolledIsNotFound() {
        InsightsRepository insights = mock(InsightsRepository.class);
        ForecastRepository repo = mock(ForecastRepository.class);
        assertThrows(ResourceNotFoundException.class,
            () -> new PeerComparisonService(repo, insights).compare(205L, 99L));
        verifyNoInteractions(repo);
    }
}
