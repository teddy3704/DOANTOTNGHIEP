package com.dlu.lmsmobile.portal;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * POLISH-1: warms the in-memory Portal cache for the demo advisor's class so the first "student detail" on stage opens at
 * once. OFF by default (app.portal.prewarm=false); only tools\Start-Demo.ps1 turns it on. Runs once in a background
 * thread after startup, strictly sequentially, at most one service call per second, through the same
 * AdvisorPortalService the endpoints use (so the cache keys are identical). Portal errors are skipped and only
 * counted; startup never waits for it. Logs counts only, never class, student or grade data.
 */
@Component
public class PortalPrewarmer {
    private static final Logger log = LoggerFactory.getLogger(PortalPrewarmer.class);

    /** Pause between calls; replaceable in tests. */
    @FunctionalInterface
    public interface Pause { void sleep(long millis) throws InterruptedException; }

    private final AdvisorPortalService advisors;
    private final PortalClient portal;
    private final long teacherId;
    private final AtomicInteger done = new AtomicInteger();
    private final AtomicInteger failed = new AtomicInteger();
    private final AtomicInteger total = new AtomicInteger();
    private volatile boolean enabled;
    private volatile Pause pause = Thread::sleep;
    private volatile long intervalMillis = 1000;

    public PortalPrewarmer(AdvisorPortalService advisors, PortalClient portal, Environment env) {
        this.advisors = advisors;
        this.portal = portal;
        this.enabled = env.getProperty("app.portal.prewarm", Boolean.class, false);
        this.teacherId = env.getProperty("app.demo-auth.teacher-id", Long.class, 0L);
    }

    void setPause(Pause pause, long intervalMillis) {
        this.pause = pause;
        this.intervalMillis = intervalMillis;
    }

    void setEnabled(boolean enabled) { this.enabled = enabled; }

    @EventListener(ApplicationReadyEvent.class)
    public void onReady() {
        if (!enabled || !portal.configured()) return;
        Thread t = new Thread(this::run, "portal-prewarm");
        t.setDaemon(true);
        t.start();
    }

    /** Runs the whole warm-up in the calling thread (the listener calls it in a background thread). */
    void run() {
        long start = System.currentTimeMillis();
        List<Long> teachers = teacherId > 0 ? List.of(teacherId)
            : new ArrayList<>(portal.properties().getAdvisors().keySet());
        try {
            for (Long teacher : teachers) {
                List<String> classes;
                try {
                    classes = advisors.identityClasses(teacher);
                } catch (RuntimeException e) {
                    continue;   // this teacher has no advisor class configured
                }
                for (String cls : classes) {
                    total.incrementAndGet();
                    Map<String, Object> overview = call(() -> advisors.overview(teacher, cls, null, null, true));
                    if (overview == null) continue;   // Portal down: the details would fail the same way
                    List<Integer> numbers = new ArrayList<>();
                    if (overview.get("students") instanceof List<?> list) {
                        for (Object o : list) {
                            if (o instanceof Map<?, ?> s && s.get("no") instanceof Number n) numbers.add(n.intValue());
                        }
                    }
                    total.addAndGet(numbers.size());
                    for (int no : numbers) {
                        call(() -> advisors.student(teacher, cls, no, null, null, true));
                    }
                }
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        log.info("Portal prewarm finished: ok={} failed={} total={} ms={}", done.get(), failed.get(), total.get(),
            System.currentTimeMillis() - start);
    }

    private Map<String, Object> call(java.util.function.Supplier<Map<String, Object>> c) throws InterruptedException {
        try {
            Map<String, Object> r = c.get();
            done.incrementAndGet();
            return r;
        } catch (RuntimeException e) {
            failed.incrementAndGet();
            return null;
        } finally {
            pause.sleep(intervalMillis);
        }
    }

    /** "N/M" for /health (N calls done, M planned); null when the warm-up is off. Never any data. */
    public String status() {
        if (!enabled) return null;
        return done.get() + "/" + total.get();
    }

    public int failedCount() { return failed.get(); }
}
