package com.dlu.lmsmobile.security;

import com.dlu.lmsmobile.controller.AuthController;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;
import org.springframework.mock.env.MockEnvironment;
import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.*;

class LocalDevelopmentSettingsTest {
    private MockEnvironment local() {
        var environment = new MockEnvironment().withProperty("server.address", "127.0.0.1");
        environment.setActiveProfiles("local-development");
        return environment;
    }

    @Test void demoIsDisabledByDefault() {
        assertFalse(new LocalDevelopmentSettings(new MockEnvironment()).demoEnabled());
    }

    @Test void flagCannotEnableDemoOutsideLocalProfile() {
        assertThrows(IllegalStateException.class, () -> new LocalDevelopmentSettings(
                new MockEnvironment().withProperty("app.demo-auth.enabled", "true")));
    }

    @Test void localProfileCannotBindToPublicOrUnspecifiedAddress() {
        for (String address : new String[] {"0.0.0.0", "::", "192.168.1.2", ""}) {
            assertThrows(IllegalStateException.class, () -> new LocalDevelopmentSettings(
                    local().withProperty("server.address", address)));
        }
    }

    @Test void enabledDemoRequiresDistinctServerOwnedPositiveIds() {
        var environment = local().withProperty("app.demo-auth.enabled", "true");
        assertThrows(IllegalStateException.class, () -> new LocalDevelopmentSettings(environment));
        environment.withProperty("app.demo-auth.student-id", "205").withProperty("app.demo-auth.teacher-id", "205");
        assertThrows(IllegalStateException.class, () -> new LocalDevelopmentSettings(environment));
        environment.withProperty("app.demo-auth.teacher-id", "102");
        assertEquals(205L, new LocalDevelopmentSettings(environment).studentId());
    }

    @Test void disabledDemoControllerIsNotRegisteredEvenInLocalProfile() {
        new ApplicationContextRunner()
                .withInitializer(context -> context.getEnvironment().setActiveProfiles("local-development"))
                .withPropertyValues("app.jwt.secret=isolated-test-only-secret-not-for-runtime-1234",
                        "server.address=127.0.0.1", "app.demo-auth.enabled=false")
                .withUserConfiguration(AuthController.class, LocalDevelopmentSettings.class, JwtTokenProvider.class)
                .run(context -> assertThat(context).doesNotHaveBean(AuthController.class));
    }

    @Test void demoControllerIsNotRegisteredWithoutLocalProfile() {
        new ApplicationContextRunner()
                .withPropertyValues("app.jwt.secret=isolated-test-only-secret-not-for-runtime-1234",
                        "app.demo-auth.enabled=false")
                .withUserConfiguration(AuthController.class, LocalDevelopmentSettings.class, JwtTokenProvider.class)
                .run(context -> assertThat(context).doesNotHaveBean(AuthController.class));
    }
}
