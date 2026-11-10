package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.service.GradeForecastService.Forecast;
import com.dlu.lmsmobile.service.GradeForecastService.Item;
import com.dlu.lmsmobile.service.GradeForecastService.Status;
import org.junit.jupiter.api.Test;

import java.util.*;

import static org.junit.jupiter.api.Assertions.*;

/** Table-style cases for the pure grade-forecast engine. */
class GradeForecastServiceTest {
    private static final double D = 1e-6;

    /** Item in sub-category {@code cat} under root 1 (two-level tree, as in the course data). */
    static Item sub(long id, long cat) {
        return new Item(id, "Item " + id, "assign", id, cat, "Cat " + cat, 1L, 100.0, 50.0, null, false, null, null, null);
    }

    static Item root(long id) {
        return new Item(id, "Item " + id, "quiz", id, 1L, "Root", null, 100.0, 50.0, null, false, null, null, null);
    }

    static Item withCoef(Item i, double coef) {
        return new Item(i.gradeItemId(), i.name(), i.activityType(), i.sourceId(), i.categoryId(), i.categoryName(),
            i.parentCategoryId(), i.grademax(), i.gradepass(), coef, i.hidden(), i.dueTime(), i.moodlePath(), i.courseModuleId());
    }

    static Item hidden(Item i) {
        return new Item(i.gradeItemId(), i.name(), i.activityType(), i.sourceId(), i.categoryId(), i.categoryName(),
            i.parentCategoryId(), i.grademax(), i.gradepass(), i.coef(), true, i.dueTime(), i.moodlePath(), i.courseModuleId());
    }

    @Test
    void twoLevelTreeWeightsSumToOneAndFollowEachLevel() {
        // Root has 2 sub-categories: A with 4 items, B with 2 items → 1/8 each in A, 1/4 each in B.
        List<Item> items = List.of(sub(1, 10), sub(2, 10), sub(3, 10), sub(4, 10), sub(5, 20), sub(6, 20));
        Forecast f = GradeForecastService.forecast(items, Map.of());
        double sum = f.items().stream().mapToDouble(GradeForecastService.Weighted::weight).sum();
        assertEquals(1.0, sum, D);
        assertEquals(0.125, f.items().get(0).weight(), D);
        assertEquals(0.25, f.items().get(4).weight(), D);
        assertFalse(f.approximation());
    }

    @Test
    void allGradedHasNoRemainingAndCurrentIsTheFinalGrade() {
        List<Item> items = List.of(sub(1, 10), sub(2, 10), sub(3, 20));
        Forecast f = GradeForecastService.forecast(items, Map.of(1L, 80.0, 2L, 60.0, 3L, 40.0));
        // A = 70, B = 40 → final 55.
        assertEquals(55.0, f.current(), D);
        assertEquals(55.0, f.gradedContribution(), D);
        var pass = GradeForecastService.need(f, 50);
        assertEquals(Status.NO_REMAINING, pass.status());
        assertTrue(pass.reached());
        assertFalse(GradeForecastService.need(f, 60).reached());
        assertEquals("SURE_PASS", GradeForecastService.passBand(f));
    }

    @Test
    void nothingGradedNeedsTheTargetEverywhere() {
        List<Item> items = List.of(sub(1, 10), sub(2, 20));
        Forecast f = GradeForecastService.forecast(items, Map.of());
        assertNull(f.current());
        var n = GradeForecastService.need(f, 70);
        assertEquals(Status.FEASIBLE, n.status());
        assertEquals(70.0, n.need(), D);
        assertEquals(100.0, f.bestCase(), D);
    }

    @Test
    void onlyGradedCategoriesCountTowardsCurrent() {
        // A: 80 and 60 graded → 70; B: nothing graded → excluded from the current value (not zero).
        List<Item> items = List.of(sub(1, 10), sub(2, 10), sub(3, 20), sub(4, 20));
        Forecast f = GradeForecastService.forecast(items, Map.of(1L, 80.0, 2L, 60.0));
        assertEquals(70.0, f.current(), D);
        // Final = 0.5*70 + 0.5*avg(B) → for 50 overall B needs 30 on average.
        assertEquals(30.0, GradeForecastService.need(f, 50).need(), D);
        assertEquals("SAFE", GradeForecastService.passBand(f));
    }

    @Test
    void unreachableTargetIsNotFeasible() {
        List<Item> items = List.of(sub(1, 10), sub(2, 10), sub(3, 10), sub(4, 20));
        Forecast f = GradeForecastService.forecast(items, Map.of(1L, 0.0, 2L, 0.0, 3L, 0.0));
        // Graded contribution 0 with remaining weight 0.5 → 90 needs 180.
        var n = GradeForecastService.need(f, 90);
        assertEquals(Status.NOT_FEASIBLE, n.status());
        assertEquals(180.0, n.need(), D);
        assertEquals(50.0, f.bestCase(), D);
        assertEquals("SAFE", GradeForecastService.passBand(GradeForecastService.forecast(items, Map.of())));
        // Passing needs exactly 100 on the remaining half: still possible, but high risk.
        assertEquals("HIGH_RISK", GradeForecastService.passBand(f));
        Forecast lost = GradeForecastService.forecast(items, Map.of(1L, 0.0, 2L, 0.0, 3L, 0.0, 4L, 10.0));
        assertEquals("NOT_FEASIBLE", GradeForecastService.passBand(lost));
    }

