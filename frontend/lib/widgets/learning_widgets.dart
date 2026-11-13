import '../core/display_text.dart';
import '../core/data_profile.dart';
import '../core/date_time_text.dart';

import 'package:flutter/material.dart';

import '../models/student_course.dart';
import '../models/teacher_course.dart';
import '../models/student_course_detail.dart';
import 'async_tab.dart';
import 'moodle_button.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader(this.title, {super.key, this.action, this.onAction});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(Icons.star, color: colors.onPrimary, size: 16),
          ),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.primary,
              ),
            ),
          ),
          if (action != null)
            Flexible(
              child: TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(action!, textAlign: TextAlign.right),
              ),
            ),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  final bool warning;
  final bool danger;
  const StatusChip(
    this.label, {
    super.key,
    this.warning = false,
    this.danger = false,
  });
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = danger
        ? colors.error
        : warning
        ? Colors.orange.shade900
        : colors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width - 64,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  const EmptyState(
    this.title, {
    super.key,
    this.subtitle,
    this.icon = Icons.check_circle_outline,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
    child: Column(
      children: [
        Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, textAlign: TextAlign.center),
        ],
      ],
    ),
  );
}

class UserAvatar extends StatelessWidget {
  final String name;
  const UserAvatar(this.name, {super.key});
  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 24,
    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    // No real name (only a student code): a person icon, never the first digit of the code.
    child: name.trim().isEmpty || RegExp(r'^[0-9]').hasMatch(name.trim())
        ? const Icon(Icons.person_outline)
        : Text(name.trim().characters.first.toUpperCase()),
  );
}

class WrapConstrainedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  const WrapConstrainedText(this.text, {super.key, this.style});
  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(
      maxWidth: MediaQuery.sizeOf(context).width - 64,
    ),
    child: Text(text, style: style),
  );
}

class CompactMetrics extends StatelessWidget {
  final Map<String, String> values;
  final bool inline;
  const CompactMetrics(this.values, {super.key, this.inline = false});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final columns = inline
          ? (box.maxWidth / MediaQuery.textScalerOf(context).scale(100))
                .floor()
                .clamp(1, 3)
          : 2;
      return Wrap(
        spacing: 12,
        runSpacing: inline ? 8 : 12,
        children: values.entries.map((entry) {
          final label = Text(
            entry.key,
            style: Theme.of(context).textTheme.bodySmall,
          );
          final value = Text(
            entry.value,
            style: RegExp(r'^\d').hasMatch(entry.value)
                ? (inline
                      ? Theme.of(context).textTheme.titleMedium
                      : Theme.of(context).textTheme.titleLarge)
                : Theme.of(context).textTheme.bodySmall,
          );
          final labelFirst = inline || entry.value == 'Chưa có dữ liệu';
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              labelFirst ? label : value,
              const SizedBox(height: 4),
              labelFirst ? value : label,
            ],
          );
          return SizedBox(
            width: (box.maxWidth - 12 * (columns - 1)) / columns,
            child: inline
                ? content
                : Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: content,
                    ),
                  ),
          );
        }).toList(),
      );
    },
  );
}

