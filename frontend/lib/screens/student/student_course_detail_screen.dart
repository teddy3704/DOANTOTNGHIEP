import '../../core/display_text.dart';
import '../../core/data_profile.dart';

import 'package:flutter/material.dart';

import '../../models/student_course.dart';
import '../../models/student_course_detail.dart';
import '../../services/api_service.dart';
import '../../widgets/async_tab.dart';
import '../../widgets/learning_widgets.dart';
import 'student_reflection_screen.dart';
import 'student_flashcard_screen.dart';
import 'grade_forecast_screen.dart';
import 'learning_health_screen.dart';
import '../../widgets/study_recommendation_widgets.dart';
import '../../widgets/peer_comparison_widgets.dart';

class StudentCourseDetailScreen extends StatefulWidget {
  final StudentCourse course;
  final ApiService? apiService;
  final int initialTab;
  const StudentCourseDetailScreen({
    super.key,
    required this.course,
    this.apiService,
    this.initialTab = 0,
  });

  @override
  State<StudentCourseDetailScreen> createState() =>
      _StudentCourseDetailScreenState();
}

class _StudentCourseDetailScreenState extends State<StudentCourseDetailScreen> {
  late final ApiService _api = widget.apiService ?? ApiService();
  StudentCourse get course => widget.course;

