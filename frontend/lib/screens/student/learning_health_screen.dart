import 'package:flutter/material.dart';
import '../../core/data_profile.dart';

import '../../models/learning_health.dart';
import '../../models/student_course.dart';
import '../../services/api_service.dart';
import '../../widgets/async_tab.dart';
import '../../widgets/learning_health_widgets.dart';
import '../../widgets/learning_widgets.dart';
import 'student_course_detail_screen.dart';

/// Course detail tab opened by each kind of health action.
const healthActionTab = {
  HealthTarget.tasks: 2,
  HealthTarget.recommendations: 0,
};

void openHealthAction(
  BuildContext context,
  ApiService api,
  HealthAction action,
  String courseName,
) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => StudentCourseDetailScreen(
        apiService: api,
        course: StudentCourse(
          courseId: action.courseId,
          courseName: courseName,
        ),
        initialTab: healthActionTab[action.target] ?? 0,
      ),
    ),
  );
}

/// V2-N9: every course with its level, the teacher-visible reasons and what to do next.
class LearningHealthScreen extends StatelessWidget {
  final ApiService api;
  const LearningHealthScreen({super.key, required this.api});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tình trạng học tập của tôi')),
    body: SafeArea(
      child: AsyncTab<LearningHealthOverview>(
        load: api.getLearningHealth,
        leading: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(DataProfile.learningHealthIntro),
          ),
        ],
        children: (data) => [
          if (data.courses.isEmpty) const EmptyState('Bạn chưa có khóa học'),
          for (final c in data.courses)
            CourseHealthCard(
              health: c,
              onAction: (a) => openHealthAction(context, api, a, c.courseName),
            ),
        ],
      ),
    ),
  );
}

/// Compact tile on the course Overview tab; the full card opens in a bottom sheet.
class CourseHealthTile extends StatefulWidget {
  final ApiService api;
  final int courseId;
  final void Function(HealthAction action)? onAction;
  const CourseHealthTile({
    super.key,
    required this.api,
    required this.courseId,
    this.onAction,
  });

  @override
  State<CourseHealthTile> createState() => _CourseHealthTileState();
}

class _CourseHealthTileState extends State<CourseHealthTile> {
  late final Future<CourseHealth?> _future = () async {
    try {
      return await widget.api.getCourseLearningHealth(
        courseId: widget.courseId,
      );
    } catch (error) {
      debugPrint('Course health tile: $error');
      return null;
    }
  }();

  @override
  Widget build(BuildContext context) => FutureBuilder<CourseHealth?>(
    future: _future,
    builder: (context, snapshot) {
      final data = snapshot.data;
      if (data == null) return const SizedBox.shrink();
      return HealthSummaryTile(
        key: const Key('course-health-tile'),
        level: data.level,
        title: 'Tình trạng học tập: ${data.level?.label ?? 'Chưa rõ'}',
        summary: data.reasons.isEmpty
            ? 'Điểm theo dõi ${data.score}/100 · không có dấu hiệu cần chú ý'
            : 'Điểm theo dõi ${data.score}/100 · ${data.reasons.length} lý do',
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          useSafeArea: true,
          builder: (sheet) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            child: CourseHealthCard(
              health: data,
              showCourseName: false,
              onAction: widget.onAction == null
                  ? null
                  : (a) {
                      Navigator.pop(sheet);
                      widget.onAction!(a);
                    },
            ),
          ),
        ),
      );
    },
  );
}

/// Compact Home tile; hidden when the request fails so it never pushes other sections away.
class LearningHealthHomeTile extends StatefulWidget {
  final ApiService api;
  const LearningHealthHomeTile({super.key, required this.api});

  @override
  State<LearningHealthHomeTile> createState() => _LearningHealthHomeTileState();
}

class _LearningHealthHomeTileState extends State<LearningHealthHomeTile> {
  late final Future<LearningHealthOverview?> _future = () async {
    try {
      return await widget.api.getLearningHealth();
    } catch (error) {
      debugPrint('Learning health tile: $error');
      return null;
    }
  }();

  @override
  Widget build(BuildContext context) => FutureBuilder<LearningHealthOverview?>(
    future: _future,
    builder: (context, snapshot) {
      final data = snapshot.data;
      if (data == null || data.courses.isEmpty) return const SizedBox.shrink();
      return HealthSummaryTile(
        key: const Key('learning-health-tile'),
        level: data.level,
        title: 'Tình trạng học tập: ${data.level?.label ?? 'Chưa rõ'}',
        summary: data.summary,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LearningHealthScreen(api: widget.api),
          ),
        ),
      );
    },
  );
}
