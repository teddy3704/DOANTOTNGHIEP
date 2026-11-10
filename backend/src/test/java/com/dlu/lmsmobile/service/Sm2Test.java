package com.dlu.lmsmobile.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/** Table tests for the pure SM-2 step (V2-N5). Expected values computed by hand from the formula. */
class Sm2Test {
    @ParameterizedTest(name = "[{index}] reps={0} ef={1} I={2} q={3} -> reps={4} ef={5} I={6}")
    @CsvSource({
        // new card, each button
        "0, 2.50, 0, 1, 0, 1.96, 1",
        "0, 2.50, 0, 3, 1, 2.36, 1",
        "0, 2.50, 0, 4, 1, 2.50, 1",
        "0, 2.50, 0, 5, 1, 2.60, 1",
        // second success -> 6 days
        "1, 2.50, 1, 4, 2, 2.50, 6",
        // third success -> round(6 * old EF)
        "2, 2.50, 6, 4, 3, 2.50, 15",
        "2, 2.60, 6, 5, 3, 2.70, 16",
        "3, 2.50, 15, 3, 4, 2.36, 38",
        // forgot after a long streak: back to 1 day, EF drops
        "5, 2.50, 40, 1, 0, 1.96, 1",
        // EF clamped at 1.3
        "0, 1.30, 0, 1, 0, 1.30, 1",
        "4, 1.40, 10, 3, 5, 1.30, 14",
    })
    void step(int reps, double ef, int interval, int q, int eReps, double eEf, int eInterval) {
        Sm2.State n = Sm2.next(new Sm2.State(reps, ef, interval), q);
        assertEquals(eReps, n.repetitions());
        assertEquals(eEf, n.easeFactor(), 1e-9);
        assertEquals(eInterval, n.intervalDays());
    }

    @Test
    void repeatedSuccessThenForgetThenRelearn() {
        Sm2.State s = Sm2.State.NEW;
        int[] expected = {1, 6, 15, 38, 95};
        for (int e : expected) {
            s = Sm2.next(s, 4);
            assertEquals(e, s.intervalDays());
            assertEquals(2.50, s.easeFactor(), 1e-9);
        }
        s = Sm2.next(s, 1);
        assertEquals(0, s.repetitions());
        assertEquals(1, s.intervalDays());
        assertEquals(1.96, s.easeFactor(), 1e-9);
        s = Sm2.next(s, 4);
        assertEquals(1, s.intervalDays());
        s = Sm2.next(s, 4);
        assertEquals(6, s.intervalDays());
        s = Sm2.next(s, 4);
        assertEquals(12, s.intervalDays()); // round(6 * 1.96) = 11.76 -> 12
    }

    @Test
    void manyHardAnswersNeverGoBelowMinimumEase() {
        Sm2.State s = Sm2.State.NEW;
        for (int i = 0; i < 30; i++) s = Sm2.next(s, 3);
        assertEquals(Sm2.MIN_EF, s.easeFactor(), 1e-9);
        for (int i = 0; i < 5; i++) s = Sm2.next(s, 1);
        assertEquals(Sm2.MIN_EF, s.easeFactor(), 1e-9);
    }

    @Test
    void intervalIsCapped() {
        Sm2.State s = new Sm2.State(50, 2.5, 30_000);
        assertEquals(Sm2.MAX_INTERVAL_DAYS, Sm2.next(s, 5).intervalDays());
    }

    @Test
    void previewGivesOneIntervalPerButton() {
        assertEquals(Map.of(1, 1, 3, 1, 4, 1, 5, 1), Sm2.preview(Sm2.State.NEW));
        assertEquals(Map.of(1, 1, 3, 15, 4, 15, 5, 15), Sm2.preview(new Sm2.State(2, 2.5, 6)));
    }

    @Test
    void ratingOutsideRangeIsRejected() {
        assertThrows(IllegalArgumentException.class, () -> Sm2.next(Sm2.State.NEW, 6));
        assertThrows(IllegalArgumentException.class, () -> Sm2.next(Sm2.State.NEW, -1));
    }
}
