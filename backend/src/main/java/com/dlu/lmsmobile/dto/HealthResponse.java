package com.dlu.lmsmobile.dto;

public class HealthResponse {
    private String status;
    private String database;
    /** V3-P0: UP | DOWN | DISABLED (cached 60 s). */
    private String portal;

    public HealthResponse() {
    }

    public HealthResponse(String status, String database) {
        this.status = status;
        this.database = database;
    }

    public HealthResponse(String status, String database, String portal) {
        this(status, database);
        this.portal = portal;
    }

    /** POLISH-1: Portal warm-up progress "N/M" (calls done / planned); null when off. Counts only. */
    private String prewarm;

    public String getPrewarm() { return prewarm; }

    public void setPrewarm(String prewarm) { this.prewarm = prewarm; }

    public String getPortal() {
        return portal;
    }

    public void setPortal(String portal) {
        this.portal = portal;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getDatabase() {
        return database;
    }

    public void setDatabase(String database) {
        this.database = database;
    }
}
