package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.exception.ResourceNotFoundException;
import com.dlu.lmsmobile.repository.ForecastRepository;
import com.dlu.lmsmobile.repository.InsightsRepository;
import org.springframework.stereotype.Service;

import java.util.*;

import static com.dlu.lmsmobile.service.Values.*;

/**
 * V2-N3 anonymous "where am I in my class". Everything is computed here; the response carries only
 * the caller's own value and class aggregates, and nothing at all for classes under
 * {@link #MIN_CLASS_SIZE} students with data.
 */
@Service
public class PeerComparisonService {
    public static final int MIN_CLASS_SIZE = 5;
    static final int BINS = 5;

    /** One value of the class; {@code mine} marks the caller's own row. Carries no identity. */
    public record Point(boolean mine, double value) {
    }

    private final ForecastRepository repository;
    private final InsightsRepository insights;

    public PeerComparisonService(ForecastRepository repository, InsightsRepository insights) {
        this.repository = repository;
        this.insights = insights;
    }

    public Map<String, Object> compare(Long userId, Long courseId) {
        if (!insights.isEnrolled(userId, courseId)) throw new ResourceNotFoundException("Student course not found");
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("courseId", courseId);
        out.put("minClassSize", MIN_CLASS_SIZE);
        out.put("progress", metric(points(repository.findClassProgress(userId, courseId), "progress_percentage")));
        out.put("grade", metric(points(repository.findClassAverageGrades(userId, courseId), "average_percentage")));
        return out;
    }

    static List<Point> points(List<Map<String, Object>> rows, String column) {
        List<Point> out = new ArrayList<>();
        for (Map<String, Object> r : rows) {
            Double v = num(r.get(column));
            if (v != null) out.add(new Point(Boolean.TRUE.equals(r.get("mine")), v));
        }
        return out;
    }

    /**
     * percentBelow = share of the other students with data whose value is strictly lower than
     * mine; median over everyone with data; histogram in five 20-point bins ([80,100] closed).
     */
    public static Map<String, Object> metric(List<Point> points) {
        Map<String, Object> out = new LinkedHashMap<>();
        int n = points.size();
        Double mine = points.stream().filter(Point::mine).map(Point::value).findFirst().orElse(null);
        out.put("classSize", n);
        if (n < MIN_CLASS_SIZE) {
            out.put("suppressed", true);
            out.put("reason", "CLASS_TOO_SMALL");
            return out;
        }
        out.put("suppressed", false);
        double[] sorted = points.stream().mapToDouble(Point::value).sorted().toArray();
        double median = n % 2 == 1 ? sorted[n / 2] : (sorted[n / 2 - 1] + sorted[n / 2]) / 2.0;
        out.put("median", round1(median));
        int[] bins = new int[BINS];
        for (Point p : points) bins[bin(p.value())]++;
        List<Map<String, Object>> histogram = new ArrayList<>();
        for (int b = 0; b < BINS; b++) {
            Map<String, Object> h = new LinkedHashMap<>();
            h.put("from", b * 20);
            h.put("to", b * 20 + 20);
            h.put("count", bins[b]);
            histogram.add(h);
        }
        out.put("histogram", histogram);
        out.put("mine", round1(mine));
        if (mine == null) {
            out.put("percentBelow", null);
            out.put("myBin", null);
        } else {
            long others = points.stream().filter(p -> !p.mine()).count();
            long below = points.stream().filter(p -> !p.mine() && p.value() < mine).count();
            out.put("percentBelow", others == 0 ? null : round1(below * 100.0 / others));
            out.put("myBin", bin(mine));
        }
        return out;
    }

    static int bin(double value) {
        int b = (int) Math.floor(Math.max(0, value) / 20.0);
        return Math.min(BINS - 1, b);
    }
}
