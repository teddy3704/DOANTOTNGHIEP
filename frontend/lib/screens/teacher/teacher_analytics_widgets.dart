import '../../core/theme/app_colors.dart';
import '../../core/data_profile.dart';
import '../../core/relative_days.dart';
import '../../core/reminder_templates.dart';
import 'package:flutter/material.dart';

import '../../models/class_insights.dart';

Color watchGroupColor(WatchGroup g) => switch (g) {
  WatchGroup.needsSupport => Colors.red.shade600,
  WatchGroup.watch => Colors.orange.shade700,
  WatchGroup.onTrack => Colors.green.shade600,
  WatchGroup.unknown => Colors.grey,
};

/// What each group means, in words a teacher can act on.
String watchGroupMeaning(WatchGroup g) => switch (g) {
  WatchGroup.needsSupport =>
    'Điểm theo dõi từ 60 trở lên: nên liên hệ, hỗ trợ sớm.',
  WatchGroup.watch =>
    'Điểm theo dõi 30–59: có dấu hiệu chậm, một lời nhắc thường là đủ.',
  WatchGroup.onTrack => 'Điểm theo dõi dưới 30: đang học ổn định.',
  WatchGroup.unknown => 'Chưa đủ dữ liệu để đánh giá.',
};

String percentOf(int part, int total) =>
    total <= 0 ? '0%' : '${(part * 100 / total).round()}%';

String lastAccessLabel(InsightStudent s) {
  final d = s.inactiveDays;
  if (d == null) return s.detailed ? DataProfile.tt('Chưa truy cập') : '—';
  return daysAgoTitle(d);
}

typedef StudentAction = void Function(InsightStudent student);

/// A compact row of the class warning table, laid out for a phone screen.
class InsightStudentTile extends StatelessWidget {
  final InsightStudent student;
  final StudentAction? onDetail, onNote;

  /// Opened from the task-status chart: lead with the tasks in this state and
  /// leave out the watch score, which is about something else.
  final TaskState? taskFocus;

  const InsightStudentTile({
    super.key,
    required this.student,
    this.onDetail,
    this.onNote,
    this.taskFocus,
  });

  @override
  Widget build(BuildContext context) {
    final s = student;
    final theme = Theme.of(context);
    final color = watchGroupColor(s.group);
    final identity = [
      if (s.code != null) 'MSSV ${s.code}',
      if (s.classCode != null) s.classCode!,
    ].join(' · ');
    final absenceRate = s.markedSessions > 0
        ? s.absentSessions * 100 / s.markedSessions
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: .35)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (identity.isNotEmpty)
                        Text(
                          identity,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: context.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GroupBadge(s.group),
              ],
            ),
            if (taskFocus != null) ...[
              const SizedBox(height: 10),
              _TaskFocusBox(student: s, state: taskFocus!),
            ] else if (s.detailed && s.riskScore != null) ...[
              const SizedBox(height: 10),
              _ScoreExplanation(student: s, color: color),
            ],
            const SizedBox(height: 10),
            _StatGrid(
              stats: s.detailed
                  ? [
                      _MiniStat(
                        'Tiến độ',
                        s.totalActivities > 0
                            ? '${s.completedActivities}/${s.totalActivities} hoạt động (${(s.progress ?? 0).round()}%)'
                            : s.progress != null
                            ? '${s.progress!.round()}%'
                            : '—',
                        warn: s.progress != null && s.progress! < 30,
                      ),
                      _MiniStat(
                        'Bài tập',
                        s.totalTasks > 0
                            ? '${s.completedTasks}/${s.totalTasks} bài đã xong'
                                  '${s.overdue > 0 ? ', ${s.overdue} quá hạn' : ''}'
                            : 'Chưa được giao bài',
                        warn: s.overdue > 0,
                      ),
                      _MiniStat(
                        'Vắng',
                        s.markedSessions > 0
                            ? '${s.absentSessions}/${s.markedSessions} buổi (${absenceRate.round()}%)'
                            : 'Chưa điểm danh',
                        warn: absenceRate >= 20,
                      ),
                      _MiniStat(
                        'Truy cập cuối',
                        lastAccessLabel(s),
                        warn: s.inactiveDays == null || s.inactiveDays! >= 7,
                      ),
                      _MiniStat(
                        'Điểm TB',
                        s.averageGrade != null
                            ? '${s.averageGrade!.round()}% (${s.gradedItems} bài đã chấm)'
                            : 'Chưa có bài được chấm',
                        warn: s.averageGrade != null && s.averageGrade! < 50,
                      ),
                    ]
                  : [
                      _MiniStat(
                        'Tiến độ',
                        s.progress != null ? '${s.progress!.round()}%' : '—',
                        warn: s.progress != null && s.progress! < 30,
                      ),
                      _MiniStat(
                        'Quá hạn',
                        '${s.overdue} bài',
                        warn: s.overdue > 0,
                      ),
                      _MiniStat('Truy cập cuối', lastAccessLabel(s)),
                    ],
            ),
            // The older attention list only has text reasons; show them as-is.
            if (!s.detailed && s.signals.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final sig in s.signals) SignalChip(sig)],
              ),
            ],
            if (onDetail != null || onNote != null)
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  children: [
                    if (onNote != null)
                      TextButton.icon(
                        onPressed: () => onNote!(s),
                        icon: const Icon(Icons.edit_note, size: 18),
                        label: const Text('Ghi chú'),
                      ),
                    if (onDetail != null)
                      TextButton.icon(
                        onPressed: () => onDetail!(s),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Chi tiết'),
                      ),
                  ],
                ),
              )
            else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// "Điểm theo dõi 65/100" with the rules that produced it, so the group is never a black box.
