package com.dlu.lmsmobile.service;

import java.time.LocalDate;
import java.util.*;

/**
 * V2-N6 weekly study plan as a pure, deterministic function (docs/FEATURES_V2.md §N6).
 * <ol>
 *   <li>Overdue tasks first ("Gỡ việc tồn"), then today's flashcards, then tasks by earliest due date,
 *       then study suggestions; ties by course, source id, title.</li>
 *   <li>Each item goes to the earliest day with enough free minutes and at least one day before its
 *       due date (due today/tomorrow: today at the latest; overdue: any day of the horizon).</li>
 *   <li>An assignment that fits no single day may be split into two 45-minute parts on two days.</li>
 *   <li>A deadline task that cannot be placed in time is reported as overloaded; a task whose
 *       deadline lies beyond the 7-day horizon is only deferred.</li>
 * </ol>
 */
public final class StudyPlanner {
    public static final List<Integer> BUDGETS = List.of(30, 60, 90, 120);
    public static final int HORIZON_DAYS = 7;
    public static final int LOOKAHEAD_DAYS = 14;
    public static final int ASSIGN_MINUTES = 90, QUIZ_MINUTES = 45, RESOURCE_MINUTES = 20, SPLIT_MINUTES = 45;
    public static final double MINUTES_PER_CARD = 1.5;

    private StudyPlanner() {
    }

    public enum Kind { OVERDUE, FLASHCARDS, DEADLINE, SUGGESTION }

    /** Something to schedule. {@code due} is the due date (null for suggestions/flashcards). */
    public record Task(String sourceType, Long sourceId, Long courseId, String title, LocalDate due, Kind kind,
                       int minutes) {
        String key() {
            return sourceType + ":" + sourceId;
        }
    }

    public record Item(LocalDate date, String sourceType, Long sourceId, Long courseId, String title, int minutes,
                       int part, int parts, boolean overdue) {
    }

    public record Overload(String sourceType, Long sourceId, Long courseId, String title, LocalDate due, int minutes) {
    }

    public record Plan(LocalDate from, int dailyMinutes, List<Item> items, List<Overload> overloaded, int deferred) {
    }

    public static int estimate(String sourceType) {
        return switch (sourceType) {
            case "assign" -> ASSIGN_MINUTES;
            case "quiz" -> QUIZ_MINUTES;
            default -> RESOURCE_MINUTES;
        };
    }

    public static int flashcardMinutes(int cards) {
        return cards <= 0 ? 0 : (int) Math.ceil(cards * MINUTES_PER_CARD);
    }

    /**
     * @param alreadyUsed minutes per day already taken by items marked done (kept on regeneration)
     * @param doneMinutes minutes already done per task key ("type:id"), subtracted from its estimate
     */
    public static Plan plan(LocalDate today, int dailyMinutes, List<Task> tasks, Map<LocalDate, Integer> alreadyUsed,
                            Map<String, Integer> doneMinutes) {
        if (!BUDGETS.contains(dailyMinutes)) throw new IllegalArgumentException("dailyMinutes must be one of " + BUDGETS);
        LocalDate end = today.plusDays(HORIZON_DAYS - 1L);
        int[] free = new int[HORIZON_DAYS];
        for (int i = 0; i < HORIZON_DAYS; i++) {
            free[i] = Math.max(0, dailyMinutes - alreadyUsed.getOrDefault(today.plusDays(i), 0));
        }
        List<Task> ordered = new ArrayList<>(tasks);
        ordered.sort(Comparator.comparing(Task::kind)
            .thenComparing(Task::due, Comparator.nullsLast(Comparator.naturalOrder()))
            .thenComparing(Task::courseId, Comparator.nullsLast(Comparator.naturalOrder()))
            .thenComparing(Task::sourceId, Comparator.nullsLast(Comparator.naturalOrder()))
            .thenComparing(Task::title, Comparator.nullsLast(Comparator.naturalOrder())));

        List<Item> items = new ArrayList<>();
        List<Overload> overloaded = new ArrayList<>();
        int deferred = 0;
        for (Task t : ordered) {
            int minutes = t.minutes() - doneMinutes.getOrDefault(t.key(), 0);
            if (minutes <= 0) continue;
            int last = lastDay(today, end, t);
            boolean overdue = t.kind() == Kind.OVERDUE;
            int day = firstFit(free, 0, last, minutes);
            if (day >= 0) {
                free[day] -= minutes;
                items.add(new Item(today.plusDays(day), t.sourceType(), t.sourceId(), t.courseId(), t.title(), minutes,
                    1, 1, overdue));
                continue;
            }
            if ("assign".equals(t.sourceType()) && minutes == ASSIGN_MINUTES) {
                int d1 = firstFit(free, 0, last, SPLIT_MINUTES);
                int d2 = d1 < 0 ? -1 : firstFit(free, d1 + 1, last, SPLIT_MINUTES);
                if (d2 >= 0) {
                    free[d1] -= SPLIT_MINUTES;
                    free[d2] -= SPLIT_MINUTES;
                    items.add(new Item(today.plusDays(d1), t.sourceType(), t.sourceId(), t.courseId(), t.title(),
                        SPLIT_MINUTES, 1, 2, overdue));
                    items.add(new Item(today.plusDays(d2), t.sourceType(), t.sourceId(), t.courseId(), t.title(),
                        SPLIT_MINUTES, 2, 2, overdue));
                    continue;
                }
            }
            switch (t.kind()) {
                case OVERDUE -> overloaded.add(overload(t, minutes));
                case DEADLINE -> {
                    if (t.due() != null && t.due().minusDays(1).isAfter(end)) deferred++;
                    else overloaded.add(overload(t, minutes));
                }
                default -> {
                    /* flashcards and suggestions are optional: dropped when there is no room */
                }
            }
        }
        items.sort(Comparator.comparing(Item::date));
        return new Plan(today, dailyMinutes, items, overloaded, deferred);
    }

    /** Index of the last day the task may be placed on. */
    static int lastDay(LocalDate today, LocalDate end, Task t) {
        return switch (t.kind()) {
            case FLASHCARDS -> 0;
            case OVERDUE, SUGGESTION -> HORIZON_DAYS - 1;
            case DEADLINE -> {
                if (t.due() == null) yield HORIZON_DAYS - 1;
                LocalDate latest = t.due().minusDays(1);
                if (latest.isBefore(today)) yield 0;           // due today: today is the only chance
                if (latest.isAfter(end)) yield HORIZON_DAYS - 1;
                yield (int) (latest.toEpochDay() - today.toEpochDay());
            }
        };
    }

    private static int firstFit(int[] free, int from, int to, int minutes) {
        for (int i = from; i <= to && i < free.length; i++) if (free[i] >= minutes) return i;
        return -1;
    }

    private static Overload overload(Task t, int minutes) {
        return new Overload(t.sourceType(), t.sourceId(), t.courseId(), t.title(), t.due(), minutes);
    }
}
