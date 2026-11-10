package com.dlu.lmsmobile.portal;

import org.junit.jupiter.api.Test;
import org.springframework.boot.context.properties.bind.Binder;
import org.springframework.boot.context.properties.source.MapConfigurationPropertySource;

import java.math.BigDecimal;
import java.time.Duration;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/**
 * The shape Start-LocalBackend.ps1 sends through SPRING_APPLICATION_JSON (flattened the same way
 * Spring flattens JSON) binds to PortalProperties. Values are invented.
 */
class PortalPropertiesBindingTest {
    @Test
    void bindsNestedMappingFromFlattenedJson() {
        Map<String, Object> flat = Map.of(
            "app.portal.enabled", "true",
            "app.portal.api-key", "FAKE",
            "app.portal.presentationMask", "true",
            "app.portal.students.205.studentId", "2399Z001",
            "app.portal.students.205.studyProgramId", "CQ99CT",
            "app.portal.students.205.classId", "ITK99Z",
            "app.portal.advisors.102[0]", "ITK99Z",
            "app.portal.advisors.102[1]", "ITK98A",
            "app.portal.courseMap.13", "TIN9999");
        PortalProperties p = new Binder(new MapConfigurationPropertySource(flat))
            .bind("app.portal", PortalProperties.class).get();
        assertTrue(p.configured());
        assertEquals("2399Z001", p.getStudents().get(205L).getStudentId());
        assertEquals(List.of("ITK99Z", "ITK98A"), p.getAdvisors().get(102L));
        assertEquals("TIN9999", p.getCourseMap().get(13L));
        assertEquals(Duration.ofMinutes(10), p.getCacheTtl());
        assertEquals(4, p.getGradeBands().size());
        assertEquals(new BigDecimal("3.6"), p.getGradeBands().get(0).getMin());
    }

    @Test
    void defaultsAreOffAndMasked() {
        PortalProperties p = new PortalProperties();
        assertFalse(p.configured());
        assertTrue(p.isPresentationMask());
        assertEquals(Duration.ofSeconds(5), p.getConnectTimeout());
        assertEquals(Duration.ofSeconds(15), p.getReadTimeout());
    }
}