class _ScoreExplanation extends StatelessWidget {
  final InsightStudent student;
  final Color color;
  const _ScoreExplanation({required this.student, required this.color});

  @override
  Widget build(BuildContext context) {
    final score = student.riskScore!;
    final sum = student.scoreBreakdown.fold<int>(0, (a, p) => a + p.points);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Điểm theo dõi: '),
                TextSpan(
                  text: '$score/100',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: (score / 100).clamp(0, 1),
              color: color,
              backgroundColor: context.hairline,
            ),
          ),
          const SizedBox(height: 6),
          if (student.scoreBreakdown.isEmpty)
            Text(
              'Không có tiêu chí nào bị cộng điểm.',
              style: TextStyle(fontSize: 12, color: Colors.green.shade700),
            )
          else ...[
            for (final p in student.scoreBreakdown)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 34,
                      child: Text(
                        '+${p.points}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        p.label,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            if (sum > 100)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Tổng $sum điểm, tính tối đa 100.',
                  style: TextStyle(fontSize: 11, color: context.muted),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Label and colour of each task state, shared by the chart legend and the sheets.
(String, Color) taskStateStyle(TaskState s) => switch (s) {
  TaskState.completed => ('Đã nộp / đã làm', Colors.green.shade700),
  TaskState.pending => ('Chưa nộp, còn hạn', Colors.orange.shade800),
  TaskState.overdue => ('Quá hạn, chưa nộp', Colors.red.shade700),
};

/// The student's tasks in one state, by name, e.g. "Đã nộp / đã làm: 1/4 bài".
class _TaskFocusBox extends StatelessWidget {
  static const _maxListed = 4;
  final InsightStudent student;
  final TaskState state;
  const _TaskFocusBox({required this.student, required this.state});

  @override
  Widget build(BuildContext context) {
    final (label, color) = taskStateStyle(state);
    final matching = student.tasks.where((t) => t.state == state).toList();
    final count = student.countIn(state);
    final total = student.tasks.isNotEmpty
        ? student.tasks.length
        : student.totalTasks;
    final now = DateTime.now();
    String dueText(StudentTaskItem t) {
      final d = t.due;
      if (d == null || state == TaskState.completed) return '';
      final late = now.difference(d).inDays;
      return state == TaskState.overdue && late > 0
          ? ' · hạn ${d.day}/${d.month}, trễ $late ngày'
          : ' · hạn ${d.day}/${d.month}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        border: Border.all(color: color.withValues(alpha: .3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            total > 0 ? '$label: $count/$total bài' : '$label: $count bài',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          for (final t in matching.take(_maxListed))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    t.isQuiz ? Icons.quiz_outlined : Icons.assignment_outlined,
                    size: 15,
                    color: context.muted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${t.title}${dueText(t)}',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          if (matching.length > _maxListed)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'và ${matching.length - _maxListed} bài khác',
                style: TextStyle(fontSize: 12, color: context.muted),
              ),
            ),
        ],
      ),
    );
  }
}

