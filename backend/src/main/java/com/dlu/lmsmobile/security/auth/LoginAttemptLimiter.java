package com.dlu.lmsmobile.security.auth;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Iterator;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * In-memory brute-force guard: {@code maxFailures} wrong attempts within {@code window} for the same login and
 * client address lock that pair until the oldest failure leaves the window. A success clears the pair.
 */
public class LoginAttemptLimiter {
    private static final int MAX_KEYS = 10_000;
    private final Clock clock;
    private final int maxFailures;
    private final Duration window;
    private final Map<String, Deque<Instant>> failures = new ConcurrentHashMap<>();

    public LoginAttemptLimiter(Clock clock, int maxFailures, Duration window) {
        if (maxFailures < 1 || window.isNegative() || window.isZero()) throw new IllegalArgumentException("limits");
        this.clock = clock;
        this.maxFailures = maxFailures;
        this.window = window;
    }

    public static String key(String login, String client) {
        return LocalCredentialProvider.normalize(login) + "|" + client;
    }

    /** Seconds until the pair may try again; 0 when it is not locked. */
    public long retryAfterSeconds(String key) {
        Deque<Instant> d = failures.get(key);
        if (d == null) return 0;
        synchronized (d) {
            prune(d);
            if (d.size() < maxFailures) return 0;
            long s = Duration.between(clock.instant(), d.peekFirst().plus(window)).toSeconds();
            return Math.max(1, s);
        }
    }

    public void recordFailure(String key) {
        if (failures.size() > MAX_KEYS) evictExpired();
        Deque<Instant> d = failures.computeIfAbsent(key, k -> new ArrayDeque<>());
        synchronized (d) {
            prune(d);
            d.addLast(clock.instant());
            while (d.size() > maxFailures) d.removeFirst();
        }
    }

    public void recordSuccess(String key) {
        failures.remove(key);
    }

    private void prune(Deque<Instant> d) {
        Instant cutoff = clock.instant().minus(window);
        while (!d.isEmpty() && !d.peekFirst().isAfter(cutoff)) d.removeFirst();
    }

    private void evictExpired() {
        for (Iterator<Map.Entry<String, Deque<Instant>>> it = failures.entrySet().iterator(); it.hasNext(); ) {
            Deque<Instant> d = it.next().getValue();
            synchronized (d) {
                prune(d);
                if (d.isEmpty()) it.remove();
            }
        }
    }
}
