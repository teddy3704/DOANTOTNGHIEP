package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.dto.HealthResponse;
import com.dlu.lmsmobile.portal.PortalClient;
import com.dlu.lmsmobile.portal.PortalPrewarmer;
import org.springframework.beans.factory.ObjectProvider;
import com.dlu.lmsmobile.repository.HealthRepository;
import org.springframework.stereotype.Service;

@Service
public class HealthService {

    private final HealthRepository healthRepository;
    private final PortalClient portal;
    private final ObjectProvider<PortalPrewarmer> prewarm;
    private final String profile;

    private final ObjectProvider<com.dlu.lmsmobile.config.RealCacheWarmer> warmer;

    public HealthService(HealthRepository healthRepository, PortalClient portal, ObjectProvider<PortalPrewarmer> prewarm,
                         @org.springframework.beans.factory.annotation.Value("${app.data-profile:demo}") String profile,
                         ObjectProvider<com.dlu.lmsmobile.config.RealCacheWarmer> warmer) {
        this.warmer = warmer;
        this.profile = new com.dlu.lmsmobile.config.DataProfile(profile).name();
        this.healthRepository = healthRepository;
        this.portal = portal;
        this.prewarm = prewarm;
    }

    public HealthResponse checkHealth() {
        boolean isConnected = healthRepository.isDatabaseConnected();
        String dbStatus = isConnected ? "CONNECTED" : "DISCONNECTED";
        String status = isConnected ? "UP" : "DOWN";
        // Portal state is informational: LMS features keep working when it is DOWN or DISABLED.
        HealthResponse r = new HealthResponse(status, dbStatus, portal.health().name());
        PortalPrewarmer p = prewarm.getIfAvailable();
        r.setPrewarm(p == null ? null : p.status());   // "N/M" counts only, or null when off
        com.dlu.lmsmobile.config.RealCacheWarmer w = warmer.getIfAvailable();
        if (r.getPrewarm() == null && w != null) r.setPrewarm(w.status());   // real: cache warm-up "ok/failed done"
        r.setDataProfile(profile);
        return r;
    }
}
