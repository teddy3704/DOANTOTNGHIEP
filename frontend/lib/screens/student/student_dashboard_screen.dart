import '../../widgets/logout_button.dart';
import '../../core/data_profile.dart';
import 'package:flutter/material.dart';

import '../../models/student_dashboard.dart';
import '../../models/student_course.dart';
import '../../models/student_course_detail.dart';
import '../../services/api_service.dart';
import '../../widgets/async_tab.dart';
import '../../widgets/learning_widgets.dart';
import 'student_course_detail_screen.dart';
import 'student_task_center_screen.dart';
import 'student_courses_screen.dart';
import 'learning_health_screen.dart';
import 'flashcard_review_screen.dart';
import 'academic_record_screen.dart';
import 'study_plan_screen.dart';
import 'focus_timer_screen.dart';
import 'reminder_settings_screen.dart';
import 'calendar_screen.dart';
import '../search_screen.dart';
import '../../services/reminder_service.dart';
import '../portal_sources_screen.dart';
import '../../widgets/study_recommendation_widgets.dart';

class StudentDashboardScreen extends StatefulWidget {
  final ApiService? apiService;
  final VoidCallback? onTasks, onCourses;

  /// Shown above everything else on Home, e.g. a new reminder from a teacher.
  final Widget? banner;

  /// V2-N7 phone reminders; created on demand when not given.
  final ReminderService? reminders;
  const StudentDashboardScreen({
    super.key,
    this.apiService,
    this.onTasks,
    this.onCourses,
    this.banner,
    this.reminders,
  });
  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  late final ApiService _api = widget.apiService ?? ApiService();
  @override
  void dispose() {
    if (widget.apiService == null) _api.dispose();
    super.dispose();
  }

