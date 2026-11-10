package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.service.StudyPlanner.*;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/** V2-N6 pure planner: ordering, deadlines, splitting, overload, regeneration. */
class StudyPlannerTest {
    static final LocalDate MON = LocalDate.of(2026, 11, 16);

    static Task assign(long id, LocalDate due) {
        return new Task("assign", id, 13L, "Bài tập " + id, due, due.isBefore(MON) ? Kind.OVERDUE : Kind.DEADLINE, 90);
    }

    static Task quiz(long id, LocalDate due) {
        return new Task("quiz", id, 13L, "Quiz " + id, due, due.isBefore(MON) ? Kind.OVERDUE : Kind.DEADLINE, 45);
    }

    static Plan plan(int budget, Task... tasks) {
        return StudyPlanner.plan(MON, budget, List.of(tasks), Map.of(), Map.of());
    }

    @Test
    void overdueFirstThenEarliestDeadlineAtLeastOneDayBefore() {
        Plan p = plan(90, quiz(2, MON.plusDays(5)), assign(1, MON.minusDays(3)), quiz(3, MON.plusDays(2)));
        assertEquals(List.of("Bài tập 1", "Quiz 3", "Quiz 2"), p.items().stream().map(Item::title).toList());
        assertEquals(MON, p.items().get(0).date());              // overdue, today ("Gỡ việc tồn")
        assertTrue(p.items().get(0).overdue());
        assertEquals(MON.plusDays(1), p.items().get(1).date());  // today full → Tue, still before Wed-1
        assertEquals(MON.plusDays(1), p.items().get(2).date());  // Tue has 45 left
        assertTrue(p.overloaded().isEmpty());
    }

    @Test
    void assignmentIsSplitIntoTwo45MinutePartsWhenNoDayHas90() {
        Plan p = plan(60, assign(1, MON.plusDays(4)));
        assertEquals(2, p.items().size());
        assertEquals(List.of(MON, MON.plusDays(1)), p.items().stream().map(Item::date).toList());
        assertEquals(List.of(1, 2), p.items().stream().map(Item::part).toList());
        assertTrue(p.items().stream().allMatch(i -> i.minutes() == 45 && i.parts() == 2));
    }

    @Test
    void overloadedWhenItCannotFitBeforeTheDeadline() {
        // 30-minute days: neither a 45-minute quiz nor a 45-minute part fits anywhere.
        Plan p = plan(30, quiz(1, MON.plusDays(3)), assign(2, MON.minusDays(1)));
        assertTrue(p.items().isEmpty());
        assertEquals(List.of("Bài tập 2", "Quiz 1"), p.overloaded().stream().map(Overload::title).toList());
    }

    @Test
    void busyWeekOverloadsTheLatestDeadline() {
        // 60 min/day, deadline Wed (must finish by Tue): two assignments need 180 min but only 120 are available.
        Plan p = plan(60, assign(1, MON.plusDays(2)), assign(2, MON.plusDays(2)));
        assertEquals(2, p.items().size()); // assignment 1 split over Mon/Tue
        assertEquals(List.of("Bài tập 2"), p.overloaded().stream().map(Overload::title).toList());
    }

    @Test
    void dueTodayMayStillBeDoneToday() {
        Plan p = plan(60, quiz(1, MON));
        assertEquals(MON, p.items().get(0).date());
    }

    @Test
    void deadlineBeyondTheHorizonIsDeferredNotOverloaded() {
        Task far = quiz(9, MON.plusDays(12));
        Plan p = StudyPlanner.plan(MON, 30, List.of(far), Map.of(), Map.of());
        assertTrue(p.overloaded().isEmpty());
        assertEquals(1, p.deferred());
    }

    @Test
    void flashcardsOnlyTodayAndSuggestionsOnlyWhenThereIsRoom() {
        Task cards = new Task("flashcards", null, null, "Ôn 4 thẻ ghi nhớ", MON, Kind.FLASHCARDS,
            StudyPlanner.flashcardMinutes(4));
        Task tip = new Task("resource", 77L, 13L, "Ôn lại: Chương 2", null, Kind.SUGGESTION, 20);
        Plan p = plan(60, quiz(1, MON.minusDays(1)), cards, tip);
        assertEquals(List.of("Quiz 1", "Ôn 4 thẻ ghi nhớ", "Ôn lại: Chương 2"), p.items().stream().map(Item::title).toList());
        assertEquals(6, p.items().get(1).minutes());
        assertEquals(MON, p.items().get(1).date());
        assertEquals(MON.plusDays(1), p.items().get(2).date()); // Monday has 60 − 45 − 6 = 9 left
        Plan small = plan(30, cards, tip);
        assertEquals(List.of(MON, MON), small.items().stream().map(Item::date).toList()); // 30 − 6 = 24 ≥ 20
        Plan full = plan(30, quiz(1, MON.minusDays(1)), cards, tip);
        assertEquals(List.of("Ôn 4 thẻ ghi nhớ", "Ôn lại: Chương 2"), full.items().stream().map(Item::title).toList());
        assertEquals(List.of("Quiz 1"), full.overloaded().stream().map(Overload::title).toList());
        assertEquals(1, full.overloaded().size()); // optional items never overload
    }

    @Test
    void regenerationKeepsDoneWorkAndItsMinutes() {
        // Part 1 of the assignment (45) was done today: only 45 remain, and today has 90 − 45 = 45 free.
        Plan p = StudyPlanner.plan(MON, 90, List.of(assign(1, MON.plusDays(4)), quiz(2, MON.plusDays(4))),
            Map.of(MON, 45), Map.of("assign:1", 45));
        assertEquals(List.of(45, 45), p.items().stream().map(Item::minutes).toList());
        assertEquals(MON, p.items().get(0).date());
        assertEquals(MON.plusDays(1), p.items().get(1).date());
        Plan finished = StudyPlanner.plan(MON, 90, List.of(assign(1, MON.plusDays(4))), Map.of(), Map.of("assign:1", 90));
        assertTrue(finished.items().isEmpty());
    }

    @Test
    void deterministicAndValidated() {
        Task[] tasks = {quiz(2, MON.plusDays(3)), quiz(1, MON.plusDays(3)), assign(3, MON.plusDays(3))};
        assertEquals(plan(90, tasks), plan(90, tasks));
        assertThrows(IllegalArgumentException.class, () -> plan(45, tasks));
        assertEquals(0, StudyPlanner.flashcardMinutes(0));
        assertEquals(2, StudyPlanner.flashcardMinutes(1));
    }
}
