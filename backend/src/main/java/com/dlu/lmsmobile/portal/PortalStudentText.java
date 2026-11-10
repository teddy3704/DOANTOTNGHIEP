package com.dlu.lmsmobile.portal;

import com.dlu.lmsmobile.portal.PortalModels.Decision;

import java.math.BigDecimal;
import java.text.Normalizer;
import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** Small classification helpers shared by the Portal services. */
public final class PortalStudentText {
    private static final Pattern NUMBER = Pattern.compile("(\\d+)");

    private PortalStudentText() {
    }

    /** "Học kỳ 5" → 5; unknown/empty last. */
    public static int semesterOrder(String semester) {
        if (semester == null) return Integer.MAX_VALUE;
        Matcher m = NUMBER.matcher(semester);
        return m.find() ? Integer.parseInt(m.group(1)) : Integer.MAX_VALUE - 1;
    }

    /** "Cảnh báo học vụ" (any accents/case) in the decision name. */
    public static boolean isAcademicWarning(Decision d) {
        String n = fold(d.name());
        return n.contains("canh bao") && (n.contains("hoc vu") || n.contains("hoc tap"));
    }

    /** Conduct classification by final score (Thông tư 16/2015/TT-BGDĐT bands). */
    public static String conductRank(BigDecimal score) {
        if (score == null) return null;
        int s = score.intValue();
        if (s >= 90) return "Xuất sắc";
        if (s >= 80) return "Tốt";
        if (s >= 65) return "Khá";
        if (s >= 50) return "Trung bình";
        if (s >= 35) return "Yếu";
        return "Kém";
    }

    public static String fold(String s) {
        if (s == null) return "";
        String d = Normalizer.normalize(s, Normalizer.Form.NFD).replaceAll("\\p{M}", "");
        return d.replace('đ', 'd').replace('Đ', 'D').toLowerCase(Locale.ROOT);
    }
}
