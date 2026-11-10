package com.dlu.lmsmobile.portal;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

/** Vietnamese labels for advisor flags (CSV export). */
public final class PortalAdvisorText {
    private PortalAdvisorText() {
    }

    public static List<String> flagLabels(Object flags) {
        List<String> out = new ArrayList<>();
        if (!(flags instanceof Collection<?> c)) return out;
        for (Object f : c) {
            out.add(switch (String.valueOf(f)) {
                case "LOW_GPA" -> "ĐTB<2.0";
                case "WEAK_RANK" -> "Yếu/Kém";
                case "LOW_CONDUCT" -> "Rèn luyện thấp";
                case "NO_SCORE" -> "Chưa có điểm";
                default -> String.valueOf(f);
            });
        }
        return out;
    }
}
