import 'package:flutter/material.dart';

import '../core/display_text.dart';
import '../models/study_recommendation.dart';
import '../screens/student/student_flashcard_screen.dart';
import '../services/api_service.dart';
import 'learning_widgets.dart';
import 'moodle_button.dart';

/// V2-N2 "Nên ôn lại". [courseId] null = across all courses (Home, top 3).
/// On Home the section disappears when there is nothing to review or the request fails;
/// inside a course it explains the empty result instead.
class StudyRecommendationsSection extends StatefulWidget {
  final ApiService api;
  final int? courseId;
  final String? courseName;

  const StudyRecommendationsSection({
    super.key,
    required this.api,
    this.courseId,
    this.courseName,
  });

  @override
  State<StudyRecommendationsSection> createState() =>
      _StudyRecommendationsSectionState();
}

class _StudyRecommendationsSectionState
    extends State<StudyRecommendationsSection> {
  late final Future<List<WeakChapter>?> _future = () async {
    try {
      return await widget.api.getStudyRecommendations(
        courseId: widget.courseId,
      );
    } catch (error) {
      debugPrint('Study recommendations: $error');
      return null;
    }
  }();

  bool get _home => widget.courseId == null;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<WeakChapter>?>(
    future: _future,
    builder: (context, snapshot) {
      final chapters = snapshot.data;
      if (snapshot.connectionState != ConnectionState.done) {
        return const SizedBox.shrink();
      }
      if (chapters == null || (chapters.isEmpty && _home)) {
        return const SizedBox.shrink();
      }
      return Column(
        key: const Key('study-recommendations'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader('Nên ôn lại'),
          if (chapters.isEmpty)
            const EmptyState(
              'Chưa thấy chương nào cần ôn lại',
              subtitle:
                  'Một chương được gợi ý khi điểm trung bình dưới ngưỡng qua, '
                  'thấp hơn lớp từ 10 điểm, hoặc có bài tính điểm quá hạn.',
            ),
          for (final c in chapters)
            WeakChapterCard(
              chapter: c,
              showCourse: _home,
              onCreateFlashcard: (s) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentFlashcardScreen(
                    api: widget.api,
                    courseId: c.courseId ?? widget.courseId ?? 0,
                    courseName: c.courseName ?? widget.courseName ?? 'Khóa học',
                    openAddWithFront: DemoDisplayNames.activity(s.activityName),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class WeakChapterCard extends StatelessWidget {
  final WeakChapter chapter;
  final bool showCourse;
  final void Function(StudySuggestion suggestion)? onCreateFlashcard;

  const WeakChapterCard({
    super.key,
    required this.chapter,
    this.showCourse = false,
    this.onCreateFlashcard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              DemoDisplayNames.section(chapter.sectionName),
              style: theme.textTheme.titleMedium,
            ),
            if (showCourse && chapter.courseName != null)
              Text(
                DemoDisplayNames.course(chapter.courseName!),
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 6),
            for (final r in chapter.reasons)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(r)),
                  ],
                ),
              ),
            if (chapter.suggestions.isNotEmpty) ...[
              const Divider(height: 16),
              for (final s in chapter.suggestions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DemoDisplayNames.activity(s.activityName),
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(s.reason, style: theme.textTheme.bodySmall),
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          MoodleButton(
                            path: s.moodlePath,
                            courseModuleId: s.courseModuleId,
                            compact: true,
                          ),
                          if (onCreateFlashcard != null)
                            TextButton.icon(
                              onPressed: () => onCreateFlashcard!(s),
                              icon: const Icon(Icons.style_outlined, size: 16),
                              label: const Text('Tạo thẻ ghi nhớ'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
