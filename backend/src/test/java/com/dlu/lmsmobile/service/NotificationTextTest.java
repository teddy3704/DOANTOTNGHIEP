package com.dlu.lmsmobile.service;

import org.junit.jupiter.api.Test;

import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;

class NotificationTextTest {
    private static Map<String, Object> row(String title, String message) {
        Map<String, Object> m = new HashMap<>();
        m.put("title", title);
        m.put("message", message);
        NotificationText.localize(m);
        return m;
    }

    @Test
    void teacherRiskAlertIsVietnamese() {
        Map<String, Object> m = row("Students need attention", "1 student(s) are currently classified as high learning risk.");
        assertEquals("Sinh viên cần được hỗ trợ", m.get("title"));
        assertEquals("Có 1 sinh viên đang ở nhóm Cần hỗ trợ (điểm theo dõi từ 60 trở lên). "
            + "Nhấn vào thông báo để mở trang Phân tích của khóa học và xem lý do, danh sách.", m.get("message"));
    }

    @Test
    void studentSystemNotificationsAreVietnamese() {
        assertEquals("\"Android Quiz\" sắp đến hạn nộp. Hãy hoàn thành trước hạn.",
            row("Quiz deadline approaching", "Android Quiz is approaching its deadline.").get("message"));
        assertEquals("Tiếp tục học", row("Continue learning", "x").get("title"));
        assertEquals("Gần đây bạn chưa vào môn Java Programming. Hãy vào khóa học để cập nhật bài.",
            row("Continue learning", "You have not accessed Java Programming recently.").get("message"));
        assertEquals("Đã có điểm \"Database Design Assignment\". Mở khóa học để xem chi tiết.",
            row("Grade updated", "Your Database Design Assignment grade is available.").get("message"));
    }

    @Test
    void teacherWrittenTextIsLeftAlone() {
        Map<String, Object> m = row("Nhắc nộp bài: Quiz 5.2", "Em chưa nộp bài kiểm tra.");
        assertEquals("Nhắc nộp bài: Quiz 5.2", m.get("title"));
        assertEquals("Em chưa nộp bài kiểm tra.", m.get("message"));
    }
}
