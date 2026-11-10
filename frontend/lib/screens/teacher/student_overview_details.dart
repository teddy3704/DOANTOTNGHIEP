import '../../core/theme/app_colors.dart';
import '../../core/relative_days.dart';
import 'package:flutter/material.dart';

import '../../core/display_text.dart';
import '../../models/student_course_detail.dart';
import '../../models/teacher_monitoring.dart';

String _two(int n) => n.toString().padLeft(2, '0');
String _date(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';
String _dateTime(DateTime d) => '${_two(d.hour)}:${_two(d.minute)} ${_date(d)}';
String _num(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : vietnameseDecimal(v);

String _typeLabel(String type) => switch (type) {
  'assign' || 'assignment' => 'Bài tập',
  'quiz' => 'Bài kiểm tra',
  'resource' => 'Tài liệu',
  'folder' => 'Thư mục',
  'forum' => 'Diễn đàn',
  'attendance' => 'Điểm danh',
  'page' => 'Trang',
  'url' => 'Liên kết',
  _ => 'Hoạt động',
};

/// Moodle attendance acronyms, in Vietnamese.
(String, Color) _statusStyle(AttendanceSession s) => switch (s.acronym) {
  'P' => ('Có mặt', Colors.green.shade700),
  'L' => ('Đi trễ', Colors.orange.shade800),
  'E' => ('Vắng có phép', Colors.blue.shade700),
  'A' => ('Vắng', Colors.red.shade700),
  _ => (s.statusDescription ?? 'Đã điểm danh', Colors.blueGrey),
};

/// What a tile opens: the number, one line on what it is made of, how it is computed,
/// and the rows behind it.
class _Detail {
  final String title, value;
  final IconData icon;
  final Color color;
  final String? summary;
  final String explanation;
  final List<Widget> rows;
  const _Detail({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.explanation,
    this.summary,
    this.rows = const [],
  });
}

/// The student's overview in one course: four compact numbers. Tapping one opens a sheet
/// with how it is computed and the activities, sessions or marks behind it.
class StudentOverviewDetails extends StatelessWidget {
  final MonitoredStudent student;
  const StudentOverviewDetails({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final s = student;
    final tiles = [
      (
        _progress(s),
        s.totalActivities != null && s.totalActivities! > 0
            ? '${s.completedActivities ?? 0}/${s.totalActivities} hoạt động'
            : null,
      ),
      (
        _attendance(s),
        s.markedSessions != null && s.markedSessions! > 0
            ? '${s.markedSessions} buổi đã điểm danh'
            : s.attendanceSessions.isNotEmpty
            ? 'Chưa được điểm danh'
            : null,
      ),
      (
        _grades(s),
        s.gradedItems != null && s.gradedItems! > 0
            ? '${s.gradedItems} bài đã chấm'
            : null,
      ),
      (
        _tasks(s),
        (s.overdue ?? 0) > 0
            ? '${s.overdue} bài quá hạn'
            : 'Không có bài quá hạn',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final w = (c.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final (d, hint) in tiles)
                  SizedBox(
                    width: w,
                    child: _Tile(
                      detail: d,
                      hint: hint,
                      onTap: () => _open(context, d),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        Text(
          s.inactiveDays == null
              ? 'Chưa ghi nhận lần vào khóa học nào trên Moodle'
              : 'Hoạt động gần nhất trên Moodle: ${daysAgoLabel(s.inactiveDays!)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  void _open(BuildContext context, _Detail d) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .8,
      minChildSize: .4,
      maxChildSize: .95,
      builder: (context, controller) =>
          _DetailSheet(detail: d, controller: controller),
    ),
  );
}

class _Tile extends StatelessWidget {
  final _Detail detail;
  final String? hint;
  final VoidCallback onTap;
  const _Tile({required this.detail, required this.hint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final number = RegExp(r'^\d').hasMatch(detail.value);
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.hairline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.title,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    // A real number stands out; "Chưa có dữ liệu" stays quiet.
                    Text(
                      detail.value,
                      style: number
                          ? Theme.of(context).textTheme.titleLarge
                          : Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                    ),
                    if (hint != null)
                      Text(
                        hint!,
                        style: TextStyle(fontSize: 11.5, color: context.muted),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: context.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  final _Detail detail;
  final ScrollController controller;
  const _DetailSheet({required this.detail, required this.controller});

  @override
  Widget build(BuildContext context) {
    final d = detail;
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 24),
      children: [
        Row(
          children: [
            Icon(d.icon, color: d.color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                d.title,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                d.value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (d.summary != null) ...[
                const SizedBox(height: 2),
                Text(
                  d.summary!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.tint(Colors.blueGrey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.calculate_outlined,
                      size: 18,
                      color: context.strong,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        d.explanation,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ...d.rows,
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle, trailing;
  final Color? trailingColor;
  const _Row({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.trailing,
    this.trailingColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13.5)),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 12, color: context.muted),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            // Wraps instead of pushing past the edge on narrow screens or large text.
            Flexible(
              flex: 2,
              child: Text(
                trailing!,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: trailingColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  final String text;
  const _GroupTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 2),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    ),
  );
}

// ------------------------------------------------------------ progress

_Detail _progress(MonitoredStudent s) {
  final items = s.progressItems;
  final done = items.where((i) => i.completed).toList();
  final todo = items.where((i) => !i.completed).toList();
  final total = s.totalActivities ?? items.length;
  final completed = s.completedActivities ?? done.length;
  final now = DateTime.now();
  return _Detail(
    title: 'Tiến độ',
    icon: Icons.trending_up,
    color: Colors.green.shade700,
    value: formatPercentageVi(s.progress),
    summary: total > 0 ? 'Đã hoàn thành $completed/$total hoạt động' : null,
    explanation: total > 0
        ? 'Tiến độ = số hoạt động đã hoàn thành ÷ số hoạt động giảng viên bật "theo dõi hoàn thành" trên Moodle '
              '($completed ÷ $total). Hoạt động có thể là bài tập, bài kiểm tra, tài liệu cần xem…'
        : 'Khóa học chưa có hoạt động nào bật theo dõi hoàn thành trên Moodle nên chưa tính được tiến độ.',
    rows: [
      if (todo.isNotEmpty) _GroupTitle('Chưa hoàn thành (${todo.length})'),
      for (final i in todo)
        _Row(
          icon: Icons.radio_button_unchecked,
          color: i.due != null && i.due!.isBefore(now)
              ? Colors.red.shade700
              : Colors.grey,
          title: DemoDisplayNames.activity(i.name),
          subtitle: [
            _typeLabel(i.type),
            if (i.section != null) i.section!,
            if (i.due != null)
              '${i.due!.isBefore(now) ? 'Đã quá hạn' : 'Hạn'} ${_dateTime(i.due!)}',
          ].join(' · '),
        ),
      if (done.isNotEmpty) _GroupTitle('Đã hoàn thành (${done.length})'),
      for (final i in done)
        _Row(
          icon: Icons.check_circle,
          color: Colors.green.shade600,
          title: DemoDisplayNames.activity(i.name),
          subtitle: [
            _typeLabel(i.type),
            if (i.completedAt != null) 'Hoàn thành ${_date(i.completedAt!)}',
          ].join(' · '),
        ),
    ],
  );
}

// ------------------------------------------------------------ attendance

_Detail _attendance(MonitoredStudent s) {
  final sessions = s.attendanceSessions;
  final marked = sessions.where((x) => x.marked).toList();
  final now = DateTime.now();
  final notYet = sessions
      .where((x) => !x.marked && x.date != null && x.date!.isAfter(now))
      .length;
  final unmarked = sessions.length - marked.length - notYet;
  int countOf(String a) => marked.where((x) => x.acronym == a).length;
  final maxGrade = sessions
      .map((x) => x.maxGrade)
      .whereType<double>()
      .fold<double?>(null, (m, g) => m == null || g > m ? g : m);
  // How many points each status is worth, as set in this course's attendance.
  final points = <String, double>{
    for (final x in marked)
      if (x.statusGrade != null) _statusStyle(x).$1: x.statusGrade!,
  };
  final counts = [
    'Có mặt ${countOf('P')}',
    if (countOf('L') > 0) 'Đi trễ ${countOf('L')}',
    if (countOf('E') > 0) 'Vắng có phép ${countOf('E')}',
    'Vắng ${countOf('A')}',
  ].join(' · ');

  return _Detail(
    title: 'Chuyên cần',
    icon: Icons.event_available,
    color: Colors.teal.shade700,
    value: formatPercentageVi(s.attendance),
    summary: marked.isEmpty
        ? null
        : '$counts / ${marked.length} buổi đã điểm danh'
              '${unmarked > 0 ? ' · $unmarked buổi chưa điểm danh' : ''}'
              '${notYet > 0 ? ' · $notYet buổi chưa diễn ra' : ''}',
    explanation: sessions.isEmpty
        ? 'Khóa học chưa có buổi điểm danh nào trên Moodle.'
        : marked.isEmpty
        ? 'Khóa học có ${sessions.length} buổi điểm danh nhưng sinh viên chưa được điểm danh buổi nào, '
              'nên chưa tính được chuyên cần.'
        : 'Chuyên cần = tổng điểm các buổi ÷ (số buổi đã điểm danh × ${maxGrade != null ? _num(maxGrade) : 'điểm tối đa'}). '
              '${points.isEmpty ? '' : 'Mỗi buổi: ${points.entries.map((e) => '${e.key} ${_num(e.value)} điểm').join(', ')}. '}'
              'Buổi chưa điểm danh không tính.',
    rows: [
      if (sessions.isNotEmpty) _GroupTitle('Các buổi học (${sessions.length})'),
      for (final x in sessions)
        Builder(
          builder: (_) {
            final future = !x.marked && x.date != null && x.date!.isAfter(now);
            final (label, color) = x.marked
                ? _statusStyle(x)
                : (future ? 'Chưa diễn ra' : 'Chưa điểm danh', Colors.grey);
            return _Row(
              icon: x.marked ? Icons.event_available : Icons.event_outlined,
              color: color,
              title: x.date != null ? _dateTime(x.date!) : 'Buổi học',
              subtitle: [
                if (x.description != null) x.description!,
                if (x.durationMinutes > 0) '${x.durationMinutes} phút',
                if (x.remarks != null) 'Ghi chú: ${x.remarks}',
              ].join(' · '),
              trailing: label,
              trailingColor: color,
            );
          },
        ),
    ],
  );
}

// ------------------------------------------------------------ grades

_Detail _grades(MonitoredStudent s) {
  final graded = s.gradeItems.where((g) => g.graded).toList();
  final ungraded = s.gradeItems.where((g) => !g.graded).toList();
  final passed = graded.where((g) => g.passed == true).length;
  final failed = graded.where((g) => g.passed == false).length;
  return _Detail(
    title: 'Điểm TB',
    icon: Icons.grade_outlined,
    color: Colors.purple,
    value: s.averageGrade == null
        ? 'Chưa có điểm'
        : formatPercentageVi(s.averageGrade),
    summary: graded.isEmpty
        ? null
        : 'Tính trên ${graded.length} bài đã chấm · Đạt $passed${failed > 0 ? ' · Chưa đạt $failed' : ''}',
    explanation: graded.isEmpty
        ? 'Chưa có bài nào được chấm trong sổ điểm Moodle.'
        : 'Điểm mỗi bài = điểm đạt ÷ điểm tối đa, quy ra %. Điểm TB là trung bình cộng các bài đã chấm; '
              'bài chưa chấm không tính.',
    rows: [
      if (graded.isNotEmpty) _GroupTitle('Đã chấm (${graded.length})'),
      for (final g in graded)
        _Row(
          icon: g.passed == false
              ? Icons.cancel_outlined
              : Icons.check_circle_outline,
          color: g.passed == false
              ? Colors.red.shade700
              : Colors.green.shade700,
          title: DemoDisplayNames.activity(g.name),
          subtitle: [
            _typeLabel(g.type),
            if (g.finalGrade != null && g.gradeMax != null)
              '${_num(g.finalGrade!)}/${_num(g.gradeMax!)} điểm',
            if (g.gradePass != null && g.gradePass! > 0)
              'cần ${_num(g.gradePass!)} để đạt',
          ].join(' · '),
          trailing:
              '${g.percentage != null ? formatPercentageVi(g.percentage) : ''}'
              '${g.passed == null
                  ? ''
                  : g.passed!
                  ? ' · Đạt'
                  : ' · Chưa đạt'}',
          trailingColor: g.passed == false
              ? Colors.red.shade700
              : Colors.green.shade800,
        ),
      if (ungraded.isNotEmpty) _GroupTitle('Chưa chấm (${ungraded.length})'),
      for (final g in ungraded)
        _Row(
          icon: Icons.hourglass_empty,
          color: Colors.grey,
          title: DemoDisplayNames.activity(g.name),
          subtitle: _typeLabel(g.type),
          trailing: 'Chưa chấm',
          trailingColor: Colors.grey,
        ),
    ],
  );
}

// ------------------------------------------------------------ assignments / quizzes

_Detail _tasks(MonitoredStudent s) {
  final now = DateTime.now();
  final open = s.tasks.where((t) => t.taskStatus != 'completed').toList()
    ..sort((a, b) => (a.dueTime ?? 1 << 40).compareTo(b.dueTime ?? 1 << 40));
  bool late(StudentTask t) => t.taskStatus == 'overdue';
  final overdue = open.where(late).toList(),
      pending = open.where((t) => !late(t)).toList();
  Widget row(StudentTask t) {
    final due = t.dueTime != null && t.dueTime! > 0
        ? DateTime.fromMillisecondsSinceEpoch(t.dueTime! * 1000)
        : null;
    return _Row(
      icon: late(t) ? Icons.error_outline : Icons.schedule,
      color: late(t) ? Colors.red.shade700 : Colors.orange.shade800,
      title: DemoDisplayNames.activity(t.title),
      subtitle: [
        _typeLabel(t.type),
        if (due != null)
          '${due.isBefore(now) ? 'Hạn đã qua' : 'Hạn'} ${_dateTime(due)}',
      ].join(' · '),
      trailing: late(t) ? 'Quá hạn' : 'Còn hạn',
      trailingColor: late(t) ? Colors.red.shade700 : Colors.orange.shade800,
    );
  }

  return _Detail(
    title: 'Bài chưa hoàn thành',
    icon: Icons.assignment_late_outlined,
    color: (s.overdue ?? 0) > 0 ? Colors.red.shade700 : Colors.orange.shade800,
    value: '${s.pending ?? open.length}',
    summary: (s.overdue ?? 0) > 0
        ? 'Trong đó ${s.overdue} bài đã quá hạn'
        : 'Không có bài quá hạn',
    explanation:
        'Đếm các bài tập chưa nộp và bài kiểm tra chưa làm xong trên Moodle, '
        'gồm cả bài còn hạn và bài đã quá hạn.',
    rows: [
      if (overdue.isNotEmpty) _GroupTitle('Quá hạn (${overdue.length})'),
      ...overdue.map(row),
      if (pending.isNotEmpty) _GroupTitle('Còn hạn (${pending.length})'),
      ...pending.map(row),
    ],
  );
}
