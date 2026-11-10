package com.dlu.lmsmobile.security;

import org.springframework.core.env.Environment;
import org.springframework.core.env.Profiles;
import org.springframework.stereotype.Component;

/** Local demo identity is server-owned; never a substitute for Moodle authentication. */
@Component
public class LocalDevelopmentSettings {
    private final boolean demoEnabled;
    private final long studentId;
    private final long teacherId;

    public LocalDevelopmentSettings(Environment environment) {
        boolean local = environment.acceptsProfiles(Profiles.of("local-development"));
        demoEnabled = environment.getProperty("app.demo-auth.enabled", Boolean.class, false);
        if (demoEnabled && !local) {
            throw new IllegalStateException("Demo authentication requires the local-development profile");
        }
        if (local && !isLoopback(environment.getProperty("server.address", ""))) {
            throw new IllegalStateException("Local development must bind to 127.0.0.1 or ::1");
        }
        studentId = environment.getProperty("app.demo-auth.student-id", Long.class, 0L);
        teacherId = environment.getProperty("app.demo-auth.teacher-id", Long.class, 0L);
        if (demoEnabled && (studentId <= 0 || teacherId <= 0 || studentId == teacherId)) {
            throw new IllegalStateException("Demo authentication requires distinct positive server-configured user IDs");
        }
    }

    private static boolean isLoopback(String address) {
        return "127.0.0.1".equals(address) || "::1".equals(address);
    }

    public boolean demoEnabled() { return demoEnabled; }
    public long studentId() { return studentId; }
    public long teacherId() { return teacherId; }
}
