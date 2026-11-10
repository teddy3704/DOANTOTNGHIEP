package com.dlu.lmsmobile.portal;

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
    public PortalClient portalClient(PortalProperties props, Clock clock) {
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
