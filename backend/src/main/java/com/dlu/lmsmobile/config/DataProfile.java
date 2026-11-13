package com.dlu.lmsmobile.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Which kind of database the backend reads (REAL-DATA-1). {@code demo} (default): the supplied
 * snapshot with Moodle access logs. {@code real}: the real Moodle export imported by
 * tools/Import-RealData.ps1, where "activity" can only mean hand-ins (submitted assignment or
 * finished quiz attempt) and progress counts graded activities only. Labels follow the profile so
 * every number on screen says how it was computed. Set by tools/Start-LocalBackend.ps1.
 */
@Component
public class DataProfile {
    public static final String DEMO = "demo";
    public static final String REAL = "real";

    private final String name;

    public DataProfile(@Value("${app.data-profile:demo}") String name) {
        this.name = REAL.equalsIgnoreCase(name == null ? "" : name.trim()) ? REAL : DEMO;
    }

    public static DataProfile demo() { return new DataProfile(DEMO); }

    public static DataProfile real() { return new DataProfile(REAL); }

    public String name() { return name; }

    /** True when "activity" means hand-ins only (no access log in the data). */
    public boolean handInsOnly() { return REAL.equals(name); }
}
