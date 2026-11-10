package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.dto.HealthResponse;
import com.dlu.lmsmobile.portal.PortalClient;
import com.dlu.lmsmobile.repository.HealthRepository;
import org.springframework.stereotype.Service;

@Service
public class HealthService {

    private final HealthRepository healthRepository;
    private final PortalClient portal;

    public HealthService(HealthRepository healthRepository, PortalClient portal) {
        this.healthRepository = healthRepository;
        this.portal = portal;
    }

    public HealthResponse checkHealth() {
        boolean isConnected = healthRepository.isDatabaseConnected();
        String dbStatus = isConnected ? "CONNECTED" : "DISCONNECTED";
        String status = isConnected ? "UP" : "DOWN";
        // Portal state is informational: LMS features keep working when it is DOWN or DISABLED.
        return new HealthResponse(status, dbStatus, portal.health().name());
    }
}
