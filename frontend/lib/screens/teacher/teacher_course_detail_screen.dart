import '../../core/display_text.dart';

import 'package:flutter/material.dart';

import '../../models/teacher_course.dart';
import '../../services/api_service.dart';
import '../../widgets/async_tab.dart';
import 'teacher_analytics_screen.dart';
import 'teacher_monitoring_screens.dart';
import '../../widgets/learning_widgets.dart';

class TeacherCourseDetailScreen extends StatefulWidget {
  /// Index of the "Phân tích" tab, for opening it directly (e.g. from a notification).
  static const analyticsTab = 4;
  final TeacherCourse course;
  final ApiService? apiService;
  final int initialTab;
  final String initialStudentFilter;
  const TeacherCourseDetailScreen({
    super.key,
    required this.course,
    this.apiService,
    this.initialTab = 0,
    this.initialStudentFilter = 'all',
  });
  @override
  State<TeacherCourseDetailScreen> createState() =>
      _TeacherCourseDetailScreenState();
}

class _TeacherCourseDetailScreenState extends State<TeacherCourseDetailScreen> {
  late String _filter = widget.initialStudentFilter;
  int _filterRequestId = 0;
  late final ApiService _api = widget.apiService ?? ApiService();

  @override
  void dispose() {
    if (widget.apiService == null) _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 5,
    initialIndex: widget.initialTab,
    child: Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: Text(
            DemoDisplayNames.course(widget.course.courseName),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          bottom: CourseTabBar(
            labels: const [
              'Tổng quan',
              'Sinh viên',
              'Bài tập',
              'Bài kiểm tra',
              'Phân tích',
            ],
            textScale: MediaQuery.textScalerOf(context).scale(14) / 14,
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              CourseTabList(
                children: [
                  TeacherCourseSummary(course: widget.course),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _filter = 'support';
                        _filterRequestId++;
                      });
                      DefaultTabController.of(context).animateTo(1);
                    },
                    icon: const Icon(Icons.people_outline),
                    label: const Text('Xem sinh viên cần theo dõi'),
                  ),
                ],
              ),
              TeacherStudentsTab(
                api: _api,
                courseId: widget.course.courseId,
                initialFilter: _filter,
                filterRequestId: _filterRequestId,
              ),
              TeacherActivitiesTab(
                api: _api,
                courseId: widget.course.courseId,
                type: 'assignment',
              ),
              TeacherActivitiesTab(
                api: _api,
                courseId: widget.course.courseId,
                type: 'quiz',
              ),
              TeacherAnalyticsTab(api: _api, courseId: widget.course.courseId),
            ],
          ),
        ),
      ),
    ),
  );
}

class TeacherCourseSummary extends StatelessWidget {
  final TeacherCourse course;
  const TeacherCourseSummary({super.key, required this.course});
  @override
  Widget build(BuildContext context) => DetailCard(
    title: DemoDisplayNames.course(course.courseName),
    children: [
      if (course.courseShortname != null)
        DetailLine('Mã khóa học', course.courseShortname!),
      if (course.startLabel != null) DetailLine('Học kỳ', course.startLabel!),
      DetailLine(
        'Tiến độ trung bình',
        detailValue(course.averageProgress, suffix: '%'),
      ),
      if (course.averageProgress != null)
        LinearProgressIndicator(
          value: (course.averageProgress! / 100).clamp(0, 1),
        ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          StatusChip('${detailValue(course.studentCount)} sinh viên'),
          StatusChip(
            course.studentsNeedAttention == null
                ? 'Sinh viên cần theo dõi: Chưa có dữ liệu'
                : '${course.studentsNeedAttention} sinh viên cần theo dõi',
          ),
          StatusChip(
            course.highRiskStudents == null
                ? 'Sinh viên nguy cơ cao: Chưa có dữ liệu'
                : '${course.highRiskStudents} sinh viên nguy cơ cao',
            danger: (course.highRiskStudents ?? 0) > 0,
          ),
          StatusChip(
            course.needsGradingCount == 0
                ? 'Không có bài nào đang chờ chấm'
                : '${detailValue(course.needsGradingCount)} bài cần chấm',
          ),
          StatusChip(
            '${detailValue(course.upcomingDeadlines7Days)} hoạt động sắp đến hạn (7 ngày)',
          ),
        ],
      ),
    ],
  );
}
