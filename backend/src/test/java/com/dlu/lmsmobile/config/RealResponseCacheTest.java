package com.dlu.lmsmobile.config;

import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

/** REAL-DATA-2: response cache for static LMS read models on the real export. */
class RealResponseCacheTest {

    @RestController
    static class Api {
        final AtomicInteger calls = new AtomicInteger();

        @GetMapping("/api/v1/dev/teachers/9/courses/1/engagement-heatmap")
        public Map<String, Object> heatmap() { return Map.of("n", calls.incrementAndGet()); }

        @GetMapping("/api/v1/dev/students/7/dashboard")
        public Map<String, Object> dashboard() { return Map.of("n", calls.incrementAndGet()); }

        @PostMapping("/api/v1/dev/students/7/flashcards")
        public Map<String, Object> write() { return Map.of("ok", true); }
    }

    static MockMvc mvc(Api api, String profile) {
        return MockMvcBuilders.standaloneSetup(api).addFilters(new RealResponseCache(profile)).build();
    }

    static String body(MockMvc m, String path) throws Exception {
        return m.perform(get(path)).andReturn().getResponse().getContentAsString();
    }

    @Test
    void realServesTheSecondReadFromMemoryAndAWriteClearsIt() throws Exception {
        Api api = new Api();
        MockMvc m = mvc(api, "real");
        String path = "/api/v1/dev/teachers/9/courses/1/engagement-heatmap";
        assertEquals("{\"n\":1}", body(m, path));
        assertEquals("HIT", m.perform(get(path)).andReturn().getResponse().getHeader("X-Real-Cache"));
        assertEquals("{\"n\":1}", body(m, path));
        assertEquals(1, api.calls.get());
        m.perform(post("/api/v1/dev/students/7/flashcards"));
        assertEquals("{\"n\":2}", body(m, path));
    }

    @Test
    void pathsWithAppDataAndTheDemoProfileAreNeverCached() throws Exception {
        Api api = new Api();
        MockMvc real = mvc(api, "real");
        body(real, "/api/v1/dev/students/7/dashboard");
        body(real, "/api/v1/dev/students/7/dashboard");
        assertEquals(2, api.calls.get());
        Api demoApi = new Api();
        MockMvc demo = mvc(demoApi, "demo");
        body(demo, "/api/v1/dev/teachers/9/courses/1/engagement-heatmap");
        body(demo, "/api/v1/dev/teachers/9/courses/1/engagement-heatmap");
        assertEquals(2, demoApi.calls.get());
    }

    @Test
    void onlyTheListedReadModelsAreCacheable() {
        assertTrue(RealResponseCache.cacheable("/api/v1/dev/students/7/study-recommendations"));
        assertTrue(RealResponseCache.cacheable("/api/v1/dev/teachers/9/courses/13698/grade-forecast"));
        assertTrue(RealResponseCache.cacheable("/api/v1/dev/teachers/9/courses/13698/class-insights"));
        assertFalse(RealResponseCache.cacheable("/api/v1/dev/teachers/9/courses/13698/students"));
        assertFalse(RealResponseCache.cacheable("/api/v1/dev/students/7/study-plan"));
    }
}