/// Two label/value pairs per line, wrapping cleanly at any width or text size.
class _StatGrid extends StatelessWidget {
  final List<_MiniStat> stats;
  const _StatGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [for (final s in stats) SizedBox(width: w, child: s)],
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final bool warn;
  const _MiniStat(this.label, this.value, {this.warn = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: context.muted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: warn ? Colors.red.shade700 : null,
          ),
        ),
      ],
    );
  }
}

class GroupBadge extends StatelessWidget {
  final WatchGroup group;
  const GroupBadge(this.group, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = watchGroupColor(group);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 4),
          Text(
            group.label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class SignalChip extends StatelessWidget {
  final StudentSignal signal;
  const SignalChip(this.signal, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = signal.strong ? Colors.red.shade700 : Colors.orange.shade800;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        border: Border.all(color: color.withValues(alpha: .35)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(signal.label, style: TextStyle(fontSize: 11.5, color: color)),
    );
  }
}

/// Students shown a page at a time, with a name/MSSV search for long lists.
class StudentDrilldownList extends StatefulWidget {
  final List<InsightStudent> students;
  final String emptyText;
  final StudentAction? onDetail, onNote;
  final int pageSize;
  final TaskState? taskFocus;

  const StudentDrilldownList({
    super.key,
    required this.students,
    this.emptyText = 'Không có sinh viên nào trong mục này.',
    this.onDetail,
    this.onNote,
    this.pageSize = 10,
    this.taskFocus,
  });

  @override
  State<StudentDrilldownList> createState() => _StudentDrilldownListState();
}

class _StudentDrilldownListState extends State<StudentDrilldownList> {
  late int _visible = widget.pageSize;
  String _query = '';

  @override
  void didUpdateWidget(StudentDrilldownList old) {
    super.didUpdateWidget(old);
    if (!identical(old.students, widget.students)) _visible = widget.pageSize;
  }

  List<InsightStudent> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.students;
    return widget.students
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              (s.code?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.students.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(widget.emptyText, style: TextStyle(color: context.muted)),
      );
    }
    final list = _filtered;
    final shown = list.take(_visible).toList();
    final remaining = list.length - shown.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.students.length > widget.pageSize)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              decoration: const InputDecoration(
                isDense: true,
                prefixIcon: Icon(Icons.search, size: 20),
                hintText: 'Tìm theo MSSV hoặc tên',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() {
                _query = v;
                _visible = widget.pageSize;
              }),
            ),
          ),
        if (list.isEmpty)
          Text(
            'Không tìm thấy sinh viên phù hợp.',
            style: TextStyle(color: context.muted),
          ),
        for (final s in shown)
          InsightStudentTile(
            student: s,
            onDetail: widget.onDetail,
            onNote: widget.onNote,
            taskFocus: widget.taskFocus,
          ),
        if (list.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Đang hiển thị ${shown.length}/${list.length} sinh viên',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: context.muted),
            ),
          ),
        if (remaining > 0)
          TextButton(
            onPressed: () => setState(() => _visible += widget.pageSize),
            child: Text(
              'Xem thêm ${remaining < widget.pageSize ? remaining : widget.pageSize} sinh viên',
            ),
          ),
      ],
    );
  }
}

/// Every analytics chart, laid out the same way: an icon and a plain title, one line on
/// what it shows, the summary first (so the reader gets the answer without decoding the
/// chart), the chart, a short hint on what can be tapped, and the formula tucked away.
class InsightCard extends StatelessWidget {
  final String title, description;
  final IconData icon;
  final Color? color;
  final List<Widget> children;
  final String? takeaway, hint;
  final List<String> howCalculated;
  final List<Widget> howCalculatedExtra;
  const InsightCard({
    super.key,
    required this.title,
    required this.description,
    required this.children,
    this.icon = Icons.insights_outlined,
    this.color,
    this.takeaway,
    this.hint,
    this.howCalculated = const [],
    this.howCalculatedExtra = const [],
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: TextStyle(fontSize: 13, color: context.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (takeaway != null) ...[
              const SizedBox(height: 12),
              TakeawayBox(takeaway!),
            ],
            const SizedBox(height: 16),
            ...children,
            if (hint != null) ...[const SizedBox(height: 10), TapHint(hint!)],
            if (howCalculated.isNotEmpty || howCalculatedExtra.isNotEmpty) ...[
              const SizedBox(height: 10),
              HowCalculatedBox(howCalculated, extra: howCalculatedExtra),
            ],
          ],
        ),
      ),
    );
  }
}

