package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.exception.InvalidRequestException;
import com.dlu.lmsmobile.repository.NotificationPreferenceRepository;
import com.dlu.lmsmobile.repository.NotificationPreferenceRepository.Prefs;
import org.junit.jupiter.api.Test;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.*;

class NotificationPreferenceServiceTest {
    private final NotificationPreferenceRepository repo = mock(NotificationPreferenceRepository.class);
    private final NotificationPreferenceService service = new NotificationPreferenceService(repo);

    private static Map<String, Object> row(boolean push, boolean assign, boolean quiz, boolean learn, int hours) {
        Map<String, Object> r = new HashMap<>();
        r.put("push_enabled", push);
        r.put("assignment_reminder_enabled", assign);
        r.put("quiz_reminder_enabled", quiz);
        r.put("learning_reminder_enabled", learn);
        r.put("default_reminder_before_hours", hours);
        return r;
    }

    @Test
    void noRowReturnsTableDefaultsWithoutWriting() {
        when(repo.find(205L)).thenReturn(List.of());
        Map<String, Object> out = service.get(205L);
        assertEquals(true, out.get("pushEnabled"));
        assertEquals(true, out.get("learningReminder"));
        assertEquals(24, out.get("reminderBeforeHours"));
        assertEquals(false, out.get("stored"));
        verify(repo, never()).upsert(anyLong(), any());
    }

    @Test
    void storedRowIsReturnedAsIs() {
        when(repo.find(101L)).thenReturn(List.of(row(true, false, false, false, 24)));
        Map<String, Object> out = service.get(101L);
        assertEquals(false, out.get("assignmentReminder"));
        assertEquals(false, out.get("learningReminder"));
        assertEquals(true, out.get("stored"));
    }

    @Test
    void partialPutKeepsOtherValuesAndUpsertsOwnRow() {
        when(repo.find(205L)).thenReturn(List.of(row(true, false, true, false, 24)));
        Map<String, Object> out = service.put(205L, Map.of("reminderBeforeHours", 6, "learningReminder", true));
        verify(repo).upsert(205L, new Prefs(true, false, true, true, 6));
        assertEquals(6, out.get("reminderBeforeHours"));
        assertEquals(false, out.get("assignmentReminder"));
    }

    @Test
    void firstPutStartsFromDefaults() {
        when(repo.find(205L)).thenReturn(List.of());
        service.put(205L, Map.of("quizReminder", false));
        verify(repo).upsert(205L, new Prefs(true, true, false, true, 24));
    }

    @Test
    void invalidValuesAreRejectedBeforeWriting() {
        when(repo.find(205L)).thenReturn(List.of());
        for (Map<String, Object> bad : List.<Map<String, Object>>of(
            Map.of("reminderBeforeHours", -1), Map.of("reminderBeforeHours", 169),
            Map.of("reminderBeforeHours", "24"), Map.of("reminderBeforeHours", 2.5),
            Map.of("pushEnabled", "yes"), Map.of("quizReminder", 1))) {
            assertThrows(InvalidRequestException.class, () -> service.put(205L, bad), bad.toString());
        }
        assertThrows(InvalidRequestException.class, () -> service.put(205L, null));
        verify(repo, never()).upsert(anyLong(), any());
    }

    @Test
    void mergeTable() {
        Prefs base = NotificationPreferenceService.DEFAULTS;
        assertEquals(base, NotificationPreferenceService.merge(base, Map.of()));
        assertEquals(new Prefs(false, true, true, true, 0),
            NotificationPreferenceService.merge(base, Map.of("pushEnabled", false, "reminderBeforeHours", 0)));
        assertEquals(new Prefs(true, true, true, true, 168),
            NotificationPreferenceService.merge(base, Map.of("reminderBeforeHours", 168, "unknownKey", "ignored")));
    }
}