  @override
  void dispose() {
    if (widget.apiService == null) _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 5,
    initialIndex: widget.initialTab,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          DemoDisplayNames.course(course.courseName),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        bottom: CourseTabBar(
          labels: const [
            'Tổng quan',
            'Nội dung',
            'Việc cần làm',
            'Điểm',
            'Chuyên cần',
          ],
          textScale: MediaQuery.textScalerOf(context).scale(14) / 14,
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          children: [
            _overview(),
            AsyncTab<List<StudentLearningItem>>(
              load: () =>
                  _api.getStudentLearningItems(courseId: course.courseId),
              children: _learningItems,
            ),
            AsyncTab<List<StudentTask>>(
              load: () => _api.getStudentTasks(courseId: course.courseId),
              children: _tasks,
            ),
            AsyncTab<
              ({
                List<StudentGrade> grades,
                List<StudentGradeCategory> categories,
              })
            >(
              load: () async {
                final results = await Future.wait<Object>([
                  _api.getStudentGrades(courseId: course.courseId),
                  _api.getStudentGradeCategories(courseId: course.courseId),
                ]);
                return (
                  grades: results[0] as List<StudentGrade>,
                  categories: results[1] as List<StudentGradeCategory>,
                );
              },
              children: (data) => _grades(data.grades, data.categories),
            ),
            AsyncTab<StudentAttendance?>(
              load: () => _api.getStudentAttendance(courseId: course.courseId),
              children: _attendance,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _overview() => AsyncTab<List<Object>>(
    load: () => Future.wait<Object>([
      _api.getStudentTasks(courseId: course.courseId),
      _api.getContinueLearning(courseId: course.courseId),
    ]),
    leading: [
      Builder(
        builder: (context) => CourseHealthTile(
          api: _api,
          courseId: course.courseId,
          // Health actions jump to this course's own tabs instead of stacking a new screen.
          onAction: (a) => DefaultTabController.of(
            context,
          ).animateTo(healthActionTab[a.target] ?? 0),
        ),
      ),
      DetailCard(
        title: DemoDisplayNames.course(course.courseName),
        children: [
          DetailLine(
            'Mã khóa học',
            course.courseShortname ?? 'Chưa có dữ liệu',
          ),
          DetailLine(
            DataProfile.progress,
            detailValue(course.progressPercentage, suffix: '%'),
          ),
          if (course.progressPercentage != null)
            LinearProgressIndicator(
              value: (course.progressPercentage! / 100).clamp(0, 1),
            ),
          DetailLine(
            'Hoạt động đã hoàn thành',
            '${detailValue(course.completedTasks)} / ${detailValue(course.totalTasks)}',
          ),
          if (course.attendancePercentage != null)
            DetailLine(
              DataProfile.attendance,
              detailValue(course.attendancePercentage, suffix: '%'),
            ),
        ],
      ),
    ],
    children: (data) {
      final tasks = data[0] as List<StudentTask>;
      final suggestions = (data[1] as List<StudentLearningItem>).where(
        (item) => item.courseId == course.courseId,
      );
      final now = DateTime.now();
      final pending = tasks.where((task) => task.isPending).length;
      final overdue = tasks.where((task) => task.isOverdue(now)).length;
      return [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentReflectionScreen(
                        api: _api,
                        courseId: course.courseId,
                        courseName: course.courseName,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.book),
                label: const Text('Nhật ký'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentFlashcardScreen(
                        api: _api,
                        courseId: course.courseId,
                        courseName: course.courseName,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.style),
                label: const Text('Flashcards'),
              ),
            ),
          ],
        ),
        if (suggestions.isNotEmpty) ...[
          const SectionHeader('Tiếp tục học'),
          ...suggestions.map(
            (item) => Builder(
              builder: (context) => ActivityCard(
                item,
                action: 'Tiếp tục',
                onFallback: () => DefaultTabController.of(context).animateTo(1),
              ),
            ),
          ),
        ],
        StudyRecommendationsSection(
          api: _api,
          courseId: course.courseId,
          courseName: course.courseName,
        ),
        PeerComparisonCard(api: _api, courseId: course.courseId),
        const SectionHeader('Việc sắp tới'),
        ...StudentTask.sorted(
          tasks.where((task) => task.isPending).toList(),
          now,
        ).take(2).map((task) => TaskCard(task, showCourse: false)),
        DetailCard(
          title: 'Việc cần làm tiếp theo',
          children: [
            DetailLine('Chưa hoàn thành', '$pending'),
            DetailLine('Đã quá hạn', '$overdue'),
            if (pending == 0)
              const Text('Bạn không có việc đang chờ trong khóa học này.'),
            Builder(
              builder: (context) => FilledButton.icon(
                onPressed: () => DefaultTabController.of(context).animateTo(2),
                icon: const Icon(Icons.checklist),
                label: const Text('Xem việc cần làm'),
              ),
            ),
          ],
        ),
      ];
    },
  );

  List<Widget> _learningItems(List<StudentLearningItem> items) {
    if (items.isEmpty) {
      return [const DetailCard(title: 'Khóa học chưa có nội dung học')];
    }
    final groups = <(int?, String?), List<StudentLearningItem>>{};
    final ordered = [...items]
      ..sort(
        (a, b) => (a.sectionNumber ?? 2147483647).compareTo(
          b.sectionNumber ?? 2147483647,
        ),
      );
    for (final item in ordered) {
      groups
          .putIfAbsent((item.sectionNumber, item.sectionName), () => [])
          .add(item);
    }
    return [
      for (final section in groups.values) ...[
        SectionHeader(section.first.sectionTitle),
        ...section.map(ActivityCard.new),
      ],
    ];
  }

  List<Widget> _tasks(List<StudentTask> tasks) {
    if (tasks.isEmpty) {
      return [const EmptyState('Khóa học chưa có việc cần làm')];
    }
    return StudentTask.sorted(
      tasks,
      DateTime.now(),
    ).map((t) => TaskCard(t, showCourse: false)).toList();
  }

  List<Widget> _grades(
    List<StudentGrade> grades,
    List<StudentGradeCategory> categories,
  ) {
    if (grades.isEmpty && categories.isEmpty) {
      return [const DetailCard(title: 'Khóa học chưa có dữ liệu điểm')];
    }
    final forecastButton = Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.tonalIcon(
        key: const Key('open-grade-forecast'),
        icon: const Icon(Icons.calculate_outlined),
        label: const Text('Mô phỏng điểm'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GradeForecastScreen(
              api: _api,
              courseId: course.courseId,
              courseName: course.courseName,
            ),
          ),
        ),
      ),
    );
    final groups = <int?, List<StudentGrade>>{};
    final categoryMap = {
      for (final category in categories) category.id: category,
    };
    for (final grade in grades) {
      groups.putIfAbsent(grade.categoryId, () => []).add(grade);
    }
    for (final category in categories) {
      groups.putIfAbsent(category.id, () => []);
    }
    return [
      if (grades.isNotEmpty)
        DetailCard(
          title: 'Tổng quan điểm',
          children: [
            DetailLine(
              'Hoạt động đã chấm',
              '${grades.where((g) => g.isGraded).length} / ${grades.length}',
            ),
            forecastButton,
          ],
        ),
      ...groups.entries.map((entry) {
        final category = categoryMap[entry.key];
        final title =
            category?.name ??
            (entry.value.isNotEmpty ? entry.value.first.categoryName : null) ??
            'Điểm hoạt động';
        return DetailCard(
          title: gradeCategoryLabel(title),
          children: [
            if (category?.averagePercentage != null) ...[
              Text(
                'Trung bình các hoạt động đã chấm',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                formatPercentageVi(category!.averagePercentage),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
            if (category?.gradedCount != null && category?.totalCount != null)
              DetailLine(
                'Hoạt động đã chấm',
                '${category!.gradedCount} / ${category.totalCount}',
              ),
            if (entry.value.isEmpty) const Text('Chưa có điểm từng hoạt động'),
            for (final grade in entry.value) ...[
              const Divider(height: 24),
              Text(
                DemoDisplayNames.activity(grade.name),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                grade.scoreLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Wrap(children: [StatusChip(grade.gradingStatus)]),
              if (grade.feedback?.trim().isNotEmpty == true)
                DetailLine('Nhận xét', grade.feedback!),
            ],
          ],
        );
      }),
    ];
  }

  List<Widget> _attendance(StudentAttendance? data) => data == null
      ? [DetailCard(title: DataProfile.noAttendanceForCourse)]
      : [
          DetailCard(
            title: DataProfile.attendance,
            children: [
              DetailLine(
                DataProfile.attendanceRate,
                detailValue(data.percentage, suffix: '%'),
              ),
              // Real export: no session tables, so no per-session breakdown is shown.
              if (!DataProfile.isReal) ...[
                DetailLine('Tổng số buổi', detailValue(data.totalSessions)),
                DetailLine('Có mặt', detailValue(data.present)),
                DetailLine('Đi trễ', detailValue(data.late)),
                if (data.excused != null)
                  DetailLine('Có phép', detailValue(data.excused)),
                DetailLine('Vắng', detailValue(data.absent)),
              ],
            ],
          ),
        ];
}
