package com.dlu.lmsmobile.portal;

import com.dlu.lmsmobile.portal.PortalModels.*;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;

/**
 * Pure academic calculations for V3 (no I/O). Formulas are documented in docs/FEATURES_V3.md.
 */
public final class AcademicEngine {
    private AcademicEngine() {
    }

    // ================================================================ P1: GPA recalculation
    /** Latest scored attempt of each course (retakes replace earlier attempts). */
    public static Collection<CourseResult> latestAttempts(List<Term> terms) {
        Map<String, CourseResult> byCourse = new LinkedHashMap<>();
        for (Term t : terms) {
            for (CourseResult c : t.courses()) {
                if (c.courseId() != null && c.scored()) byCourse.put(c.courseId(), c);
            }
        }
        return byCourse.values();
    }

    /** Σ credits × score4 / Σ credits over courses that count for the GPA; null when none. */
    public static Gpa recompute(List<Term> terms) {
        BigDecimal points = BigDecimal.ZERO;
        int credits = 0;
        for (CourseResult c : latestAttempts(terms)) {
            if (!c.countsForGpa()) continue;
            points = points.add(c.score4().multiply(BigDecimal.valueOf(c.credits())));
            credits += c.credits();
        }
        return new Gpa(credits == 0 ? null : points.divide(BigDecimal.valueOf(credits), 4, RoundingMode.HALF_UP), credits);
    }

    public record Gpa(BigDecimal gpa4, int credits) {
    }

    /** Last term that has at least one score: the "data until" mark (the data is static). */
    public static Optional<Term> latestScoredTerm(List<Term> terms) {
        for (int i = terms.size() - 1; i >= 0; i--) if (terms.get(i).hasScores()) return Optional.of(terms.get(i));
        return Optional.empty();
    }

    // ================================================================ P3: conversion table
    /** One letter grade: lower bound on the 10-point scale and its 4-point value. */
    public record Grade(String letter, BigDecimal min10, BigDecimal max10, BigDecimal score4, boolean derived) {
    }

    /** Default A/B/C/D/F table (credit system without plus grades), used where the transcript has no evidence. */
    public static final List<Grade> DEFAULT_TABLE = List.of(
        new Grade("A", new BigDecimal("8.5"), new BigDecimal("10"), new BigDecimal("4"), false),
        new Grade("B", new BigDecimal("7.0"), new BigDecimal("8.4"), new BigDecimal("3"), false),
        new Grade("C", new BigDecimal("5.5"), new BigDecimal("6.9"), new BigDecimal("2"), false),
        new Grade("D", new BigDecimal("4.0"), new BigDecimal("5.4"), new BigDecimal("1"), false),
        new Grade("F", BigDecimal.ZERO, new BigDecimal("3.9"), BigDecimal.ZERO, false));

    /**
     * Table inferred from the student's own transcript: for each letter the smallest and largest
     * DiemTK_10 seen and its DiemTK_4. Letters never seen keep the default row (derived=false).
     * Sorted from best to worst.
     */
    public static List<Grade> conversionTable(List<Term> terms) {
        Map<String, BigDecimal[]> seen = new HashMap<>();
        for (Term t : terms) {
            for (CourseResult c : t.courses()) {
                if (c.letter() == null || c.score10() == null || c.score4() == null) continue;
                String l = c.letter().trim().toUpperCase(Locale.ROOT);
                BigDecimal[] mm = seen.computeIfAbsent(l, k -> new BigDecimal[]{c.score10(), c.score10(), c.score4()});
                if (c.score10().compareTo(mm[0]) < 0) mm[0] = c.score10();
                if (c.score10().compareTo(mm[1]) > 0) mm[1] = c.score10();
            }
        }
        Map<String, Grade> out = new LinkedHashMap<>();
        for (Grade d : DEFAULT_TABLE) out.put(d.letter(), d);
        seen.forEach((l, mm) -> out.put(l, new Grade(l, mm[0], mm[1], mm[2], true)));
        List<Grade> list = new ArrayList<>(out.values());
        list.sort(Comparator.comparing(Grade::score4).reversed().thenComparing(Grade::min10, Comparator.reverseOrder()));
        return list;
    }

    /**
     * Letter for a 10-point score: the best letter whose lower bound (smallest observed, or the
     * default) the score reaches. A score between two observed bands falls to the lower letter.
     */
    public static Grade toGrade(BigDecimal score10, List<Grade> table) {
        if (score10 == null) return null;
        for (Grade g : table) if (score10.compareTo(g.min10()) >= 0) return g;
        return table.get(table.size() - 1);
    }

    // ================================================================ P3: targets
    public enum TargetStatus { ACHIEVED, FEASIBLE, NOT_FEASIBLE }

    public record Target(String band, BigDecimal min, BigDecimal needed, TargetStatus status) {
    }

