package com.dlu.lmsmobile;

import com.dlu.lmsmobile.controller.DevStudentController;
import com.dlu.lmsmobile.security.*;
import com.dlu.lmsmobile.service.StudentService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.security.servlet.UserDetailsServiceAutoConfiguration;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.MockMvc;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = DevStudentController.class,
        excludeAutoConfiguration = UserDetailsServiceAutoConfiguration.class,
        properties = {"app.jwt.secret=isolated-test-only-secret-not-for-runtime-1234", "app.demo-auth.enabled=false"})
@Import({SecurityConfig.class, JwtAuthenticationFilter.class, JwtTokenProvider.class, LocalDevelopmentSettings.class})
class DevStudentControllerTest {
    @Autowired MockMvc mvc;
    @Autowired JwtTokenProvider tokens;
    @MockBean StudentService students;

    @Test void ownCourseReadRoutesAcceptAuthenticatedStudentWithoutDatabase() throws Exception {
        String token = tokens.generateToken(2L, "STUDENT");
        for (String suffix : new String[] {"learning-items", "grades", "grade-categories", "attendance", "tasks"}) {
            mvc.perform(get("/api/v1/dev/students/2/courses/10/" + suffix)
                    .header("Authorization", "Bearer " + token)).andExpect(status().isOk());
        }
    }
}