    @Test
    void achievedWhenWorstCaseAlreadyMeetsTarget() {
        List<Item> items = List.of(sub(1, 10), sub(2, 20));
        Forecast f = GradeForecastService.forecast(items, Map.of(1L, 100.0));
        var n = GradeForecastService.need(f, 50);
        assertEquals(Status.ACHIEVED, n.status());
        assertTrue(n.reached());
        assertEquals("SURE_PASS", GradeForecastService.passBand(f));
    }

    @Test
    void hiddenItemsAreLeftOutOfTheTree() {
        List<Item> items = List.of(sub(1, 10), hidden(sub(2, 10)), sub(3, 20));
        Forecast f = GradeForecastService.forecast(items, Map.of(2L, 0.0));
        assertEquals(2, f.items().size());
        assertEquals(0.5, f.items().get(0).weight(), D);
        assertNull(f.current());
    }

    @Test
    void coefficientsGiveAWeightedMean() {
        List<Item> items = List.of(withCoef(root(1), 3), withCoef(root(2), 1));
        Forecast f = GradeForecastService.forecast(items, Map.of(1L, 80.0));
        assertEquals(0.75, f.items().get(0).weight(), D);
        assertEquals(0.25, f.items().get(1).weight(), D);
        // 0.75*80 = 60 → for 70 the last item needs 40.
        assertEquals(40.0, GradeForecastService.need(f, 70).need(), D);
        assertFalse(f.approximation());
        // Only one sibling weighted → equal shares, flagged as an approximation.
        Forecast mixed = GradeForecastService.forecast(List.of(withCoef(root(1), 3), root(2)), Map.of());
        assertEquals(0.5, mixed.items().get(0).weight(), D);
        assertTrue(mixed.approximation());
        // Weighted items inside a sub-category.
        Forecast inSub = GradeForecastService.forecast(
            List.of(withCoef(sub(1, 10), 1), withCoef(sub(2, 10), 3), sub(3, 20)), Map.of());
        assertEquals(0.125, inSub.items().get(0).weight(), D);
        assertEquals(0.375, inSub.items().get(1).weight(), D);
    }

    @Test
    void itemsDirectlyInRootSitBesideSubCategories() {
        List<Item> items = List.of(root(1), sub(2, 10), sub(3, 10));
        Forecast f = GradeForecastService.forecast(items, Map.of());
        assertEquals(0.5, f.items().get(0).weight(), D);
        assertEquals(0.25, f.items().get(1).weight(), D);
    }

    @Test
    void passThresholdComesFromItemsOrFallsBackToFiftyPercent() {
        assertEquals("items", GradeForecastService.forecast(List.of(sub(1, 10)), Map.of()).passSource());
        Item noPass = new Item(9, "x", "quiz", 9L, 1L, "Root", null, 10.0, 0.0, null, false, null, null, null);
        Forecast f = GradeForecastService.forecast(List.of(noPass), Map.of());
        assertEquals("default", f.passSource());
        assertEquals(50.0, f.passPercent(), D);
        Item sixty = new Item(8, "y", "quiz", 8L, 1L, "Root", null, 10.0, 6.0, null, false, null, null, null);
        assertEquals(60.0, GradeForecastService.forecast(List.of(sixty), Map.of()).passPercent(), D);
    }

    @Test
    void severalRootsAreFlaggedAsApproximation() {
        Item other = new Item(7, "z", "quiz", 7L, 99L, "Other", null, 100.0, 50.0, null, false, null, null, null);
        assertTrue(GradeForecastService.forecast(List.of(root(1), other), Map.of()).approximation());
    }

    @Test
    void bandsFollowTheDocumentedThresholds() {
        // One graded, one ungraded item of equal weight: need = 2*50 − s.
        List<Item> items = List.of(root(1), root(2));
        Map<Double, String> cases = new LinkedHashMap<>();
        cases.put(40.0, "SAFE");      // need 60
        cases.put(30.0, "EFFORT");    // need 70
        cases.put(15.0, "EFFORT");    // need 85
        cases.put(10.0, "HIGH_RISK"); // need 90
        cases.put(0.0, "HIGH_RISK");  // need 100
        for (var c : cases.entrySet()) {
            Forecast f = GradeForecastService.forecast(items, Map.of(1L, c.getKey()));
            assertEquals(c.getValue(), GradeForecastService.passBand(f), "score " + c.getKey());
        }
        assertEquals("NO_DATA", GradeForecastService.passBand(GradeForecastService.forecast(List.of(), Map.of())));
    }

    @Test
    void jsonCarriesWeightsAndNullScoresForUngradedItems() {
        Map<String, Object> json = GradeForecastService.toJson(
            GradeForecastService.forecast(List.of(sub(1, 10), sub(2, 20)), Map.of(1L, 64.0)));
        assertEquals(64.0, json.get("current"));
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> items = (List<Map<String, Object>>) json.get("items");
        assertEquals(0.5, items.get(0).get("weight"));
        assertNull(items.get(1).get("scorePercent"));
        @SuppressWarnings("unchecked")
        Map<String, Object> pass = (Map<String, Object>) json.get("pass");
        assertEquals("FEASIBLE", pass.get("status"));
        assertEquals(36.0, pass.get("need")); // (50 − 0.5·64) / 0.5
        assertEquals(82.0, json.get("bestCase"));
    }
}
