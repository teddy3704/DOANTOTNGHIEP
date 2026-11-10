package com.dlu.lmsmobile.portal;

import com.fasterxml.jackson.databind.JsonNode;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.time.format.ResolverStyle;

/**
 * Tolerant parsing of Portal values: numbers often arrive as strings ("2.77", "3"), "" means
 * missing, dates are dd/MM/yyyy. Anything unparseable becomes null instead of failing.
 */
public final class PortalValues {
    private static final DateTimeFormatter DMY = DateTimeFormatter.ofPattern("dd/MM/uuuu")
        .withResolverStyle(ResolverStyle.STRICT);

    private PortalValues() {
    }

    public static String text(JsonNode n) {
        if (n == null || n.isNull() || n.isMissingNode() || n.isContainerNode()) return null;
        String s = n.asText().trim();
        return s.isEmpty() ? null : s;
    }

    public static String text(JsonNode parent, String field) {
        return parent == null ? null : text(parent.get(field));
    }

    public static BigDecimal decimal(JsonNode n) {
        if (n == null || n.isNull() || n.isMissingNode()) return null;
        if (n.isNumber()) return n.decimalValue();
        String s = text(n);
        if (s == null) return null;
        try {
            return new BigDecimal(s.replace(',', '.'));
        } catch (NumberFormatException e) {
            return null;
        }
    }

    public static BigDecimal decimal(JsonNode parent, String field) {
        return parent == null ? null : decimal(parent.get(field));
    }

    public static Integer integer(JsonNode parent, String field) {
        BigDecimal d = decimal(parent, field);
        if (d == null) return null;
        try {
            return d.intValueExact();
        } catch (ArithmeticException e) {
            return null;
        }
    }

    /** true/"true"/"True"/1/"1" → true; false/"false"/0/"0" → false; otherwise null. */
    public static Boolean bool(JsonNode parent, String field) {
        JsonNode n = parent == null ? null : parent.get(field);
        if (n == null || n.isNull() || n.isMissingNode()) return null;
        if (n.isBoolean()) return n.booleanValue();
        String s = text(n);
        if (s == null) return null;
        return switch (s.toLowerCase()) {
            case "true", "1", "x", "yes" -> true;
            case "false", "0", "no" -> false;
            default -> null;
        };
    }

    public static LocalDate date(JsonNode parent, String field) {
        String s = text(parent, field);
        if (s == null) return null;
        String day = s.length() > 10 ? s.substring(0, 10) : s;
        try {
            return LocalDate.parse(day, DMY);
        } catch (DateTimeParseException e) {
            return null;
        }
    }

    /** "2399Z001" → "23**Z0**": keeps characters 0–1, 4–5, 8–9 … (presentation mode). */
    public static String maskId(String id) {
        if (id == null) return null;
        StringBuilder b = new StringBuilder(id.length());
        for (int i = 0; i < id.length(); i++) b.append(i % 4 < 2 ? id.charAt(i) : '*');
        return b.toString();
    }
}