    /**
     * Average 4-point score needed on {@code remainingCredits} so that the cumulative GPA reaches
     * each band: need = (band × (C + R) − GPA × C) / R. need ≤ 0 → ACHIEVED, ≤ 4 → FEASIBLE.
     * With no remaining credits a band is ACHIEVED when the GPA already reaches it.
     */
    public static List<Target> targets(BigDecimal gpa4, int credits, int remainingCredits,
                                       List<PortalProperties.GradeBand> bands) {
        List<Target> out = new ArrayList<>();
        BigDecimal g = gpa4 == null ? BigDecimal.ZERO : gpa4;
        for (PortalProperties.GradeBand b : bands) {
            if (remainingCredits <= 0) {
                boolean ok = g.compareTo(b.getMin()) >= 0;
                out.add(new Target(b.getName(), b.getMin(), null, ok ? TargetStatus.ACHIEVED : TargetStatus.NOT_FEASIBLE));
                continue;
            }
            BigDecimal need = b.getMin().multiply(BigDecimal.valueOf(credits + remainingCredits))
                .subtract(g.multiply(BigDecimal.valueOf(credits)))
                .divide(BigDecimal.valueOf(remainingCredits), 4, RoundingMode.HALF_UP);
            TargetStatus s = need.signum() <= 0 ? TargetStatus.ACHIEVED
                : need.compareTo(BigDecimal.valueOf(4)) <= 0 ? TargetStatus.FEASIBLE : TargetStatus.NOT_FEASIBLE;
            out.add(new Target(b.getName(), b.getMin(), need, s));
        }
        return out;
    }

    /** Cumulative GPA after adding courses with known 4-point scores. */
    public static BigDecimal project(BigDecimal gpa4, int credits, Map<Integer, BigDecimal> addedCreditsToScore4) {
        BigDecimal points = (gpa4 == null ? BigDecimal.ZERO : gpa4).multiply(BigDecimal.valueOf(credits));
        int total = credits;
        for (Map.Entry<Integer, BigDecimal> e : addedCreditsToScore4.entrySet()) {
            points = points.add(e.getValue().multiply(BigDecimal.valueOf(e.getKey())));
            total += e.getKey();
        }
        return total == 0 ? null : points.divide(BigDecimal.valueOf(total), 4, RoundingMode.HALF_UP);
    }

    /** The highest band the GPA reaches, or null. */
    public static String bandOf(BigDecimal gpa4, List<PortalProperties.GradeBand> bands) {
        if (gpa4 == null) return null;
        for (PortalProperties.GradeBand b : bands) if (gpa4.compareTo(b.getMin()) >= 0) return b.getName();
        return null;
    }

    // ================================================================ P2: program progress
    public enum CourseStatus { PASSED, FAILED, IN_LMS, IN_PROGRESS, NOT_TAKEN }

    public record ProgramItem(ProgramCourse course, CourseStatus status, BigDecimal score10, String letter,
                              Long lmsCourseId, List<String> missingPrerequisites) {
    }

    /**
     * Status of each program course. Order of precedence: passed → failed → mapped to a Moodle
     * course → registered on the Portal without a score → not taken.
     * Missing prerequisites: HPTienQuyet codes not yet passed and HPHocTruoc codes never attempted.
     */
    public static List<ProgramItem> programStatus(List<ProgramCourse> program, List<Term> terms,
                                                  Map<String, Long> lmsByCode) {
        Map<String, CourseResult> latest = new HashMap<>();
        Set<String> attempted = new HashSet<>();
        Set<String> registered = new HashSet<>();
        for (Term t : terms) {
            for (CourseResult c : t.courses()) {
                if (c.courseId() == null) continue;
                String code = c.courseId().toUpperCase(Locale.ROOT);
                registered.add(code);
                if (c.scored()) {
                    attempted.add(code);
                    latest.put(code, c);
                }
            }
        }
        Set<String> passed = new HashSet<>();
        latest.forEach((code, c) -> {
            if (c.passed()) passed.add(code);
        });
        List<ProgramItem> out = new ArrayList<>();
        for (ProgramCourse pc : program) {
            String code = pc.code() == null ? "" : pc.code().toUpperCase(Locale.ROOT);
            CourseResult r = latest.get(code);
            Long lms = lmsByCode.get(code);
            CourseStatus s;
            if (passed.contains(code)) s = CourseStatus.PASSED;
            else if (r != null) s = CourseStatus.FAILED;
            else if (lms != null) s = CourseStatus.IN_LMS;
            else if (registered.contains(code)) s = CourseStatus.IN_PROGRESS;
            else s = CourseStatus.NOT_TAKEN;
            List<String> missing = new ArrayList<>();
            for (String p : pc.prerequisites()) if (!passed.contains(p)) missing.add(p);
            for (String p : pc.priorCourses()) if (!attempted.contains(p) && !passed.contains(p) && !missing.contains(p)) missing.add(p);
            out.add(new ProgramItem(pc, s, r == null ? null : r.score10(), r == null ? null : r.letter(), lms, missing));
        }
        return out;
    }

    /** Distinct program courses: base program first, then the specialisation (same code kept once). */
    public static List<ProgramCourse> merge(List<ProgramCourse> base, List<ProgramCourse> specialisation) {
        Map<String, ProgramCourse> m = new LinkedHashMap<>();
        for (ProgramCourse c : base) if (c.code() != null) m.putIfAbsent(c.code().toUpperCase(Locale.ROOT), c);
        for (ProgramCourse c : specialisation) if (c.code() != null) m.putIfAbsent(c.code().toUpperCase(Locale.ROOT), c);
        return new ArrayList<>(m.values());
    }

    /** "CQ23CT-PM" → "CQ23CT"; a program without a specialisation suffix has no base. */
    public static Optional<String> baseProgram(String programId) {
        if (programId == null) return Optional.empty();
        int i = programId.indexOf('-');
        return i > 0 ? Optional.of(programId.substring(0, i)) : Optional.empty();
    }

    public static int credits(ProgramCourse c) {
        return c.credits() == null ? 0 : c.credits();
    }
}
