import '../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../models/student_course_detail.dart';
import '../models/student_course.dart';
import '../models/student_dashboard.dart';

class StudentCopilotCard extends StatelessWidget {
  final StudentDashboard profile;
  final List<StudentTask> tasks;
  final List<StudentCourse> courses;
  final VoidCallback? onAction;

  const StudentCopilotCard({
    super.key,
    required this.profile,
    required this.tasks,
    required this.courses,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Analyze tasks
    final pendingTasks = tasks.where((t) => t.isPending).toList();
    final overdueTasks = pendingTasks.where((t) => t.isOverdue(now)).toList();
    final upcomingTasks = pendingTasks.where((t) {
      if (t.deadline == null || t.isOverdue(now)) return false;
      final hours = t.deadline!.difference(now).inHours;
      return hours >= 0 && hours <= 48;
    }).toList();

    // Analyze courses
    final lowProgressCourses = courses.where((c) {
      final prog = c.progressPercentage ?? 0;
      final avg = profile.averageProgress ?? 0;
      return prog > 0 && prog < avg - 10; // 10% lower than their average
    }).toList();

    // Generate insights
    List<Widget> insights = [];

    if (overdueTasks.isNotEmpty) {
      insights.add(
        _buildInsight(
          context,
          icon: Icons.error_outline,
          color: Colors.red,
          title: 'Bạn đang có ${overdueTasks.length} nhiệm vụ quá hạn.',
          subtitle: 'Hãy hoàn thành ngay để không bị ảnh hưởng điểm số.',
        ),
      );
    }

    if (upcomingTasks.isNotEmpty) {
      insights.add(
        _buildInsight(
          context,
          icon: Icons.access_time,
          color: Colors.orange,
          title: 'Có ${upcomingTasks.length} nhiệm vụ hết hạn trong 48h tới.',
          subtitle: 'Ưu tiên: ${upcomingTasks.first.title}.',
        ),
      );
    } else if (overdueTasks.isEmpty && pendingTasks.isNotEmpty) {
      insights.add(
        _buildInsight(
          context,
          icon: Icons.check_circle_outline,
          color: Colors.green,
          title: 'Bạn đang theo đúng tiến độ!',
          subtitle: 'Không có nhiệm vụ nào gấp trong 48h tới.',
        ),
      );
    }

    if (lowProgressCourses.isNotEmpty) {
      insights.add(
        _buildInsight(
          context,
          icon: Icons.trending_down,
          color: Colors.orange,
          title:
              'Khóa học ${lowProgressCourses.first.courseName} đang chậm hơn tiến độ chung.',
          subtitle: 'Dành thêm 15 phút hôm nay để theo kịp nhé.',
        ),
      );
    }

    if (insights.isEmpty) {
      insights.add(
        _buildInsight(
          context,
          icon: Icons.star_border,
          color: Theme.of(context).colorScheme.primary,
          title: 'Tuyệt vời, bạn đã hoàn thành mọi mục tiêu!',
          subtitle: 'Hãy xem lại các bài giảng cũ hoặc nghỉ ngơi nhé.',
        ),
      );
    }

    return Card(
      elevation: 0,
      color: context.tint(Colors.green),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.tintBorder(Colors.green)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Trợ lý học tập',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...insights
                .take(3)
                .map(
                  (insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: insight,
                  ),
                ),
            if (onAction != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Xem chi tiết việc cần làm'),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsight(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: context.muted, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TeacherCopilotCard extends StatelessWidget {
  final int studentsNeedAttention;
  final int needsGradingCount;
  final int upcomingDeadlines;
  final VoidCallback? onAction;

  const TeacherCopilotCard({
    super.key,
    required this.studentsNeedAttention,
    required this.needsGradingCount,
    required this.upcomingDeadlines,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> insights = [];

    if (studentsNeedAttention > 0) {
      insights.add(
        _CopilotInsight(
          icon: Icons.people_outline,
          color: Colors.orange,
          title:
              'Phát hiện $studentsNeedAttention sinh viên có dấu hiệu cần hỗ trợ.',
          evidence:
              'Dựa trên tiến độ hoàn thành và hạn nộp (độ tin cậy: Trung bình).',
          actionLabel: 'Nên gửi tin nhắn thăm hỏi hoặc nhắc nhở trên diễn đàn.',
        ),
      );
    }

    if (needsGradingCount > 0) {
      insights.add(
        _CopilotInsight(
          icon: Icons.assignment_turned_in,
          color: Colors.blue,
          title: 'Có $needsGradingCount bài tập đang chờ chấm điểm.',
          evidence: 'Dữ liệu từ danh sách nộp bài mới nhất.',
          actionLabel: 'Nên ưu tiên chấm các bài nộp đã quá 3 ngày.',
        ),
      );
    }

    if (upcomingDeadlines > 0) {
      insights.add(
        _CopilotInsight(
          icon: Icons.schedule,
          color: Theme.of(context).colorScheme.primary,
          title:
              'Có $upcomingDeadlines hoạt động sắp đến hạn trong 7 ngày tới.',
          evidence: 'Dựa trên cấu hình thời gian mở/đóng bài tập.',
          actionLabel:
              'Kiểm tra tỷ lệ nộp bài hiện tại để có biện pháp đôn đốc.',
        ),
      );
    }

    if (insights.isEmpty) {
      insights.add(
        const _CopilotInsight(
          icon: Icons.check_circle_outline,
          color: Colors.green,
          title: 'Lớp học đang diễn ra suôn sẻ.',
          evidence: 'Không có bài cần chấm hay sinh viên cần hỗ trợ khẩn cấp.',
          actionLabel: 'Dành thời gian chuẩn bị nội dung học tập tiếp theo.',
        ),
      );
    }

    return Card(
      elevation: 0,
      color: context.tint(Colors.green),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.tintBorder(Colors.green)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Trợ lý giảng dạy',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...insights
                .take(3)
                .map(
                  (insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: insight,
                  ),
                ),
            if (onAction != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Xem danh sách công việc'),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CopilotInsight extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String evidence;
  final String actionLabel;

  const _CopilotInsight({
    required this.icon,
    required this.color,
    required this.title,
    required this.evidence,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                evidence,
                style: TextStyle(color: context.muted, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      actionLabel,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
