package com.dlu.lmsmobile.security.auth;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.*;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

/** Mocked Moodle only: the provider is never pointed at the real lms.dlu.edu.vn. */
class MoodleTokenProviderTest {
    static final String BASE = "https://lms.example.test";
    MockRestServiceServer server;
    MoodleTokenProvider provider;

    @BeforeEach
    void setUp() {
        RestClient.Builder builder = RestClient.builder().baseUrl(BASE);
        server = MockRestServiceServer.bindTo(builder).build();
        provider = new MoodleTokenProvider(builder.build(), "moodle_mobile_app", id -> id == 102 ? "TEACHER" : "STUDENT");
    }

    @Test
    void validTokenThenSiteInfoGivesTheUserAndTheServerDecidedRole() {
        server.expect(requestTo(BASE + "/login/token.php")).andExpect(method(HttpMethod.POST))
            .andExpect(content().formDataContains(java.util.Map.of("username", "2312005", "service", "moodle_mobile_app")))
            .andRespond(withSuccess("{\"token\":\"abc123\",\"privatetoken\":null}", MediaType.APPLICATION_JSON));
        server.expect(requestTo(BASE + "/webservice/rest/server.php"))
            .andExpect(content().formDataContains(java.util.Map.of("wstoken", "abc123",
                "wsfunction", "core_webservice_get_site_info")))
            .andRespond(withSuccess("{\"userid\":205,\"username\":\"2312005\"}", MediaType.APPLICATION_JSON));
        Optional<AuthProvider.AuthenticatedUser> user = provider.authenticate("2312005", "pw");
        assertEquals(Optional.of(new AuthProvider.AuthenticatedUser(205, "STUDENT")), user);
        server.verify();
    }

    @Test
    void wrongPasswordIsEmptyNotAnError() {
        server.expect(requestTo(BASE + "/login/token.php")).andRespond(withSuccess(
            "{\"error\":\"Invalid login, please try again\",\"errorcode\":\"invalidlogin\"}", MediaType.APPLICATION_JSON));
        assertTrue(provider.authenticate("2312005", "wrong").isEmpty());
    }

    @Test
    void disabledMobileWebServiceIsUnavailable() {
        server.expect(requestTo(BASE + "/login/token.php")).andRespond(withSuccess(
            "{\"error\":\"Web services must be enabled\",\"errorcode\":\"enablewsdescription\"}", MediaType.APPLICATION_JSON));
        assertThrows(AuthProvider.UnavailableException.class, () -> provider.authenticate("2312005", "pw"));
    }
}
