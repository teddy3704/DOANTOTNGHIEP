package com.dlu.lmsmobile.portal;

import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Locale;

/**
 * Server-side mapping userId → Portal identity (docs/V3_PORTAL_PROMPT.md §2.2). Users never
 * send an MSSV or class code that widens what they can see. A real deployment would take the
 * MSSV from the university SSO login instead of this configuration.
 */
@Component
public class PortalIdentity {
    private final PortalClient client;

    public PortalIdentity(PortalClient client) {
        this.client = client;
    }

    /** Throws 503 PORTAL_DISABLED when not configured, 404 PORTAL_NOT_LINKED when unmapped. */
    public PortalProperties.StudentLink student(Long userId) {
        if (!client.configured()) throw PortalUnavailableException.disabled();
        PortalProperties.StudentLink link = client.properties().getStudents().get(userId);
        if (link == null || !link.complete()) throw new PortalNotLinkedException();
        return link;
    }

    public List<String> advisorClasses(Long teacherId) {
        if (!client.configured()) throw PortalUnavailableException.disabled();
        List<String> classes = client.properties().getAdvisors().get(teacherId);
        if (classes == null || classes.isEmpty()) throw new PortalNotLinkedException();
        return classes.stream().map(c -> c.trim().toUpperCase(Locale.ROOT)).toList();
    }

    /** The class must be one of this advisor's configured classes; otherwise 404. */
    public String advisorClass(Long teacherId, String classId) {
        String wanted = classId == null ? "" : classId.trim().toUpperCase(Locale.ROOT);
        if (!advisorClasses(teacherId).contains(wanted)) throw new PortalNotLinkedException();
        return wanted;
    }
}
