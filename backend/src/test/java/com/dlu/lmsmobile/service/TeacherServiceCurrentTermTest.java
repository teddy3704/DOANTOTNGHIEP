package com.dlu.lmsmobile.service;

import com.dlu.lmsmobile.config.DataProfile;
import com.dlu.lmsmobile.repository.TeacherRepository;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

/** Invented courses; teacher home totals on real use only the current term's courses. */
class TeacherServiceCurrentTermTest {

    private final TeacherRepository repo = mock(TeacherRepository.class);

    private List<Map<String, Object>> courses() {
        return List.of(Map.of("courseid", 1L, "course_name", "Môn mới", "needs_grading_count", 3),
                Map.of("courseid", 2L, "course_name", "Môn cũ", "needs_grading_count", 500));
    }

    @Test
    void realMarksCurrentTermCourses() {
        when(repo.findCoursesByTeacherId(9L)).thenReturn(courses());
        when(repo.findCurrentTermCourseIds()).thenReturn(List.of(1L));
        var out = new TeacherService(repo, DataProfile.real()).getTeacherCourses(9L);
        assertThat(out).extracting(m -> m.get("current_term")).containsExactly(true, false);
        assertThat(out.get(0).get("needs_grading_count")).isEqualTo(3);
    }

    @Test
    void demoIsUnchangedAndNeverQueriesTheRealView() {
        when(repo.findCoursesByTeacherId(9L)).thenReturn(courses());
        var out = new TeacherService(repo, DataProfile.demo()).getTeacherCourses(9L);
        assertThat(out).allSatisfy(m -> assertThat(m).doesNotContainKey("current_term"));
        verify(repo, never()).findCurrentTermCourseIds();
    }
}