  void _tasks() => widget.onTasks != null
      ? widget.onTasks!()
      : Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StudentTaskCenterScreen(api: _api)),
        );
  void _courses() => widget.onCourses != null
      ? widget.onCourses!()
      : Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentCoursesScreen(apiService: _api),
          ),
        );
  // Capture failures immediately, including for sections below the viewport.
  // Every section keeps its own result and retry; a failed API never hides siblings.
  Future<AsyncSnapshot<T>> _capture<T>(Future<T> request) async {
    try {
      return AsyncSnapshot.withData(ConnectionState.done, await request);
    } catch (error, stack) {
      debugPrint('Learning Home: $error\n$stack');
      return AsyncSnapshot.withError(ConnectionState.done, error, stack);
    }
  }

  late Future<AsyncSnapshot<StudentDashboard>> _profile = _capture(
    _api.getStudentDashboard(),
  );
  late Future<AsyncSnapshot<List<StudentCourse>>> _courseData = _capture(
    _api.getStudentCourses(),
  );
  late Future<AsyncSnapshot<List<StudentTask>>> _taskData = _capture(
    _api.getAllStudentTasks(),
  );
  late Future<AsyncSnapshot<List<StudentLearningItem>>> _suggestions = _capture(
    _api.getContinueLearning(),
  );

  Future<void> _refresh() async {
    setState(() {
      _profile = _capture(_api.getStudentDashboard());
      _courseData = _capture(_api.getStudentCourses());
      _taskData = _capture(_api.getAllStudentTasks());
      _suggestions = _capture(_api.getContinueLearning());
    });
    await Future.wait([_profile, _courseData, _taskData, _suggestions]);
  }

  void _openCourse(StudentCourse course, {int initialTab = 0}) =>
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentCourseDetailScreen(
            course: course,
            apiService: _api,
            initialTab: initialTab,
          ),
        ),
      );
  Future<void> _openSuggestion(StudentLearningItem item) async {
    final courseId = item.courseId;
    if (courseId == null || courseId <= 0) return;
    final courses = (await _courseData).data ?? <StudentCourse>[];
    if (!mounted) return;
    final matching = courses.where((course) => course.courseId == courseId);
    _openCourse(
      matching.isNotEmpty
          ? matching.first
          : StudentCourse(
              courseId: courseId,
              courseName: item.courseName ?? 'Khóa học',
            ),
      initialTab: 1,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AccountMenu(),
      title: const Text('Trang chủ'),
      actions: [
        IconButton(
          key: const Key('open-search'),
          tooltip: 'Tìm kiếm',
          icon: const Icon(Icons.search),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SearchScreen(api: _api)),
          ),
        ),
        IconButton(
          key: const Key('open-calendar'),
          tooltip: 'Lịch học',
          icon: const Icon(Icons.calendar_month_outlined),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CalendarScreen(api: _api)),
          ),
        ),
        IconButton(
          key: const Key('open-reminder-settings'),
          tooltip: 'Cài đặt nhắc',
          icon: const Icon(Icons.notifications_active_outlined),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReminderSettingsScreen(
                api: _api,
                reminders: widget.reminders ?? ReminderService(),
              ),
            ),
          ),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _refresh,
      child: CourseTabList(
        children: [
          if (widget.banner != null) ...[
            widget.banner!,
            const SizedBox(height: 12),
          ],
          PortalSummaryCard(
            api: _api,
            onOpen: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AcademicRecordScreen(api: _api),
              ),
            ),
          ),
          _HomeSection<StudentDashboard>(
            future: _profile,
            onRetry: () => setState(() {
              _profile = _capture(_api.getStudentDashboard());
            }),
            children: (profile) {
              final name = profile.fullName ?? 'Sinh viên';
              return [
                Row(
                  children: [
                    UserAvatar(name),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xin chào, $name',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (profile.identityLabel != null)
                            Text(
                              profile.identityLabel!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          if (profile.academicLabel != null)
                            Text(
                              profile.academicLabel!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CompactMetrics({
                  DataProfile.progress: detailValue(
                    profile.averageProgress,
                    suffix: '%',
                  ),
                  'Khóa học': detailValue(profile.totalCourses),
                  if (profile.averageAttendancePercentage != null)
                    DataProfile.isReal
                        ? 'Điểm chuyên cần'
                        : 'Chuyên cần': detailValue(
                      profile.averageAttendancePercentage,
                      suffix: '%',
                    ),
                }),
              ];
            },
          ),
          const SizedBox(height: 8),
          LearningHealthHomeTile(api: _api),
          TodayPlanCard(api: _api),
          FocusEntryCard(api: _api),
          DueFlashcardsChip(api: _api),
          SectionHeader(
            DataProfile.todayPriority,
            action: 'Tất cả việc cần làm',
            onAction: _tasks,
          ),
          _HomeSection<List<StudentTask>>(
            future: _taskData,
            onRetry: () => setState(() {
              _taskData = _capture(_api.getAllStudentTasks());
            }),
            children: (tasks) {
              final priority = StudentTask.sorted(
                tasks.where((t) => t.isPending).toList(),
                DateTime.now(),
              ).take(MediaQuery.sizeOf(context).width < 600 ? 2 : 3);
              return [
                if (priority.isEmpty)
                  const EmptyState('Bạn đã hoàn thành tất cả việc cần làm'),
                ...priority.map(TaskCard.new),
              ];
            },
          ),
          StudyRecommendationsSection(api: _api),
          const SectionHeader('Tiếp tục học'),
          _HomeSection<List<StudentLearningItem>>(
            future: _suggestions,
            onRetry: () => setState(() {
              _suggestions = _capture(_api.getContinueLearning());
            }),
            children: (items) => [
              if (items.isEmpty)
                const EmptyState(
                  'Chưa có gợi ý học tiếp',
                  subtitle: 'Mở khóa học để chọn nội dung bạn muốn học.',
                ),
              for (final item in items) ...[
                ActivityCard(
                  item,
                  action: 'Tiếp tục',
                  onFallback: (item.courseId ?? 0) > 0
                      ? () => _openSuggestion(item)
                      : null,
                ),
              ],
            ],
          ),
          SectionHeader(
            'Khóa học của bạn',
            action: 'Xem tất cả',
            onAction: _courses,
          ),
          _HomeSection<List<StudentCourse>>(
            future: _courseData,
            onRetry: () => setState(() {
              _courseData = _capture(_api.getStudentCourses());
            }),
            children: (courses) => [
              if (courses.isEmpty) const EmptyState('Bạn chưa có khóa học'),
              for (final course in courses.take(3))
                CourseProgressCard(
                  course: course,
                  onTap: () => _openCourse(course),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _HomeSection<T> extends StatelessWidget {
  final Future<AsyncSnapshot<T>> future;
  final VoidCallback onRetry;
  final List<Widget> Function(T) children;
  const _HomeSection({
    required this.future,
    required this.onRetry,
    required this.children,
  });
  @override
  Widget build(BuildContext context) => FutureBuilder<AsyncSnapshot<T>>(
    future: future,
    builder: (context, outer) {
      if (outer.connectionState != ConnectionState.done) {
        return const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final result = outer.data;
      if (result == null || result.hasError) {
        return CourseLoadError(onRetry: onRetry);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children(result.data as T),
      );
    },
  );
}