/// A small grey line saying what can be tapped.
class TapHint extends StatelessWidget {
  final String text;
  const TapHint(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.touch_app_outlined, size: 16, color: context.muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: context.muted),
          ),
        ),
      ],
    );
  }
}

class TakeawayBox extends StatelessWidget {
  final String text;
  const TakeawayBox(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.tint(Colors.amber),
        border: Border.all(color: context.tintBorder(Colors.amber)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber.shade900),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Tóm tắt: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: text),
                ],
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Cách tính", closed until the reader taps it: the formula is there for whoever
/// wants to check a number, without crowding the chart for everyone else.
class HowCalculatedBox extends StatefulWidget {
  final List<String> lines;
  final List<Widget> extra;
  final bool initiallyExpanded;
  const HowCalculatedBox(
    this.lines, {
    super.key,
    this.extra = const [],
    this.initiallyExpanded = false,
  });

  @override
  State<HowCalculatedBox> createState() => _HowCalculatedBoxState();
}

class _HowCalculatedBoxState extends State<HowCalculatedBox> {
  late bool _open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final ink = context.strong;
    return Material(
      color: context.tint(Colors.blueGrey),
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.calculate_outlined, size: 18, color: ink),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Cách tính',
                      style: TextStyle(fontWeight: FontWeight.w600, color: ink),
                    ),
                  ),
                  Text(
                    _open ? 'Ẩn' : 'Xem',
                    style: TextStyle(fontSize: 12.5, color: ink),
                  ),
                  Icon(
                    _open ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: ink,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.topCenter,
            child: !_open
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final l in widget.lines)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• $l',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ...widget.extra,
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// A bold heading that groups the cards below it, e.g. "Tiến độ và kết quả".
class AnalyticsSectionHeader extends StatelessWidget {
  final String title, subtitle;
  const AnalyticsSectionHeader(this.title, this.subtitle, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 38,
            margin: const EdgeInsets.only(right: 10, top: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12.5, color: context.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A quick filter offered inside a student sheet, e.g. "Có bài quá hạn".
class SheetFilter {
  final String label;
  final bool Function(InsightStudent) test;
  const SheetFilter(this.label, this.test);
}

/// Opens the students behind one chart mark (a slice, a legend row, a bar) in a
/// bottom sheet that rises over the chart, so the result of a tap is never missed.
Future<void> showStudentListSheet(
  BuildContext context, {
  required String title,
  required String description,
  required Color color,
  required List<InsightStudent> students,
  List<String> howCalculated = const [],
  List<SheetFilter> filters = const [],
  TaskState? taskFocus,
  ReminderDraft? reminderDraft,
  StudentAction? onDetail,
  StudentAction? onNote,
}) {
  final remind = ReminderScope.maybeOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .85,
      minChildSize: .4,
      maxChildSize: .95,
      builder: (_, controller) => _StudentSheetBody(
        controller: controller,
        title: title,
        description: description,
        color: color,
        students: students,
        howCalculated: howCalculated,
        filters: filters,
        taskFocus: taskFocus,
        onRemind: remind == null
            ? null
            : (list) => remind(list, reminderDraft ?? ReminderDraft.general),
        onDetail: onDetail == null
            ? null
            : (s) {
                Navigator.pop(sheetContext);
                onDetail(s);
              },
        onNote: onNote == null
            ? null
            : (s) {
                Navigator.pop(sheetContext);
                onNote(s);
              },
      ),
    ),
  );
}

class _StudentSheetBody extends StatefulWidget {
  final ScrollController controller;
  final String title, description;
  final Color color;
  final List<InsightStudent> students;
  final List<String> howCalculated;
  final List<SheetFilter> filters;
  final TaskState? taskFocus;
  final StudentAction? onDetail, onNote;
  final Future<bool> Function(List<InsightStudent>)? onRemind;

