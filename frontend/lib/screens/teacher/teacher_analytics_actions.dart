import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';

import '../../core/display_text.dart';
import '../../models/class_insights.dart';
import '../../widgets/moodle_button.dart';
import 'teacher_analytics_sections.dart';
import 'teacher_analytics_widgets.dart';

String _dm(DateTime d) => '${d.day}/${d.month}';
String _hm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

// ============================================================ This week's to-do list

/// What to do this week, worked out from the class data, each with the button that does it.
class ActionItemsCard extends StatelessWidget {
  final List<ActionItem> items;
  final List<InsightStudent> students;
  final bool viewTracking;
  final StudentAction? onDetail, onNote;
  const ActionItemsCard({
    super.key,
    required this.items,
    required this.students,
    this.viewTracking = false,
    this.onDetail,
    this.onNote,
  });

  @override
  Widget build(BuildContext context) {
    return InsightCard(
      icon: Icons.checklist_rtl,
      color: Colors.deepPurple,
      title: 'Việc cần làm tuần này',
      description:
          'Những việc nên làm trước, sắp theo mức độ gấp. Dữ liệu cập nhật mỗi lần mở tab.',
      howCalculated: const [
        'Nhắc nộp bài: bài hết hạn trong 3 ngày tới, hoặc đã quá hạn trong 14 ngày qua, mà còn sinh viên chưa nộp.',
        'Liên hệ sinh viên ngừng học: không vào khóa học từ 2 tuần trở lên và chưa được ghi chú '
            'hay nhắc nhở trong 14 ngày qua.',
        'Liên hệ lại: đã được hỗ trợ hơn 7 ngày nhưng chưa có hoạt động nào trên Moodle.',
        'Hỗ trợ nhóm Cần hỗ trợ: sinh viên từ 60 điểm theo dõi chưa được liên hệ trong 14 ngày qua.',
        'Xem lại bài: bài đã quá hạn có từ 30% lượt nộp trễ hoặc từ 50% sinh viên chưa nộp.',
      ],
      children: [
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.tint(Colors.green),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.task_alt, color: Colors.green.shade700),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Tuần này chưa có việc cần làm gấp. Lớp đang ổn.',
                  ),
                ),
              ],
            ),
          )
        else
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 20),
            _ActionTile(
              index: i + 1,
              item: items[i],
              students: students,
              viewTracking: viewTracking,
              onDetail: onDetail,
              onNote: onNote,
            ),
          ],
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final int index;
  final ActionItem item;
  final List<InsightStudent> students;
  final bool viewTracking;
  final StudentAction? onDetail, onNote;
  const _ActionTile({
    required this.index,
    required this.item,
    required this.students,
    required this.viewTracking,
    this.onDetail,
    this.onNote,
  });

  List<InsightStudent> get _who => [
    for (final id in item.studentIds)
      ?students.where((s) => s.id == id).firstOrNull,
  ];

  @override
  Widget build(BuildContext context) {
    final n = item.studentIds.length;
    final a = item.activity;
    final name = a == null ? '' : DemoDisplayNames.activity(a.title);
    final (icon, color) = switch (item.action) {
      ActionKind.remind => (
        Icons.notifications_active_outlined,
        Colors.orange.shade800,
      ),
      ActionKind.contact => (Icons.phone_in_talk_outlined, Colors.red.shade700),
      ActionKind.review => (Icons.rate_review_outlined, Colors.indigo),
    };
    final (title, reason) = switch (item.code) {
      'DEADLINE_SOON' => (
        'Nhắc $n sinh viên chưa nộp "$name"',
        'Còn ${item.days} ngày đến hạn${a?.due != null ? ' (${_hm(a!.due!)} ${_dm(a.due!)})' : ''}. '
            'Nhắc trước hạn giúp sinh viên kịp hoàn thành.',
      ),
      'RECENTLY_OVERDUE' => (
        'Nhắc $n sinh viên chưa nộp "$name"',
        'Đã quá hạn ${item.days} ngày${a?.due != null ? ' (hạn ${_dm(a!.due!)})' : ''}.',
      ),
      'STOPPED_LEARNING' => (
        'Liên hệ $n sinh viên đã ngừng vào học',
        'Không vào khóa học từ 2 tuần trở lên và chưa được liên hệ trong 14 ngày qua.',
      ),
      'NO_CHANGE_AFTER_SUPPORT' => (
        'Liên hệ lại $n sinh viên chưa quay lại học',
        'Đã được hỗ trợ hơn 7 ngày nhưng chưa có hoạt động nào; nên thử cách liên hệ khác.',
      ),
      'NEEDS_SUPPORT_UNCONTACTED' => (
        'Hỗ trợ $n sinh viên nhóm Cần hỗ trợ',
        'Chưa được ghi chú hay nhắc nhở trong 14 ngày qua.',
      ),
      'REVIEW_ACTIVITY' => (
        'Xem lại bài "$name"',
        '${item.lateRate?.round() ?? 0}% lượt nộp trễ, ${item.missingRate?.round() ?? 0}% sinh viên chưa nộp sau hạn. '
            'Có thể đề khó hoặc thời hạn chưa phù hợp.',
      ),
      _ => ('Việc cần làm', ''),
    };
    final remind = ReminderScope.maybeOf(context);
    final who = _who;

    void openList() => showStudentListSheet(
      context,
      title: title,
      description: reason,
      color: color,
      students: who,
      onDetail: onDetail,
      onNote: onNote,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$index. $title',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (reason.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  reason,
                  style: TextStyle(fontSize: 12.5, color: context.muted),
                ),
              ],
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (item.action == ActionKind.remind &&
                      remind != null &&
                      who.isNotEmpty)
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.send, size: 16),
                      label: Text('Nhắc $n sinh viên'),
                      onPressed: () => remind(
                        who,
                        a == null
                            ? ReminderDraft.general
                            : ReminderDraft.forActivity(
                                title: name,
                                type: a.type,
                                sourceId: a.sourceId,
                                due: a.due,
                              ),
                      ),
                    ),
                  if (a != null && item.action != ActionKind.contact)
                    OutlinedButton(
                      onPressed: () => showActivitySubmissionsSheet(
                        context,
                        activity: ActivityRef.action(
                          a,
                          viewTracking: viewTracking,
                        ),
                        students: students,
                        onDetail: onDetail,
                      ),
                      child: const Text('Xem tình trạng nộp'),
                    ),
                  if (item.action == ActionKind.contact && who.isNotEmpty)
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.people_alt_outlined, size: 16),
                      label: Text('Xem $n sinh viên'),
                      onPressed: openList,
                    ),
                  if (item.action == ActionKind.review && a != null)
                    MoodleButton(
                      path: a.moodlePath,
                      courseModuleId: a.courseModuleId,
                      compact: true,
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

// ============================================================ Week-over-week change

/// The class now versus 7 days ago, with who moved between groups.
class WeeklyChangeCard extends StatelessWidget {
  final WeeklyChange change;
  final List<InsightStudent> students;
  final StudentAction? onDetail, onNote;
  const WeeklyChangeCard({
    super.key,
    required this.change,
    required this.students,
    this.onDetail,
    this.onNote,
  });

  @override
  Widget build(BuildContext context) {
    final c = change;
    final worse = c.worsened.length, better = c.improved.length;
    final moved = [
      if (worse > 0) '$worse sinh viên chuyển sang nhóm cần chú ý hơn',
      if (better > 0) '$better sinh viên đã tiến bộ',
    ];
    final takeaway = moved.isEmpty
        ? 'Không có sinh viên nào đổi nhóm so với tuần trước.'
        : '${moved.join(', ')}.';

    List<InsightStudent> pick(List<GroupMove> moves) => [
      for (final m in moves) ?students.where((s) => s.id == m.id).firstOrNull,
    ];

    return InsightCard(
      icon: Icons.compare_arrows,
      color: context.strong,
      title: 'Thay đổi so với tuần trước',
      description: c.asOf != null
          ? 'So sánh lớp hôm nay với 7 ngày trước (${_dm(c.asOf!)}).'
          : 'So sánh lớp hôm nay với 7 ngày trước.',
      takeaway: takeaway,
      howCalculated: const [
        'Số liệu 7 ngày trước được tính lại từ lịch sử trên Moodle: lần truy cập cuối, bài đã quá hạn '
            'mà chưa nộp vào lúc đó, hoạt động đã hoàn thành vào lúc đó, số lượt hoạt động trong 7 ngày trước đó.',
        'Dùng cùng quy tắc chấm điểm theo dõi như hiện tại, nên hai mốc so sánh được với nhau.',
        'Đây là ước tính: nếu giảng viên thêm hoặc bớt hoạt động trong tuần, tiến độ cũ có thể lệch đôi chút.',
      ],
      children: [
        _DeltaRow(
          'Cần hỗ trợ',
          c.before[WatchGroup.needsSupport]!,
          c.now[WatchGroup.needsSupport]!,
          higherIsBetter: false,
        ),
        _DeltaRow(
          'Cần theo dõi',
          c.before[WatchGroup.watch]!,
          c.now[WatchGroup.watch]!,
          higherIsBetter: false,
        ),
        _DeltaRow(
          'Đúng tiến độ',
          c.before[WatchGroup.onTrack]!,
          c.now[WatchGroup.onTrack]!,
          higherIsBetter: true,
        ),
        _DeltaRow(
          'Sinh viên có bài quá hạn',
          c.overdueBefore,
          c.overdueNow,
          higherIsBetter: false,
        ),
        if (c.progressBefore != null && c.progressNow != null)
          _DeltaRow.percent(
            'Tiến độ trung bình',
            c.progressBefore!,
            c.progressNow!,
          ),
        if (worse > 0) ...[
          const SizedBox(height: 12),
          _MovesBox(
            title: 'Cần chú ý hơn tuần trước',
            color: Colors.red.shade700,
            moves: c.worsened,
            onOpen: () => showStudentListSheet(
              context,
              title: 'Cần chú ý hơn tuần trước',
              description:
                  'Sinh viên đã chuyển sang nhóm cần chú ý hơn so với 7 ngày trước.',
              color: Colors.red.shade700,
              students: pick(c.worsened),
              onDetail: onDetail,
              onNote: onNote,
            ),
          ),
        ],
        if (better > 0) ...[
          const SizedBox(height: 8),
          _MovesBox(
            title: 'Đã tiến bộ',
            color: Colors.green.shade700,
            moves: c.improved,
            onOpen: () => showStudentListSheet(
              context,
              title: 'Đã tiến bộ',
              description:
                  'Sinh viên đã chuyển sang nhóm tốt hơn so với 7 ngày trước.',
              color: Colors.green.shade700,
              students: pick(c.improved),
              onDetail: onDetail,
              onNote: onNote,
            ),
          ),
        ],
      ],
    );
  }
}

/// "▲ 2" in red when more is worse, green when more is better; "Không đổi" otherwise.
class DeltaBadge extends StatelessWidget {
  final double delta;
  final bool higherIsBetter;
  final String unit;
  const DeltaBadge(
    this.delta, {
    super.key,
    required this.higherIsBetter,
    this.unit = '',
  });

  @override
  Widget build(BuildContext context) {
    if (delta.abs() < 0.05) {
      return Text(
        'Không đổi',
        style: TextStyle(fontSize: 12, color: context.muted),
      );
    }
    final up = delta > 0;
    final good = up == higherIsBetter;
    final color = good ? Colors.green.shade700 : Colors.red.shade700;
    final value = delta.abs() == delta.abs().roundToDouble()
        ? delta.abs().toStringAsFixed(0)
        : delta.abs().toStringAsFixed(1);
    return Text(
      '${up ? '▲' : '▼'} $value$unit',
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }
}

class _DeltaRow extends StatelessWidget {
  final String label, before, now;
  final double delta;
  final bool higherIsBetter;
  final String unit;

  _DeltaRow(this.label, int before, int now, {required this.higherIsBetter})
    : before = '$before',
      now = '$now',
      delta = (now - before).toDouble(),
      unit = '';

  _DeltaRow.percent(this.label, double before, double now)
    : before = '${before.toStringAsFixed(1)}%',
      now = '${now.toStringAsFixed(1)}%',
      delta = now - before,
      higherIsBetter = true,
      unit = '%';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13.5))),
          const SizedBox(width: 8),
          // Wraps under itself on narrow screens or with large text instead of overflowing.
          Flexible(
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$before → ',
                        style: TextStyle(fontSize: 13, color: context.muted),
                      ),
                      TextSpan(
                        text: now,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                DeltaBadge(delta, higherIsBetter: higherIsBetter, unit: unit),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MovesBox extends StatelessWidget {
  final String title;
  final Color color;
  final List<GroupMove> moves;
  final VoidCallback onOpen;
  const _MovesBox({
    required this.title,
    required this.color,
    required this.moves,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    const shown = 4;
    return Material(
      color: color.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$title · ${moves.length} sinh viên',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: context.muted),
                ],
              ),
              for (final m in moves.take(shown))
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    '${m.name}: ${m.from.label} → ${m.to.label}',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              if (moves.length > shown)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    'và ${moves.length - shown} sinh viên khác',
                    style: TextStyle(fontSize: 12, color: context.muted),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
