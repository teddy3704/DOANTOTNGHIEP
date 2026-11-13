package com.dlu.lmsmobile.service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * The watch score shared by the teacher views (class insights) and the student's own
 * "learning health" (V2-N9). Same four rules as derived.student_risk_indicator, applied to the same
 * columns, so the points add up to the stored risk_score (capped at 100).
 */
public final class RiskScore {
    public static final int NEEDS_SUPPORT = 60, WATCH = 30, MAX = 100;

    private RiskScore() {
    }

    public static List<Map<String, Object>> breakdown(Object inactive, long overdue, Double progress, long events7d) {
        return breakdown(inactive, overdue, progress, events7d, false);
    }

    /**
     * {@code handInsOnly} (real data, DataProfile): the only activity signal is a hand-in (submitted
     * assignment or finished quiz attempt) and progress counts graded activities, so the reason
     * labels say exactly that instead of "truy cập".
     */
    public static List<Map<String, Object>> breakdown(Object inactive, long overdue, Double progress, long events7d,
                                                      boolean handInsOnly) {
        List<Map<String, Object>> out = new ArrayList<>();
        int days = inactive instanceof Number n ? n.intValue() : 999;
        String never = handInsOnly ? "Chưa từng nộp bài hoặc làm bài kiểm tra" : "Chưa từng truy cập khóa học";
        String idle = handInsOnly ? " ngày chưa nộp bài hoặc làm bài kiểm tra" : " ngày không truy cập";
        String progressLabel = handInsOnly ? "Tiến độ (theo hoạt động có chấm điểm) " : "Tiến độ ";
        // Real export (REAL-DATA-2): "no hand-in for N days" only counts when the student owes work, i.e.
        // has an overdue task; nothing due (all done, or only future deadlines) is not a reason to watch.
        boolean idleCounts = !handInsOnly || overdue > 0;
        if (idleCounts && inactive == null) out.add(points(40, never, "INACTIVE"));
        else if (idleCounts && days >= 14) out.add(points(40, days + idle + " (≥14 ngày)", "INACTIVE"));
        else if (idleCounts && days >= 7) out.add(points(25, days + idle + " (7–13 ngày)", "INACTIVE"));
        if (overdue >= 3) out.add(points(30, overdue + " bài quá hạn (≥3 bài)", "OVERDUE"));
        else if (overdue >= 1) out.add(points(15, overdue + " bài quá hạn (1–2 bài)", "OVERDUE"));
        if (progress != null && progress < 30) {
            out.add(points(25, progressLabel + Math.round(progress) + "% (dưới 30%)", "LOW_PROGRESS"));
        } else if (progress != null && progress < 60) {
            out.add(points(10, progressLabel + Math.round(progress) + "% (dưới 60%)", "LOW_PROGRESS"));
        }
        if (events7d == 0 && idleCounts) {
            out.add(points(10, handInsOnly ? "Không nộp bài hoặc làm bài kiểm tra nào trong 7 ngày qua"
                : "Không có hoạt động nào trong 7 ngày qua", "NO_RECENT_EVENTS"));
        }
        return out;
    }

    public static int total(List<Map<String, Object>> breakdown) {
        int sum = breakdown.stream().mapToInt(p -> ((Number) p.get("points")).intValue()).sum();
        return Math.min(MAX, sum);
    }

    /** needs_support ≥ 60, watch ≥ 30, else on_track (same cut-offs as risk_level HIGH/MEDIUM/LOW). */
    public static String group(int score) {
        return score >= NEEDS_SUPPORT ? "needs_support" : score >= WATCH ? "watch" : "on_track";
    }

    private static Map<String, Object> points(int points, String label, String code) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("points", points);
        m.put("label", label);
        m.put("code", code);
        return m;
    }
}
