package com.dlu.lmsmobile.portal;

import com.dlu.lmsmobile.config.DataProfile;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestClient;

import java.time.Clock;

/** Wires the Portal client with explicit timeouts (connect 5 s, read 15 s by default). */
@Configuration
@EnableConfigurationProperties(PortalProperties.class)
public class PortalConfig {
    @Bean
    public PortalClient portalClient(PortalProperties props, Clock clock, DataProfile profile) {
        // REAL-DATA-2: the Portal API serves SIMULATED data. On the real export a real student code could
        // match a simulated one and show invented grades as real, so the client is switched off there:
        // configured() is false, no request is ever sent and the prewarmer never starts.
        if (profile.handInsOnly()) props.setEnabled(false);
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout((int) props.getConnectTimeout().toMillis());
        factory.setReadTimeout((int) props.getReadTimeout().toMillis());
        RestClient rest = RestClient.builder()
            .baseUrl(props.getBaseUrl() == null ? "" : props.getBaseUrl())
            .requestFactory(factory)
            .build();
        return new PortalClient(props, rest, clock);
    }
}