  const _StudentSheetBody({
    required this.controller,
    required this.title,
    required this.description,
    required this.color,
    required this.students,
    required this.howCalculated,
    required this.filters,
    this.taskFocus,
    this.onDetail,
    this.onNote,
    this.onRemind,
  });

  @override
  State<_StudentSheetBody> createState() => _StudentSheetBodyState();
}

class _StudentSheetBodyState extends State<_StudentSheetBody> {
  SheetFilter? _filter;

  @override
  Widget build(BuildContext context) {
    final shown = _filter == null
        ? widget.students
        : widget.students.where(_filter!.test).toList();
    final usable = [
      for (final f in widget.filters)
        if (widget.students.any(f.test)) f,
    ];
    return ListView(
      controller: widget.controller,
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 24),
      children: [
        Row(
          children: [
            Icon(Icons.circle, size: 14, color: widget.color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${widget.title} · ${widget.students.length} sinh viên',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Đóng',
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.description,
                style: TextStyle(fontSize: 13, color: context.muted),
              ),
              if (widget.howCalculated.isNotEmpty) ...[
                const SizedBox(height: 10),
                HowCalculatedBox(widget.howCalculated),
              ],
              if (usable.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    FilterChip(
                      visualDensity: VisualDensity.compact,
                      label: Text('Tất cả (${widget.students.length})'),
                      selected: _filter == null,
                      onSelected: (_) => setState(() => _filter = null),
                    ),
                    for (final f in usable)
                      FilterChip(
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          '${f.label} (${widget.students.where(f.test).length})',
                        ),
                        selected: _filter == f,
                        onSelected: (on) =>
                            setState(() => _filter = on ? f : null),
                      ),
                  ],
                ),
              ],
              if (widget.onRemind != null && shown.isNotEmpty) ...[
                const SizedBox(height: 12),
                RemindAllButton(
                  count: shown.length,
                  onPressed: () => widget.onRemind!(shown),
                ),
              ],
              const SizedBox(height: 12),
              StudentDrilldownList(
                students: shown,
                onDetail: widget.onDetail,
                onNote: widget.onNote,
                taskFocus: widget.taskFocus,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Default wording for a reminder; the teacher can edit both fields before sending.
class ReminderDraft {
  final String title, message;
  final String? sourceType;
  final int? sourceId;
  const ReminderDraft(
    this.title,
    this.message, {
    this.sourceType,
    this.sourceId,
  });

  static const general = ReminderDraft(
    'Nhắc nhở học tập',
    'Thầy/cô thấy dạo gần đây em chưa theo kịp khóa học. Em hãy vào khóa học để cập nhật bài '
        'và nhắn cho thầy/cô nếu gặp khó khăn nhé.',
  );

  /// Wording for students who have not handed in one assignment/quiz yet.
  factory ReminderDraft.forActivity({
    required String title,
    required String type,
    required int? sourceId,
    required DateTime? due,
  }) {
    String two(int n) => n.toString().padLeft(2, '0');
    final work = type == 'quiz' ? 'bài kiểm tra' : 'bài';
    final source = sourceId == null
        ? null
        : (type == 'quiz' ? 'quiz' : 'assignment');
    if (due != null && due.isBefore(DateTime.now())) {
      return ReminderDraft(
        'Bài quá hạn: $title',
        'Em chưa nộp $work "$title" (hạn ${two(due.day)}/${two(due.month)}). Em hãy hoàn thành sớm nhất '
            'có thể và báo thầy/cô nếu cần hỗ trợ nhé.',
        sourceType: source,
        sourceId: sourceId,
      );
    }
    return ReminderDraft(
      'Nhắc nộp bài: $title',
      due == null
          ? 'Em chưa nộp $work "$title". Em nhớ hoàn thành sớm nhé.'
          : 'Em chưa nộp $work "$title", hạn lúc ${two(due.hour)}:${two(due.minute)} '
                '${two(due.day)}/${two(due.month)}. Em nhớ hoàn thành trước hạn nhé, có khó khăn thì nhắn thầy/cô.',
      sourceType: source,
      sourceId: sourceId,
    );
  }
}

typedef RemindStudents =
    Future<bool> Function(List<InsightStudent> students, ReminderDraft draft);

/// Lets every student list under the analytics tab offer "Nhắc N sinh viên" without
/// threading a callback through each chart.
class ReminderScope extends InheritedWidget {
  final RemindStudents remind;
  const ReminderScope({super.key, required this.remind, required super.child});

  static RemindStudents? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ReminderScope>()?.remind;

  @override
  bool updateShouldNotify(ReminderScope oldWidget) =>
      remind != oldWidget.remind;
}

class RemindAllButton extends StatelessWidget {
  final int count;
  final VoidCallback onPressed;
  final String? label;
  const RemindAllButton({
    super.key,
    required this.count,
    required this.onPressed,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: const Icon(Icons.notifications_active_outlined, size: 18),
      label: Text(label ?? 'Nhắc $count sinh viên'),
    );
  }
}

/// Lets the teacher check who will be reminded and edit the wording before sending.
/// Returns true once the reminders were sent.
Future<bool> showReminderComposer(
  BuildContext context, {
  required List<String> recipients,
  required ReminderDraft draft,
  required Future<int> Function(String title, String message) send,
  List<ReminderTemplate> templates = const [],
}) async {
  final sent = await showDialog<int>(
    context: context,
    builder: (_) => _ReminderComposer(
      recipients: recipients,
      draft: draft,
      send: send,
      templates: templates,
    ),
  );
  if (sent != null && context.mounted) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text('Đã gửi nhắc nhở tới $sent sinh viên.')),
    );
  }
  return sent != null;
}

class _ReminderComposer extends StatefulWidget {
  final List<String> recipients;
  final ReminderDraft draft;
  final Future<int> Function(String title, String message) send;

