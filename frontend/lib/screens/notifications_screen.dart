import '../core/theme/app_colors.dart';
import '../core/display_text.dart';

import 'package:flutter/material.dart';

import '../models/learning_notification.dart';
import '../models/student_course_detail.dart';
import '../models/student_course.dart';
import '../models/teacher_course.dart';
import '../services/api_service.dart';
import '../widgets/async_tab.dart';
import '../widgets/learning_widgets.dart';
import '../widgets/moodle_button.dart';
import 'student/student_course_detail_screen.dart';
import 'student/student_task_center_screen.dart';
import 'teacher/teacher_course_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final ApiService api;
  final bool teacher;
  final VoidCallback? onTasks;

  /// Called after a reminder is marked seen, e.g. to refresh the unread badge.
  final VoidCallback? onRead;
  const NotificationsScreen({
    super.key,
    required this.api,
    this.teacher = false,
    this.onTasks,
    this.onRead,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  /// Marked read in this session; the server confirms on the next load.
  final Set<int> _readNow = {};

  bool _unread(LearningNotification n) =>
      n.isRead == false && !_readNow.contains(n.id);

  Future<void> _markRead(LearningNotification n) async {
    final id = n.id;
    if (id == null) return;
    setState(() => _readNow.add(id));
    try {
      await widget.api.markNotificationRead(id);
      widget.onRead?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() => _readNow.remove(id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không cập nhật được trạng thái. Vui lòng thử lại.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Thông báo'),
      automaticallyImplyLeading: false,
    ),
    body: AsyncTab<List<LearningNotification>>(
      load: () => widget.api.getNotifications(teacher: widget.teacher),
      children: (items) {
        final fromTeacher =
            widget.teacher
                  ? <LearningNotification>[]
                  : items.where((n) => n.fromTeacher).toList()
              // Unread first, then newest.
              ..sort((a, b) {
                final u = (_unread(a) ? 0 : 1).compareTo(_unread(b) ? 0 : 1);
                return u != 0
                    ? u
                    : (b.time ?? DateTime(0)).compareTo(a.time ?? DateTime(0));
              });
        final others = items.where((n) => !fromTeacher.contains(n)).toList();
        final unread = fromTeacher.where(_unread).length;
        return [
          if (items.isEmpty)
            const EmptyState(
              'Bạn chưa có thông báo mới',
              subtitle: 'Kiểm tra Việc cần làm để theo dõi hạn nộp.',
            ),
          if (fromTeacher.isNotEmpty) ...[
            _SectionTitle(
              icon: Icons.campaign_outlined,
              title: 'Nhắc nhở từ giảng viên',
              badge: unread > 0 ? '$unread mới' : null,
            ),
            for (final n in fromTeacher)
              _TeacherReminderCard(
                item: n,
                unread: _unread(n),
                onRead: n.id == null ? null : () => _markRead(n),
                onOpen: n.studentCourseTab == null
                    ? null
                    : () {
                        if (_unread(n)) _markRead(n);
                        _openStudentCourse(context, widget.api, n);
                      },
              ),
            if (others.isNotEmpty)
              const _SectionTitle(
                icon: Icons.notifications_none,
                title: 'Thông báo khác',
              ),
          ],
          for (final item in others)
            _NotificationCard(
              item: item,
              teacher: widget.teacher,
              api: widget.api,
              onTasks: widget.onTasks,
            ),
        ];
      },
    ),
  );
}

/// Opens the course tab a student's notification is about (grades, tasks, content…).
void _openStudentCourse(
  BuildContext context,
  ApiService api,
  LearningNotification item,
) {
  final target = item.studentCourseTab;
  if (target == null) return;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => StudentCourseDetailScreen(
        apiService: api,
        course: StudentCourse(
          courseId: item.course!,
          courseName: item.courseName ?? 'Khóa học',
        ),
        initialTab: target.$1,
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? badge;
  const _SectionTitle({required this.icon, required this.title, this.badge});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A reminder a teacher sent: who sent it, about which course and activity, and
/// a way to open that activity or mark the reminder as seen.
class _TeacherReminderCard extends StatelessWidget {
  final LearningNotification item;
  final bool unread;
  final VoidCallback? onRead, onOpen;
  const _TeacherReminderCard({
    required this.item,
    required this.unread,
    this.onRead,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final accent = unread ? Colors.deepOrange : context.muted;
    final link =
        moodleActivityUri(item.moodlePath, item.courseModuleId) != null;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      color: unread ? context.tint(Colors.deepOrange) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: accent.withValues(alpha: unread ? .6 : .3),
          width: unread ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: accent.withValues(alpha: .15),
                    child: Icon(Icons.school_outlined, size: 20, color: accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.senderName != null
                              ? 'Giảng viên ${item.senderName}'
                              : 'Giảng viên của bạn',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (item.courseName != null)
                          Text(
                            DemoDisplayNames.course(item.courseName!),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  if (unread)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Mới',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (item.message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(item.message!),
                ),
              if (item.time != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Gửi lúc ${formatDeadline(item.time)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              Wrap(
                spacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (onOpen != null)
                    TextButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.school_outlined, size: 18),
                      label: Text(item.studentCourseTab!.$2),
                    ),
                  if (link)
                    MoodleButton(
                      path: item.moodlePath,
                      courseModuleId: item.courseModuleId,
                      label: 'Mở bài trên LMS',
                      compact: true,
                    ),
                  if (unread && onRead != null)
                    TextButton.icon(
                      onPressed: onRead,
                      icon: const Icon(Icons.done, size: 18),
                      label: const Text('Đã xem'),
                    )
                  else if (!unread && item.isRead != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      child: Text(
                        'Đã xem',
                        style: TextStyle(fontSize: 12.5, color: context.muted),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final LearningNotification item;
  final bool teacher;
  final ApiService api;
  final VoidCallback? onTasks;
  const _NotificationCard({
    required this.item,
    required this.teacher,
    required this.api,
    this.onTasks,
  });

  /// A teacher's course notification opens that course; a "students need support" alert
  /// opens its analytics tab, where the list and the reasons are.
  void _openCourse(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => TeacherCourseDetailScreen(
        apiService: api,
        course: TeacherCourse(
          courseId: item.course!,
          courseName: item.courseName ?? 'Khóa học',
        ),
        initialTab: item.opensAnalytics
            ? TeacherCourseDetailScreen.analyticsTab
            : 0,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final openCourse = teacher && item.course != null;
    final studentTab = teacher ? null : item.studentCourseTab;
    final link =
        moodleActivityUri(item.moodlePath, item.courseModuleId) != null;
    final card = DetailCard(
      title: item.title,
      children: [
        Wrap(children: [StatusChip(item.reminder ? 'Nhắc nhở' : 'Thông báo')]),
        if (item.courseName != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              DemoDisplayNames.course(item.courseName!),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (item.message != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(item.message!),
          ),
        if (item.time != null)
          Text(
            formatDeadline(item.time),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (openCourse)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: FilledButton.tonalIcon(
              onPressed: () => _openCourse(context),
              icon: Icon(
                item.opensAnalytics
                    ? Icons.insights_outlined
                    : Icons.school_outlined,
                size: 18,
              ),
              label: Text(
                item.opensAnalytics ? 'Mở trang Phân tích' : 'Mở khóa học',
              ),
            ),
          )
        else if (studentTab != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _openStudentCourse(context, api, item),
                  icon: const Icon(Icons.school_outlined, size: 18),
                  label: Text(studentTab.$2),
                ),
                if (link)
                  MoodleButton(
                    path: item.moodlePath,
                    courseModuleId: item.courseModuleId,
                    compact: true,
                  ),
              ],
            ),
          )
        else if (link)
          MoodleButton(
            path: item.moodlePath,
            courseModuleId: item.courseModuleId,
            compact: true,
          )
        else if (!teacher && (item.courseId != null || item.sourceId != null))
          TextButton.icon(
            onPressed:
                onTasks ??
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentTaskCenterScreen(api: api),
                  ),
                ),
            icon: const Icon(Icons.checklist, size: 18),
            label: const Text('Kiểm tra việc cần làm'),
          ),
      ],
    );
    return openCourse
        ? InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openCourse(context),
            child: card,
          )
        : studentTab != null
        ? InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openStudentCourse(context, api, item),
            child: card,
          )
        : card;
  }
}
