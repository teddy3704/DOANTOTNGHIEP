package com.dlu.lmsmobile.service;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * V2-N5: SM-2 spaced-repetition step as a pure function (docs/FEATURES_V2.md).
 * <ul>
 *   <li>q &lt; 3: repetitions = 0, interval = 1 day.</li>
 *   <li>q &ge; 3: repetitions + 1; interval 1 day (1st), 6 days (2nd), then round(interval × EF).</li>
 *   <li>EF' = EF + (0.1 − (5−q)(0.08 + (5−q)·0.02)), never below 1.3, rounded to 2 decimals
 *       (column app.flashcard_reviews.ease_factor is numeric(4,2)).</li>
 * </ul>
 * The interval of the 3rd+ repetition uses the EF from before this answer (original SM-2 order).
 */
public final class Sm2 {
    public static final double START_EF = 2.5;
    public static final double MIN_EF = 1.3;
    /** Buttons: Quên = 1, Khó = 3, Được = 4, Dễ = 5. */
    public static final List<Integer> RATINGS = List.of(1, 3, 4, 5);
    /** Upper bound so an extreme EF chain can never overflow the int column (about 100 years). */
    static final int MAX_INTERVAL_DAYS = 36_500;

    private Sm2() {
    }

    public record State(int repetitions, double easeFactor, int intervalDays) {
        public static final State NEW = new State(0, START_EF, 0);
    }

    public static State next(State s, int q) {
        if (q < 0 || q > 5) throw new IllegalArgumentException("SM-2 rating must be 0..5");
        int d = 5 - q;
        double ef = Math.max(MIN_EF, Math.round((s.easeFactor() + (0.1 - d * (0.08 + d * 0.02))) * 100.0) / 100.0);
        if (q < 3) return new State(0, ef, 1);
        int reps = s.repetitions() + 1;
        long interval = switch (reps) {
            case 1 -> 1;
            case 2 -> 6;
            default -> Math.round(Math.max(1, s.intervalDays()) * s.easeFactor());
        };
        return new State(reps, ef, (int) Math.min(MAX_INTERVAL_DAYS, interval));
    }

    /** Next interval in days for each button, shown on the button before the student answers. */
    public static Map<Integer, Integer> preview(State s) {
        Map<Integer, Integer> out = new LinkedHashMap<>();
        for (int q : RATINGS) out.put(q, next(s, q).intervalDays());
        return out;
    }
}
