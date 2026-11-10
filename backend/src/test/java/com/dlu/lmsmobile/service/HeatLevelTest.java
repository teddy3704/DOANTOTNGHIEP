package com.dlu.lmsmobile.service;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class HeatLevelTest {
    @Test
    void fourLevelsByQuarterOfTheMaximum() {
        long[][] cases = {
            // events, max, level
            {0, 9, 0}, {1, 0, 0}, {-1, 9, 0},
            {1, 100, 1}, {25, 100, 1}, {26, 100, 2}, {50, 100, 2}, {51, 100, 3},
            {75, 100, 3}, {76, 100, 4}, {100, 100, 4}, {150, 100, 4},
        };
        for (long[] c : cases) {
            assertEquals((int) c[2], ClassInsightsService.heatLevel(c[0], c[1]), c[0] + "/" + c[1]);
        }
    }
}
