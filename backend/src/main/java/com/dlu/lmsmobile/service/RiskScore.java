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
        List<Map<String, Object>> out = new ArrayList<>();
        int days = inactive instanceof Number n ? n.intValue() : 999;
        if (inactive == null) out.add(points(40, "Chưa từng truy cập khóa học", "INACTIVE"));
        else if (days >= 14) out.add(points(40, days + " ngày không truy cập (≥14 ngày)", "INACTIVE"));
        else if (days >= 7) out.add(points(25, days + " ngày không truy cập (7–13 ngày)", "INACTIVE"));
        if (overdue >= 3) out.add(points(30, overdue + " bài quá hạn (≥3 bài)", "OVERDUE"));
        else if (overdue >= 1) out.add(points(15, overdue + " bài quá hạn (1–2 bài)", "OVERDUE"));
        if (progress != null && progress < 30) {
            out.add(points(25, "Tiến độ " + Math.round(progress) + "% (dưới 30%)", "LOW_PROGRESS"));
        } else if (progress != null && progress < 60) {
            out.add(points(10, "Tiến độ " + Math.round(progress) + "% (dưới 60%)", "LOW_PROGRESS"));
        }
        if (events7d == 0) out.add(points(10, "Không có hoạt động nào trong 7 ngày qua", "NO_RECENT_EVENTS"));
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
