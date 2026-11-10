import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';

import '../../models/learning_notification.dart';
import '../../services/api_service.dart';
import 'student_dashboard_screen.dart';
import 'student_courses_screen.dart';
import 'student_task_center_screen.dart';
import 'student_analytics_screen.dart';
import '../notifications_screen.dart';
import '../../services/reminder_service.dart';
import '../../widgets/offline_banner.dart';

class StudentMainScreen extends StatefulWidget {
  final ApiService? apiService;
  final ReminderService? reminders;
  const StudentMainScreen({super.key, this.apiService, this.reminders});
  @override
  State<StudentMainScreen> createState() => _StudentMainScreenState();
}

class _StudentMainScreenState extends State<StudentMainScreen> {
  static const _notificationsTab = 3;
  late final ApiService _api = widget.apiService ?? ApiService();
  late final ReminderService _reminders = widget.reminders ?? ReminderService();
  int _index = 0;
  final _visited = <int>{0};

  /// Unread reminders from teachers, newest first; drives the badge and the home banner.
  List<LearningNotification> _teacherUnread = const [];

  @override
  void initState() {
    super.initState();
    _refreshUnread();
    // V2-N7: keep phone reminders in step with the latest deadlines, cards and plan.
    _reminders.refreshQuietly(_api);
  }

  void _select(int index) {
    setState(() {
      _index = index;
      _visited.add(index);
    });
    _refreshUnread();
  }

  /// Best effort: a failed request leaves the badge as it was and never blocks a tab.
  Future<void> _refreshUnread() async {
    try {
      final items = await _api.getNotifications();
      final unread =
          items.where((n) => n.fromTeacher && n.isRead == false).toList()..sort(
            (a, b) => (b.time ?? DateTime(0)).compareTo(a.time ?? DateTime(0)),
          );
      if (mounted) setState(() => _teacherUnread = unread);
    } catch (_) {
      /* The notifications tab shows its own error when opened. */
    }
  }

  @override
  void dispose() {
    if (widget.apiService == null) _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unread = _teacherUnread.length;
    return Scaffold(
      body: Column(
        children: [
          OfflineBanner(api: _api),
          Expanded(
            // The banner already covers the status bar; the screens below must not add it again.
            child: ValueListenableBuilder<DateTime?>(
              valueListenable: _api.offlineSince,
              builder: (context, offline, child) => MediaQuery.removePadding(
                context: context,
                removeTop: offline != null,
                child: child!,
              ),
              child: IndexedStack(
                index: _index,
                children: [
                  StudentDashboardScreen(
                    apiService: _api,
                    onTasks: () => _select(1),
                    onCourses: () => _select(2),
                    reminders: _reminders,
                    banner: unread == 0
                        ? null
                        : TeacherReminderBanner(
                            latest: _teacherUnread.first,
                            count: unread,
                            onOpen: () => _select(_notificationsTab),
                          ),
                  ),
                  if (_visited.contains(1))
                    StudentTaskCenterScreen(api: _api)
                  else
                    const SizedBox.shrink(),
                  if (_visited.contains(2))
                    StudentCoursesScreen(apiService: _api)
                  else
                    const SizedBox.shrink(),
                  if (_visited.contains(_notificationsTab))
                    NotificationsScreen(
                      api: _api,
                      onTasks: () => _select(1),
                      onRead: _refreshUnread,
                    )
                  else
                    const SizedBox.shrink(),
                  if (_visited.contains(4))
                    StudentAnalyticsScreen(apiService: _api)
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        height:
            64 +
            16 *
                (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(0.0, 1.0),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Trang chủ',
          ),
          const NavigationDestination(
            icon: Icon(Icons.checklist),
            label: 'Việc cần làm',
          ),
          const NavigationDestination(
            icon: Icon(Icons.school_outlined),
            label: 'Khóa học',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
            label: 'Thông báo',
            tooltip: unread > 0
                ? 'Thông báo, $unread nhắc nhở mới từ giảng viên'
                : 'Thông báo',
          ),
          const NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            label: 'Phân tích',
          ),
        ],
      ),
    );
  }
}

/// Top of Home: the newest unread teacher reminder, so it is seen without opening the tab.
class TeacherReminderBanner extends StatelessWidget {
  final LearningNotification latest;
  final int count;
  final VoidCallback onOpen;
  const TeacherReminderBanner({
    super.key,
    required this.latest,
    required this.count,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.tint(Colors.deepOrange),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: context.tintBorder(Colors.deepOrange)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.campaign_outlined, color: Colors.deepOrange.shade700),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count == 1
                          ? '${latest.senderName != null ? 'Giảng viên ${latest.senderName}' : 'Giảng viên'} vừa nhắc bạn'
                          : 'Bạn có $count nhắc nhở mới từ giảng viên',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      latest.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nhấn để xem',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.deepOrange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.deepOrange.shade300),
            ],
          ),
        ),
      ),
    );
  }
}