class CourseProgressCard extends StatelessWidget {
  final StudentCourse course;
  final VoidCallback onTap;
  const CourseProgressCard({
    super.key,
    required this.course,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => DetailCard(
    title: DemoDisplayNames.course(course.courseName),
    titleMaxLines: 2,
    onTap: onTap,
    trailing: const Icon(Icons.chevron_right, size: 20),
    children: [
      if (course.courseShortname != null)
        Text(
          course.courseShortname!,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      const SizedBox(height: 4),
      Text(
        '${DataProfile.progress} ${detailValue(course.progressPercentage, suffix: '%')}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      if (course.progressPercentage != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: LinearProgressIndicator(
            value: (course.progressPercentage! / 100).clamp(0, 1),
          ),
        ),
      Wrap(
        spacing: 12,
        runSpacing: 4,
        children: [
          if (course.completedTasks != null && course.totalTasks != null)
            WrapConstrainedText(
              '${course.completedTasks}/${course.totalTasks} hoạt động',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (course.unfinishedTasks != null)
            WrapConstrainedText(
              '${course.unfinishedTasks} việc chưa hoàn thành',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (course.overdueTasks != null)
            WrapConstrainedText(
              '${course.overdueTasks} quá hạn',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: course.overdueTasks! > 0
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
            ),
        ],
      ),
    ],
  );
}

class TaskCard extends StatelessWidget {
  final StudentTask task;
  final bool showCourse;
  final String? actionOverride;
  const TaskCard(
    this.task, {
    super.key,
    this.showCourse = true,
    this.actionOverride,
  });
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final late = task.isOverdue(now), soon = task.isDueSoon(now);
    return DetailCard(
      title: DemoDisplayNames.activity(task.title),
      children: [
        if (showCourse && task.courseName != null)
          Text(
            DemoDisplayNames.course(task.courseName!),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              activityLabel(task.type),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            StatusChip(
              late && task.deadline != null && task.deadline!.isBefore(now)
                  ? relativeDeadline(task.deadline, now: now)
                  : late
                  ? 'Quá hạn'
                  : soon
                  ? relativeDeadline(task.deadline, now: now)
                  : task.statusLabel,
              danger: late,
              warning: soon,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          task.deadline == null && task.type == 'quiz'
              ? noQuizClose
              : 'Hạn: ${formatDeadline(task.deadline)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: MoodleButton(
            path: task.moodlePath,
            courseModuleId: task.courseModuleId,
            label: actionOverride ?? task.actionLabel,
            compact: true,
            tonal: true,
          ),
        ),
      ],
    );
  }
}

IconData activityIcon(String type) => switch (type) {
  'resource' => Icons.description_outlined,
  'folder' => Icons.folder_outlined,
  'forum' => Icons.forum_outlined,
  'assign' || 'assignment' => Icons.assignment_outlined,
  'quiz' => Icons.quiz_outlined,
  'attendance' => Icons.fact_check_outlined,
  _ => Icons.school_outlined,
};

class ActivityCard extends StatelessWidget {
  final StudentLearningItem item;
  final String action;
  final VoidCallback? onFallback;
  const ActivityCard(
    this.item, {
    super.key,
    this.action = 'Mở trên LMS',
    this.onFallback,
  });
  @override
  Widget build(BuildContext context) {
    final continuing = action == 'Tiếp tục';
    final button =
        moodleActivityUri(item.moodlePath, item.courseModuleId) == null &&
            onFallback != null
        ? OutlinedButton.icon(
            onPressed: onFallback,
            icon: const Icon(Icons.arrow_forward, size: 16),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
            label: Text(action),
          )
        : MoodleButton(
            path: item.moodlePath,
            courseModuleId: item.courseModuleId,
            label: action,
            compact: true,
            tonal: continuing,
          );
    return DetailCard(
      title: DemoDisplayNames.activity(item.name),
      children: [
        if (item.courseName != null)
          Text(
            DemoDisplayNames.course(item.courseName!),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(activityIcon(item.activityType), size: 16),
            Text(
              continuing ? item.sectionTitle : activityLabel(item.activityType),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            button,
          ],
        ),
      ],
    );
  }
}

/// Insets at both viewport edges and inside the scroll content keep end chips reachable.
class LearningFilterBar extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final bool wrap;
  const LearningFilterBar({
    super.key,
    required this.children,
    this.controller,
    this.wrap = false,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: wrap
        ? Wrap(spacing: 4, runSpacing: 4, children: children)
        : SingleChildScrollView(
            controller: controller,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 16, 4),
            child: Row(children: children),
          ),
  );
}

/// Native tabs with padded ends; re-reveal selection after layout or navigation.
class CourseTabBar extends StatefulWidget implements PreferredSizeWidget {
  final List<String> labels;
  final double textScale;
  const CourseTabBar({
    super.key,
    required this.labels,
    required this.textScale,
  });
  // At accessibility sizes, a long label may need two lines within the viewport.
  double get height =>
      textScale > 1.5 ? 24 + 40 * textScale : 28 + 20 * textScale;
  @override
  Size get preferredSize => Size.fromHeight(height + 8);
  @override
  State<CourseTabBar> createState() => _CourseTabBarState();
}

class _CourseTabBarState extends State<CourseTabBar> {
  TabController? _controller;
  late List<GlobalKey> _keys = List.generate(
    widget.labels.length,
    (_) => GlobalKey(),
  );
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to viewport changes so rotation also repositions the selection.
    MediaQuery.sizeOf(context);
    final controller = DefaultTabController.of(context);
    if (_controller != controller) {
      _controller?.removeListener(_revealSelected);
      _controller = controller..addListener(_revealSelected);
    }
    _revealSelected();
  }

  @override
  void didUpdateWidget(covariant CourseTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.labels.length != widget.labels.length) {
      _keys = List.generate(widget.labels.length, (_) => GlobalKey());
    }
    _revealSelected();
  }

