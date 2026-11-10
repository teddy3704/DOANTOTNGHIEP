package com.dlu.lmsmobile.security.auth;

import com.dlu.lmsmobile.repository.TeacherRepository;
import com.dlu.lmsmobile.security.JwtTokenProvider;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestClient;

import java.time.Clock;
import java.util.ArrayList;
import java.util.List;

@Configuration
@EnableConfigurationProperties(AuthProperties.class)
public class AuthConfig {

    @Bean
    public LoginAttemptLimiter loginAttemptLimiter(Clock clock, AuthProperties props) {
        return new LoginAttemptLimiter(clock, props.getMaxFailures(), props.getLockWindow());
    }

    @Bean
    public LoginService loginService(AuthProperties props, LoginAttemptLimiter limiter, JwtTokenProvider tokens,
                                     ObjectProvider<TeacherRepository> teachers) {
        List<AuthProvider> providers = new ArrayList<>();
        if (props.getLocal().isEnabled()) {
            providers.add(new LocalCredentialProvider(props.getLocal().getUsers()));
        }
        AuthProperties.Moodle moodle = props.getMoodle();
        if (moodle.isEnabled()) {
            if (moodle.getBaseUrl() == null || !moodle.getBaseUrl().startsWith("https://")) {
                throw new IllegalStateException("app.auth.moodle.base-url must be an https URL");
            }
            SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
            factory.setConnectTimeout((int) moodle.getTimeout().toMillis());
            factory.setReadTimeout((int) moodle.getTimeout().toMillis());
            RestClient rest = RestClient.builder().baseUrl(moodle.getBaseUrl()).requestFactory(factory).build();
            TeacherRepository repo = teachers.getObject();
            providers.add(new MoodleTokenProvider(rest, moodle.getService(),
                id -> repo.findCoursesByTeacherId(id).isEmpty() ? "STUDENT" : "TEACHER"));
        }
        return new LoginService(providers, limiter, tokens);
    }
}