  /// V2-N8 templates for one student; tapping one fills title and message.
  final List<ReminderTemplate> templates;
  const _ReminderComposer({
    required this.recipients,
    required this.draft,
    required this.send,
    this.templates = const [],
  });

  @override
  State<_ReminderComposer> createState() => _ReminderComposerState();
}

class _ReminderComposerState extends State<_ReminderComposer> {
  late final _title = TextEditingController(text: widget.draft.title);
  late final _message = TextEditingController(text: widget.draft.message);
  bool _sending = false;
  String? _error;
  // The chip of the template the dialog opened with is shown as selected.
  late TemplateKind? _template = widget.templates
      .where(
        (t) =>
            t.title == widget.draft.title && t.message == widget.draft.message,
      )
      .firstOrNull
      ?.kind;

  void _useTemplate(ReminderTemplate t) => setState(() {
    _template = t.kind;
    _title.text = t.title;
    _message.text = t.message;
  });

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _title.text.trim(), message = _message.text.trim();
    if (title.isEmpty || message.isEmpty) {
      setState(() => _error = 'Hãy nhập đủ tiêu đề và nội dung.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final sent = await widget.send(title, message);
      if (mounted) Navigator.pop(context, sent);
    } catch (_) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = 'Không gửi được nhắc nhở. Vui lòng thử lại.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const shownNames = 4;
    final names = widget.recipients.take(shownNames).join(', ');
    final more = widget.recipients.length - shownNames;
    return AlertDialog(
      title: Text(
        widget.recipients.length == 1
            ? 'Nhắc riêng ${widget.recipients.single}'
            : 'Nhắc ${widget.recipients.length} sinh viên',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Gửi tới: $names${more > 0 ? ' và $more sinh viên khác' : ''}.',
              style: TextStyle(fontSize: 13, color: context.strong),
            ),
            if (widget.templates.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final t in widget.templates)
                    ChoiceChip(
                      key: Key('reminder-template-${t.kind.name}'),
                      label: Text(t.label),
                      selected: _template == t.kind,
                      onSelected: _sending ? null : (_) => _useTemplate(t),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              enabled: !_sending,
              maxLength: 255,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _message,
              enabled: !_sending,
              minLines: 3,
              maxLines: 6,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Nội dung',
                border: OutlineInputBorder(),
              ),
            ),
            Text(
              'Sinh viên nhận thông báo trong ứng dụng. Lần nhắc được lưu vào ghi chú hỗ trợ để '
              'mục "Hiệu quả hỗ trợ" theo dõi sinh viên có quay lại học hay không.',
              style: TextStyle(fontSize: 12, color: context.muted),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Colors.red.shade700)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          onPressed: _sending ? null : _submit,
          icon: _sending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send, size: 18),
          label: const Text('Gửi'),
        ),
      ],
    );
  }
}
