import '../../widgets/logout_button.dart';
import '../../core/theme/app_colors.dart';
import '../search_screen.dart';
import '../../core/display_text.dart';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/teacher_course.dart';
import '../../services/api_service.dart';
import '../../widgets/async_tab.dart';
import '../../widgets/learning_widgets.dart';
import '../../widgets/copilot_widgets.dart';
import 'advisor_class_screen.dart';
import 'teacher_course_detail_screen.dart';

class TeacherHomeScreen extends StatefulWidget {
  final ApiService? apiService;
  const TeacherHomeScreen({super.key, this.apiService});
  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  late final ApiService _api = widget.apiService ?? ApiService();
  @override
  void dispose() {
    if (widget.apiService == null) _api.dispose();
    super.dispose();
  }

  void _open(TeacherCourse c, int tab) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => TeacherCourseDetailScreen(
        course: c,
        apiService: _api,
        initialTab: tab,
        initialStudentFilter: tab == 1 ? 'support' : 'all',
      ),
    ),
  );
  int? _actionCount(TeacherCourse c, int tab) => switch (tab) {
    1 => c.studentsNeedAttention,
    2 => c.needsGradingCount,
    _ => c.upcomingDeadlines7Days,
  };

  void _pick(List<TeacherCourse> courses, int tab) {
    final relevant = courses
        .where((c) => (_actionCount(c, tab) ?? 0) > 0)
        .toList();
    // If summaries are unavailable, offer the course list without claiming a match.
    final choices = relevant.isNotEmpty
        ? relevant
        : courses.where((c) => _actionCount(c, tab) == null).toList();
    if (courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có khóa học được phân công')),
      );
      return;
    }
    // Zero counts still open the existing course flow for review.
    if (choices.isEmpty) choices.addAll(courses);
    // The summary has no assignment/quiz breakdown for upcoming deadlines.
    final destinationTab = tab < 0 ? 0 : tab;
    if (choices.length == 1) {
      _open(choices.first, destinationTab);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * .6,
          child: CourseTabList(
            children: [
              SectionHeader(
                relevant.isEmpty
                    ? 'Chọn khóa học để kiểm tra'
                    : switch (tab) {
                        1 => 'Khóa học có sinh viên cần theo dõi',
                        2 => 'Khóa học có bài cần chấm',
                        _ => 'Khóa học có hoạt động sắp đến hạn',
                      },
              ),
              for (final c in choices)
                ListTile(
                  title: Text(DemoDisplayNames.course(c.courseName)),
                  subtitle: _actionCount(c, tab) == null
                      ? const Text('Chưa có dữ liệu tổng hợp')
                      : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _open(c, destinationTab);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  int? _total(
    List<TeacherCourse> courses,
    int? Function(TeacherCourse) value,
  ) => courses.any((c) => value(c) == null)
      ? null
      : courses.fold<int>(0, (sum, c) => sum + value(c)!);
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Trang chủ Giảng viên'),
      leading: const AccountMenu(),
      actions: [
        IconButton(
          key: const Key('open-search'),
          tooltip: 'Tìm kiếm',
          icon: const Icon(Icons.search),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SearchScreen(api: _api, teacher: true),
            ),
          ),
        ),
      ],
    ),
    body: AsyncTab<List<TeacherCourse>>(
      load: _api.getTeacherCourses,
      children: (courses) => [
        Row(
          children: [
            const UserAvatar('Giảng viên'),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Xin chào, Giảng viên',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TeacherCopilotCard(
          studentsNeedAttention:
              _total(courses, (c) => c.studentsNeedAttention) ?? 0,
          needsGradingCount: _total(courses, (c) => c.needsGradingCount) ?? 0,
          upcomingDeadlines:
              _total(courses, (c) => c.upcomingDeadlines7Days) ?? 0,
        ),
        AdvisorClassEntry(api: _api),
        const SizedBox(height: 8),
        const SectionHeader('Chi tiết công việc'),
        Text(
          'Được tổng hợp từ các khóa học',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (label, value, tab) in [
                (
                  'trường hợp cần theo dõi',
                  _total(courses, (c) => c.studentsNeedAttention),
                  1,
                ),
                (
                  'bài cần chấm',
                  _total(courses, (c) => c.needsGradingCount),
                  2,
                ),
                (
                  'hoạt động sắp đến hạn',
                  _total(courses, (c) => c.upcomingDeadlines7Days),
                  -1,
                ),
              ]) ...[
                if (tab != 1)
                  const Divider(height: 1, indent: 12, endIndent: 12),
                InkWell(
                  onTap: () => _pick(courses, tab),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 64),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            tab == 1
                                ? Icons.people_outline
                                : tab == 2
                                ? Icons.assignment_outlined
                                : Icons.schedule,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  value == null
                                      ? '$label: Chưa có dữ liệu'
                                      : tab == 2 && value == 0
                                      ? 'Không có bài nào đang chờ chấm'
                                      : tab == 1 && value == 0
                                      ? 'Không có sinh viên cần theo dõi'
                                      : '$value $label',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                if (tab == -1)
                                  Text(
                                    'Trong 7 ngày tới',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SectionHeader('Khóa học giảng dạy'),
        if (courses.isEmpty)
          const EmptyState('Chưa có khóa học được phân công')
        else ...[
          _buildProgressComparisonChart(courses),
          const SizedBox(height: 16),
        ],
        for (final c in courses)
          TeacherCourseCard(course: c, onTap: () => _open(c, 0)),
      ],
    ),
  );

  Widget _buildProgressComparisonChart(List<TeacherCourse> courses) {
    final validCourses = courses
        .where((c) => c.averageProgress != null)
        .toList();
    if (validCourses.isEmpty) return const SizedBox.shrink();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'So sánh tiến độ các khóa học',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Tỷ lệ hoàn thành trung bình của sinh viên trong từng khóa học.',
              style: TextStyle(fontSize: 13, color: context.muted),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < validCourses.length) {
                            String name =
                                validCourses[index].courseShortname ??
                                validCourses[index].courseName;
                            if (name.length > 10) {
                              name = '${name.substring(0, 8)}...';
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                name,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 32,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: validCourses.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.averageProgress!
                              .clamp(0, 100)
                              .toDouble(),
                          color: Theme.of(context).colorScheme.primary,
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
