package com.dlu.lmsmobile.service;

import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Vietnamese wording for the system notifications that were stored in English. The stored
 * rows are left untouched (the teacher/student split still filters on the English title);
 * only what the app receives is translated. Text that matches no known pattern, such as a
 * reminder a teacher wrote, passes through unchanged.
 */
final class NotificationText {
    private NotificationText() {
    }

    private record Rule(Pattern pattern, Function<Matcher, String> text) {
    }

    private static Rule rule(String regex, Function<Matcher, String> text) {
        return new Rule(Pattern.compile(regex), text);
    }

    private static final Map<String, String> TITLES = Map.of(
        "Students need attention", "Sinh viên cần được hỗ trợ",
        "Quiz deadline approaching", "Bài kiểm tra sắp hết hạn",
        "Assignment deadline approaching", "Bài tập sắp hết hạn",
        "Continue learning", "Tiếp tục học",
        "Grade updated", "Có điểm mới");

    private static final List<Rule> MESSAGES = List.of(
        rule("^(\\d+) student\\(s\\) (?:are|is) currently classified as high learning risk\\.?$",
            m -> "Có " + m.group(1) + " sinh viên đang ở nhóm Cần hỗ trợ (điểm theo dõi từ 60 trở lên). "
                + "Nhấn vào thông báo để mở trang Phân tích của khóa học và xem lý do, danh sách."),
        rule("^(.+) is approaching its deadline\\.?$",
            m -> "\"" + m.group(1) + "\" sắp đến hạn nộp. Hãy hoàn thành trước hạn."),
        rule("^Your (.+) learning activity has been inactive\\.?$",
            m -> "Đã một thời gian bạn chưa học môn " + m.group(1) + ". Hãy vào khóa học để theo kịp lớp."),
        rule("^You have not accessed (.+) recently\\.?$",
            m -> "Gần đây bạn chưa vào môn " + m.group(1) + ". Hãy vào khóa học để cập nhật bài."),
        rule("^Your (.+) grade is available\\.?$",
            m -> "Đã có điểm \"" + m.group(1) + "\". Mở khóa học để xem chi tiết."));

    /** Translates title and message in place. */
    static void localize(Map<String, Object> row) {
        if (row.get("title") instanceof String title) {
            String vi = TITLES.get(title.trim());
            if (vi != null) row.put("title", vi);
            else if (title.startsWith("Teacher ")) row.put("title", "Giảng viên: " + title.substring(8));
        }
        if (row.get("message") instanceof String message) {
            for (Rule r : MESSAGES) {
                Matcher m = r.pattern().matcher(message.trim());
                if (m.matches()) {
                    row.put("message", r.text().apply(m));
                    break;
                }
            }
        }
    }
}
