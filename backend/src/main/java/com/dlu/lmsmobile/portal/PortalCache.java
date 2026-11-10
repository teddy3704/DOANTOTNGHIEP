package com.dlu.lmsmobile.portal;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Comparator;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.Supplier;

/**
 * Bounded in-memory TTL cache. Portal responses live only here, never in the database
 * (docs/V3_PORTAL_PROMPT.md §2.5). Lost on restart by design.
 */
public class PortalCache<V> {
    private record Entry<V>(V value, Instant expiresAt) {
    }

    private final Map<String, Entry<V>> map = new ConcurrentHashMap<>();
    private final Duration ttl;
    private final int maxEntries;
    private final Clock clock;

    public PortalCache(Duration ttl, int maxEntries, Clock clock) {
        this.ttl = ttl;
        this.maxEntries = Math.max(1, maxEntries);
        this.clock = clock;
    }

    /** Cached value, or the loaded one (stored only when the loader succeeds). */
    public V get(String key, Supplier<V> loader) {
        Instant now = clock.instant();
        Entry<V> e = map.get(key);
        if (e != null && now.isBefore(e.expiresAt())) return e.value();
        V value = loader.get();
        put(key, value, now);
        return value;
    }

    /** True when a fresh entry exists (used for the "cached" flag and the E2 measurements). */
    public boolean contains(String key) {
        Entry<V> e = map.get(key);
        return e != null && clock.instant().isBefore(e.expiresAt());
    }

    private void put(String key, V value, Instant now) {
        if (map.size() >= maxEntries && !map.containsKey(key)) {
            map.entrySet().removeIf(x -> !now.isBefore(x.getValue().expiresAt()));
            while (map.size() >= maxEntries) {
                map.entrySet().stream().min(Comparator.comparing(x -> x.getValue().expiresAt()))
                    .ifPresent(x -> map.remove(x.getKey()));
            }
        }
        map.put(key, new Entry<>(value, now.plus(ttl)));
    }

    public int size() {
        return map.size();
    }

    public void clear() {
        map.clear();
    }
}
