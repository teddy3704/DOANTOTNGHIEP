package com.dlu.lmsmobile.security;

import jakarta.servlet.DispatcherType;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {
    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final LocalDevelopmentSettings localSettings;

    public SecurityConfig(JwtAuthenticationFilter jwtAuthenticationFilter, LocalDevelopmentSettings localSettings) {
        this.jwtAuthenticationFilter = jwtAuthenticationFilter;
        this.localSettings = localSettings;
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http.csrf(AbstractHttpConfigurer::disable)
            .httpBasic(AbstractHttpConfigurer::disable)
            .formLogin(AbstractHttpConfigurer::disable)
            .logout(AbstractHttpConfigurer::disable)
            .requestCache(AbstractHttpConfigurer::disable)
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .exceptionHandling(errors -> errors
                .authenticationEntryPoint((request, response, exception) -> response.sendError(HttpServletResponse.SC_UNAUTHORIZED))
                .accessDeniedHandler((request, response, exception) -> response.sendError(HttpServletResponse.SC_FORBIDDEN)))
            .authorizeHttpRequests(auth -> {
                // sendError(403/401) re-dispatches to /error; without this the error dispatch is
                // re-authorized anonymously and every 403 surfaces to clients as 401.
                auth.dispatcherTypeMatchers(DispatcherType.ERROR).permitAll();
                auth.requestMatchers(HttpMethod.POST, "/api/v1/auth/login").permitAll();
                if (localSettings.demoEnabled()) {
                    auth.requestMatchers(HttpMethod.POST, "/api/v1/auth/demo-login").permitAll();
                }
                auth.requestMatchers("/api/v1/dev/students/**").access(new PathIdentityAuthorizationManager(
                        "STUDENT", "^/api/v1/dev/students/([1-9][0-9]*)(?:/.*)?$"))
                    .requestMatchers("/api/v1/dev/teachers/**", "/api/v1/teachers/**")
                    .access(new PathIdentityAuthorizationManager("TEACHER", "^/api/v1/(?:dev/)?teachers/([1-9][0-9]*)(?:/.*)?$"))
                    .requestMatchers("/api/v1/courses/**", "/api/v1/students/me/**").hasRole("STUDENT")
                    .requestMatchers("/api/v1/health").authenticated()
                    .anyRequest().denyAll();
            })
            .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }
}
