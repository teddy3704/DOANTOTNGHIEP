package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.exception.InvalidRequestException;
import com.dlu.lmsmobile.exception.ResourceNotFoundException;
import com.dlu.lmsmobile.repository.TeacherNoteRepository;
import com.dlu.lmsmobile.repository.TeacherRepository;
import org.junit.jupiter.api.Test;
import java.util.List;
import java.util.Map;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;

class TeacherNoteSecurityTest {
    private final TeacherRepository teachers = mock(TeacherRepository.class);
    private final TeacherNoteRepository notes = mock(TeacherNoteRepository.class);
    private final TeacherNoteService service = new TeacherNoteService(notes, teachers);
    private final Map<String, Object> payload = Map.of("courseId", 14L, "studentId", 205L, "note", "Private learning support note");

    @Test void teacherCannotWriteOrReadNotesInUnassignedCourse() {
        assertThrows(ResourceNotFoundException.class, () -> service.addNote(102L, payload));
        assertThrows(ResourceNotFoundException.class, () -> service.getNotes(102L, 14L, null));
        verifyNoInteractions(notes);
    }

    @Test void courseOwnershipDoesNotGrantAccessToUnenrolledStudent() {
        when(teachers.hasCourse(102L, 14L)).thenReturn(true);
        when(teachers.findStudents(102L, 14L)).thenReturn(List.of(Map.of("userid", 206L)));
        assertThrows(ResourceNotFoundException.class, () -> service.addNote(102L, payload));
        assertThrows(ResourceNotFoundException.class, () -> service.getNotes(102L, 14L, 205L));
        verifyNoInteractions(notes);
    }

    @Test void missingScopeAndUnknownStatusCannotWrite() {
        assertThrows(InvalidRequestException.class, () -> service.addNote(102L, Map.of("studentId", 205L, "note", "text")));
        assertThrows(InvalidRequestException.class, () -> service.getNotes(102L, null, 205L));
        assertThrows(InvalidRequestException.class, () -> service.updateStatus(1L, 102L, "deleted"));
        verifyNoInteractions(notes);
    }

    @Test void validRosterMemberCanReceiveNoteAndLostAuthorizationYieldsNotFound() {
        when(teachers.hasCourse(102L, 14L)).thenReturn(true);
        when(teachers.findStudents(102L, 14L)).thenReturn(List.of(Map.of("userid", 205L)));
        service.addNote(102L, payload);
        verify(notes).save(102L, 205L, 14L, "Private learning support note", "active");
        assertThrows(ResourceNotFoundException.class, () -> service.updateStatus(1L, 102L, "resolved"));
    }
}