  void _revealSelected() {
    if (_scheduled || _controller == null || _controller!.indexIsChanging) {
      return;
    }
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted || _controller == null || _controller!.indexIsChanging) {
        return;
      }
      final selected = _keys[_controller!.index].currentContext;
      final target = selected?.findRenderObject();
      if (selected == null || target == null) return;
      // Restrict the reveal to the tab strip, never scroll the course body.
      Scrollable.maybeOf(
        selected,
        axis: Axis.horizontal,
      )?.position.ensureVisible(
        target,
        alignment: .5,
        duration: const Duration(milliseconds: 160),
      );
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(_revealSelected);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        physics: const ClampingScrollPhysics(),
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        tabs: [
          for (var i = 0; i < widget.labels.length; i++)
            Tab(
              key: _keys[i],
              height: widget.height,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: (constraints.maxWidth - 48).clamp(
                    1,
                    double.infinity,
                  ),
                ),
                child: Text(
                  widget.labels[i],
                  softWrap: widget.textScale > 1.5,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class MonitoringReasonRow extends StatelessWidget {
  final String reason;
  const MonitoringReasonRow(this.reason, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Icon(
            reason.contains('quá hạn')
                ? Icons.error_outline
                : reason.contains('chưa hoạt động')
                ? Icons.schedule
                : Icons.trending_down,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(reason)),
      ],
    ),
  );
}

/// Shared compact course preview for the teacher home and course list.
class TeacherCourseCard extends StatelessWidget {
  final TeacherCourse course;
  final VoidCallback onTap;
  const TeacherCourseCard({
    super.key,
    required this.course,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => DetailCard(
    title: DemoDisplayNames.course(course.courseName),
    titleMaxLines: 2,
    onTap: onTap,
    trailing: const Icon(Icons.chevron_right, size: 20),
    children: [
      if (course.courseShortname != null || course.startLabel != null)
        Text(
          [?course.courseShortname, ?course.startLabel].join(' · '),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      const SizedBox(height: 4),
      Wrap(
        spacing: 12,
        runSpacing: 4,
        children: [
          WrapConstrainedText('${detailValue(course.studentCount)} sinh viên'),
          WrapConstrainedText(
            '${DataProfile.isReal ? 'Tiến độ trung bình (theo hoạt động có chấm điểm)' : 'Tiến độ trung bình'} ${formatPercentageVi(course.averageProgress)}',
          ),
        ],
      ),
      if (course.averageProgress != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: LinearProgressIndicator(
            value: (course.averageProgress! / 100).clamp(0, 1),
          ),
        ),
      Wrap(
        spacing: 12,
        runSpacing: 4,
        children: [
          WrapConstrainedText(
            course.studentsNeedAttention == null
                ? 'Sinh viên cần theo dõi: Chưa có dữ liệu'
                : '${course.studentsNeedAttention} sinh viên cần theo dõi',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          WrapConstrainedText(
            course.needsGradingCount == null
                ? 'Bài cần chấm: Chưa có dữ liệu'
                : '${course.needsGradingCount} bài cần chấm',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ],
  );
}
