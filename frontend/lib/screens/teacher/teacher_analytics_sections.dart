import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';

import '../../core/display_text.dart';
import '../../models/class_insights.dart';
import 'teacher_analytics_widgets.dart';

// ============================================================ A. Progress × grade quadrants

/// One kind of difficulty, each needing a different kind of help.
class _Quadrant {
  final String title, advice;
  final Color color;
  final bool highProgress, highGrade;
  const _Quadrant(
    this.title,
    this.advice,
    this.color,
    this.highProgress,
    this.highGrade,
  );

  bool contains(InsightStudent s) =>
      (s.progress! >= _cut) == highProgress &&
      (s.averageGrade! >= _cut) == highGrade;
}

const double _cut = 50;

/// Fewer graded items than this and one lucky (or unlucky) mark would decide the quadrant.
const int _minGradedItems = 2;

// Titles state only what the data shows; any interpretation lives in the advice line.
const _quadrants = [
  _Quadrant(
    'Điểm khá, làm ít hoạt động',
    'Có thể đã nắm bài nhưng chưa hoàn thành các hoạt động; nên nhắc hoàn thành.',
    Color(0xFF1E88E5),
    false,
    true,
  ),
  _Quadrant(
    'Làm nhiều, điểm khá',
    'Đang học ổn; có thể giao thêm bài nâng cao.',
    Color(0xFF43A047),
    true,
    true,
  ),
  _Quadrant(
    'Làm ít, điểm thấp',
    'Nên liên hệ sớm để tìm hiểu khó khăn.',
    Color(0xFFE53935),
    false,
    false,
  ),
  _Quadrant(
    'Làm nhiều, điểm thấp',
    'Đã cố gắng nhưng kết quả chưa tốt; nên hỗ trợ kiến thức, giải thích lại, gợi ý tài liệu ôn.',
    Color(0xFFFB8C00),
    true,
    false,
  ),
];

/// Where each student sits on effort (progress) versus result (grade).
class ProgressGradeQuadrants extends StatelessWidget {
  final List<InsightStudent> students;
  final StudentAction? onDetail, onNote;
  const ProgressGradeQuadrants({
    super.key,
    required this.students,
    this.onDetail,
    this.onNote,
  });

  /// Placed on the chart only with a progress value and enough graded items.
  static bool isPlottable(InsightStudent s) =>
      s.progress != null &&
      s.averageGrade != null &&
      s.gradedItems >= _minGradedItems;

  @override
  Widget build(BuildContext context) {
    final plotted = students.where(isPlottable).toList();
    if (plotted.isEmpty) return const SizedBox.shrink();
    final ungraded = students.length - plotted.length;
    final counts = [
      for (final q in _quadrants) plotted.where(q.contains).length,
    ];

    void open(int i) {
      final q = _quadrants[i];
      showStudentListSheet(
        context,
        title: q.title,
        description:
            'Tiến độ ${q.highProgress ? 'từ' : 'dưới'} 50% và điểm TB ${q.highGrade ? 'từ' : 'dưới'} 50% '
            '(tính trên các bài đã được chấm). Gợi ý: ${q.advice}',
        color: q.color,
        students: plotted.where(q.contains).toList()
          ..sort(
            (a, b) => (a.averageGrade! + a.progress!).compareTo(
              b.averageGrade! + b.progress!,
            ),
          ),
        onDetail: onDetail,
        onNote: onNote,
      );
    }

    // The most crowded quadrant other than "Làm nhiều, điểm khá" is the takeaway.
    var worst = -1;
    for (final i in [2, 3, 0]) {
      if (counts[i] > 0 && (worst < 0 || counts[i] > counts[worst])) worst = i;
    }
    final takeaway = worst < 0
        ? 'Tất cả ${plotted.length} sinh viên trên biểu đồ đều làm nhiều hoạt động và có điểm khá.'
        : 'Ô đông nhất cần chú ý là "${_quadrants[worst].title}" với ${counts[worst]} sinh viên '
              '(${percentOf(counts[worst], plotted.length)}). ${_quadrants[worst].advice}';

    return InsightCard(
      icon: Icons.scatter_plot_outlined,
      color: Colors.blue.shade700,
      title: 'Tiến độ và điểm số của sinh viên',
      description:
          'Mỗi chấm là một sinh viên, xếp tự động từ dữ liệu Moodle, sinh viên không phải '
          'tự nhập gì. Mỗi ô cần một cách hỗ trợ khác nhau.',
      takeaway: takeaway,
      hint: 'Nhấn vào một ô để xem tên sinh viên và gợi ý hỗ trợ.',
      howCalculated: const [
        'Trục ngang (tiến độ) = số hoạt động đã hoàn thành ÷ số hoạt động có theo dõi hoàn thành trên Moodle.',
        'Trục dọc (điểm TB) = trung bình (điểm đạt ÷ điểm tối đa) của các bài đã được chấm trong sổ điểm Moodle.',
        'Hai đường chia ở mức 50%.',
        'Ví dụ: hoàn thành 4/20 hoạt động (20%), 2 bài được chấm 8/10 và 7/10 (75%) '
            '→ nằm ở ô "Điểm khá, làm ít hoạt động".',
        'Chỉ xếp sinh viên đã có ít nhất $_minGradedItems bài được chấm, để 1 bài điểm cao hoặc thấp '
            'không quyết định cả vị trí.',
        'Tên ô chỉ mô tả số liệu; dòng gợi ý trong mỗi ô là cách hỗ trợ nên cân nhắc, '
            'không phải kết luận về năng lực sinh viên.',
      ],
      children: [
        _QuadrantPlot(students: plotted, onTap: open),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) {
            final w = (c.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _quadrants.length; i++)
                  SizedBox(
                    width: w,
                    child: _QuadrantCard(
                      quadrant: _quadrants[i],
                      count: counts[i],
                      total: plotted.length,
                      onTap: counts[i] > 0 ? () => open(i) : null,
                    ),
                  ),
              ],
            );
          },
        ),
        if (ungraded > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '$ungraded sinh viên chưa đủ dữ liệu điểm (dưới $_minGradedItems bài được chấm) '
              'nên chưa hiển thị trên biểu đồ.',
              style: TextStyle(fontSize: 12, color: context.muted),
            ),
          ),
      ],
    );
  }
}

/// Students whose dots would overlap on screen, drawn as one numbered dot.
class _DotCluster {
  final double x, y;
  final int quadrant;
  final List<InsightStudent> members;
  _DotCluster(this.x, this.y, this.quadrant, this.members);

  /// The most urgent group among the members decides the colour.
  WatchGroup get color => members
      .map((s) => s.group)
      .reduce((a, b) => _urgency.indexOf(a) <= _urgency.indexOf(b) ? a : b);

  static const _urgency = [
    WatchGroup.needsSupport,
    WatchGroup.watch,
    WatchGroup.onTrack,
    WatchGroup.unknown,
  ];
}

/// Groups dots whose centres are closer than one dot width. Only dots in the same
/// quadrant are merged, so the numbers on the chart always add up to the quadrant cards.
List<_DotCluster> _clusterDots(
  List<InsightStudent> students,
  double w,
  double h,
  double dot,
) {
  final out = <_DotCluster>[];
  for (final s in students) {
    final x = dot / 2 + (s.progress!.clamp(0, 100) / 100) * (w - dot);
    final y = dot / 2 + (1 - s.averageGrade!.clamp(0, 100) / 100) * (h - dot);
    final q = _quadrants.indexWhere((q) => q.contains(s));
    final near = out
        .where(
          (c) =>
              c.quadrant == q && (c.x - x).abs() < dot && (c.y - y).abs() < dot,
        )
        .firstOrNull;
    if (near != null) {
      near.members.add(s);
    } else {
      out.add(_DotCluster(x, y, q, [s]));
    }
  }
  return out;
}

class _QuadrantPlot extends StatelessWidget {
  final List<InsightStudent> students;
  final void Function(int quadrant) onTap;
  const _QuadrantPlot({required this.students, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final axis = TextStyle(fontSize: 10, color: context.muted);
    Widget cell(int i) {
      final q = _quadrants[i];
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(i),
          child: Container(
            margin: const EdgeInsets.all(1),
            padding: const EdgeInsets.all(4),
            color: q.color.withValues(alpha: .10),
            alignment: q.highProgress ? Alignment.topRight : Alignment.topLeft,
            child: Text(
              q.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: q.highProgress ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: q.color,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('↑ Điểm TB (%)', style: axis),
        const SizedBox(height: 2),
        SizedBox(
          height: 220,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 24,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('100', style: axis),
                    Text('50', style: axis),
                    Text('0', style: axis),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    const dot = 12.0, cluster = 20.0;
                    final groups = _clusterDots(
                      students,
                      c.maxWidth,
                      c.maxHeight,
                      dot,
                    );
                    return Stack(
                      children: [
                        Column(
                          children: [
                            Expanded(child: Row(children: [cell(0), cell(1)])),
                            Expanded(child: Row(children: [cell(2), cell(3)])),
                          ],
                        ),
                        for (final g in groups)
                          Builder(
                            builder: (_) {
                              final size = g.members.length > 1 ? cluster : dot;
                              return Positioned(
                                left: (g.x - size / 2).clamp(
                                  0,
                                  c.maxWidth - size,
                                ),
                                top: (g.y - size / 2).clamp(
                                  0,
                                  c.maxHeight - size,
                                ),
                                child: IgnorePointer(
                                  child: Container(
                                    width: size,
                                    height: size,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: watchGroupColor(g.color),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: g.members.length > 1
                                        ? Text(
                                            '${g.members.length}',
                                            textScaler: TextScaler.noScaling,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 24, top: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0', style: axis),
              Text('50', style: axis),
              Text('100', style: axis),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text('Tiến độ (%) →', style: axis),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (final g in [
              WatchGroup.needsSupport,
              WatchGroup.watch,
              WatchGroup.onTrack,
            ])
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 10, color: watchGroupColor(g)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Chấm: ${g.label}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.muted,
                  ),
                  child: const Text(
                    '2',
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Flexible(
                  child: Text(
                    'Chấm có số: nhiều sinh viên ở gần cùng vị trí',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _QuadrantCard extends StatelessWidget {
  final _Quadrant quadrant;
  final int count, total;
  final VoidCallback? onTap;
  const _QuadrantCard({
    required this.quadrant,
    required this.count,
    required this.total,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: quadrant.color.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quadrant.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: quadrant.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count SV (${percentOf(count, total)})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                quadrant.advice,
                style: TextStyle(fontSize: 11.5, color: context.strong),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================ B. Who stopped, and since when

String _dm(DateTime d) => '${d.day}/${d.month}';

class ActivityHeatmapSection extends StatefulWidget {
  final ActivityHeatmap heatmap;
  final List<InsightStudent> students;
  final StudentAction? onDetail, onNote;
  const ActivityHeatmapSection({
    super.key,
    required this.heatmap,
    required this.students,
    this.onDetail,
    this.onNote,
  });

  @override
  State<ActivityHeatmapSection> createState() => _ActivityHeatmapSectionState();
}

class _ActivityHeatmapSectionState extends State<ActivityHeatmapSection> {
  static const _collapsedRows = 8;
  bool _expanded = false;

  InsightStudent? _student(int id) =>
      widget.students.where((s) => s.id == id).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final h = widget.heatmap;
    if (h.rows.isEmpty || h.weeks.isEmpty) return const SizedBox.shrink();
    final primary = Theme.of(context).colorScheme.primary;
    final flagged = h.rows.where((r) => r.status != HeatStatus.active).length;
    // Collapsed: every flagged student, and at least a few rows for comparison.
    final shownCount = _expanded
        ? h.rows.length
        : (flagged > _collapsedRows ? flagged : _collapsedRows).clamp(
            0,
            h.rows.length,
          );
    final shown = h.rows.take(shownCount).toList();
    final step = h.weeks.length > 8 ? 2 : 1;

    // V2-N15: 4 intensity levels (quarters of the class maximum), same rule as the API.
    Color levelColor(int level) => level == 0
        ? context.subtle
        : primary.withValues(alpha: const <double>[0, .25, .5, .75, 1][level]);
    Color cellColor(int events) => levelColor(heatLevel(events, h.maxEvents));

    final problems = [
      if (h.droppedCount > 0)
        '${h.droppedCount} sinh viên đã ngừng vào học ít nhất ${h.dropOffWeeks} tuần',
      if (h.neverActiveCount > 0)
        '${h.neverActiveCount} sinh viên chưa vào học lần nào trong ${h.weeks.length} tuần',
    ];
    final takeaway = problems.isEmpty
        ? 'Không có sinh viên nào ngừng vào học từ ${h.dropOffWeeks} tuần trở lên.'
        : '${problems.join('; ')}. Đây là những người nên liên hệ trước.';

    final flaggedStudents = [
      for (final r in h.rows)
        if (r.status != HeatStatus.active) ?_student(r.id),
    ];

    return InsightCard(
      icon: Icons.calendar_view_week_outlined,
      color: Colors.teal.shade700,
      title: 'Lịch sử vào học theo tuần',
      description:
          'Mỗi hàng là một sinh viên, mỗi ô là một tuần. Ô càng đậm là học càng nhiều, '
          'ô xám là tuần đó không vào học.',
      takeaway: takeaway,
      hint: 'Nhấn vào tên sinh viên để xem chi tiết.',
      howCalculated: [
        'Mỗi ô = số lượt thao tác của sinh viên trong khóa học trong tuần đó, theo nhật ký Moodle.',
        'Màu chia 4 mức theo phần tư của tuần nhiều nhất cả lớp (${h.maxEvents} lượt); ô xám = 0 lượt.',
        '"Ngừng từ ngày …": sinh viên từng vào học nhưng không có hoạt động nào ít nhất '
            '${h.dropOffWeeks} tuần gần đây; ngày ghi là tuần đầu tiên không vào học.',
        '"Chưa vào học": không có lượt thao tác nào trong ${h.weeks.length} tuần đang xem.',
        'Sinh viên ngừng học và chưa vào học được xếp lên đầu danh sách.',
      ],
      children: [
        // Week labels.
        Row(
          children: [
            const SizedBox(width: 112),
            for (var i = 0; i < h.weeks.length; i++)
              Expanded(
                child: i % step == 0
                    ? FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _dm(h.weeks[i]),
                          style: TextStyle(fontSize: 9, color: context.muted),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (final r in shown)
          InkWell(
            onTap: widget.onDetail != null && _student(r.id) != null
                ? () => widget.onDetail!(_student(r.id)!)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 112,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (r.status == HeatStatus.dropped &&
                            r.droppedSince != null)
                          Text(
                            'Ngừng từ ${_dm(r.droppedSince!)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Colors.red.shade700,
                            ),
                          )
                        else if (r.status == HeatStatus.neverActive)
                          Text(
                            'Chưa vào học',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: context.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  for (final e in r.events)
                    Expanded(
                      child: Tooltip(
                        message: '$e lượt',
                        child: Container(
                          height: 20,
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: cellColor(e),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (h.rows.length > shownCount || _expanded)
          Center(
            child: TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded
                    ? 'Thu gọn'
                    : 'Hiện tất cả ${h.rows.length} sinh viên',
              ),
            ),
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('Ít', style: TextStyle(fontSize: 11, color: context.muted)),
            const SizedBox(width: 4),
            for (var level = 0; level <= 4; level++)
              Container(
                width: 16,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: levelColor(level),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Nhiều lượt hoạt động',
                style: TextStyle(fontSize: 11, color: context.muted),
              ),
            ),
          ],
        ),
        if (flaggedStudents.isNotEmpty) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.person_search_outlined, size: 18),
            label: Text(
              'Xem ${flaggedStudents.length} sinh viên ngừng học / chưa vào học',
            ),
            onPressed: () => showStudentListSheet(
              context,
              title: 'Ngừng học hoặc chưa vào học',
              description:
                  'Không có hoạt động trên Moodle ít nhất ${h.dropOffWeeks} tuần gần đây, '
                  'hoặc chưa vào khóa học lần nào trong ${h.weeks.length} tuần.',
              color: Colors.red.shade600,
              students: flaggedStudents,
              onDetail: widget.onDetail,
              onNote: widget.onNote,
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================ C. Did support help?

class SupportFollowUpSection extends StatefulWidget {
  final SupportFollowUps followUps;
  final List<InsightStudent> students;
  final StudentAction? onDetail;
  const SupportFollowUpSection({
    super.key,
    required this.followUps,
    required this.students,
    this.onDetail,
  });

  @override
  State<SupportFollowUpSection> createState() => _SupportFollowUpSectionState();
}

class _SupportFollowUpSectionState extends State<SupportFollowUpSection> {
  static const _collapsed = 5;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final f = widget.followUps;
    final days = f.windowDays;
    final how = [
      'Mỗi lần bạn lưu ghi chú cho một sinh viên, hoặc gửi nhắc nhở bằng nút "Nhắc" trong app, '
          'được tính là một lần hỗ trợ.',
      'App đếm số lượt hoạt động trên Moodle của sinh viên trong $days ngày trước và $days ngày sau ghi chú.',
      '"Đã quay lại học": có ít nhất 1 hoạt động trong $days ngày sau. "Chưa thay đổi": đã qua $days ngày mà không có hoạt động.',
      'Kết quả cho thấy sự thay đổi sau khi hỗ trợ, không khẳng định thay đổi là do ghi chú.',
    ];

    if (f.total == 0) {
      return InsightCard(
        icon: Icons.volunteer_activism_outlined,
        color: Colors.green.shade700,
        title: 'Hiệu quả hỗ trợ sinh viên',
        description:
            'App tự đo xem sinh viên có quay lại học trên Moodle sau mỗi lần bạn hỗ trợ.',
        howCalculated: how,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.subtle,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.edit_note, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chưa có ghi chú hỗ trợ nào trong khóa học này.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Mở một sinh viên trong nhóm "Cần hỗ trợ", bấm "Ghi chú" để ghi lại lần bạn liên hệ. '
                  'Sau $days ngày, mục này sẽ cho biết sinh viên đó có quay lại học hay không.',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final evaluated = f.returned + f.noChange;
    final takeaway = evaluated == 0
        ? 'Các lần hỗ trợ đều chưa đủ $days ngày để đánh giá; ${f.returned} sinh viên đã quay lại học sớm.'
        : '${f.returned}/$evaluated lần hỗ trợ (${f.returnRate?.toStringAsFixed(0) ?? 0}%) có sinh viên quay lại học '
              'trong $days ngày'
              '${f.averageDaysToReturn != null ? ', trung bình sau ${f.averageDaysToReturn!.toStringAsFixed(1)} ngày' : ''}.'
              '${f.noChange > 0 ? ' ${f.noChange} trường hợp chưa thay đổi nên liên hệ lại bằng cách khác.' : ''}';
    final items = _expanded ? f.items : f.items.take(_collapsed).toList();

    return InsightCard(
      icon: Icons.volunteer_activism_outlined,
      color: Colors.green.shade700,
      title: 'Hiệu quả hỗ trợ sinh viên',
      description:
          'Hoạt động của sinh viên trên Moodle $days ngày trước và $days ngày sau mỗi lần bạn ghi chú hỗ trợ.',
      takeaway: takeaway,
      hint: 'Nhấn vào một lần hỗ trợ để xem chi tiết sinh viên.',
      howCalculated: how,
      children: [
        Row(
          children: [
            _OutcomeBox('Đã quay lại học', f.returned, Colors.green.shade600),
            const SizedBox(width: 6),
            _OutcomeBox('Chưa thay đổi', f.noChange, Colors.red.shade600),
            const SizedBox(width: 6),
            _OutcomeBox('Đang chờ đủ $days ngày', f.waiting, context.muted),
          ],
        ),
        if (f.averageBefore != null && f.averageAfter != null) ...[
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Lượt hoạt động TB: '),
                TextSpan(
                  text: '${f.averageBefore!.toStringAsFixed(1)} (trước)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: '  →  '),
                TextSpan(
                  text: '${f.averageAfter!.toStringAsFixed(1)} (sau)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: f.averageAfter! > f.averageBefore!
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ],
        const SizedBox(height: 12),
        for (final item in items)
          _FollowUpTile(item: item, days: days, onTap: _onTap(item)),
        if (f.items.length > _collapsed)
          Center(
            child: TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded
                    ? 'Thu gọn'
                    : 'Xem tất cả ${f.items.length} lần hỗ trợ',
              ),
            ),
          ),
      ],
    );
  }

  VoidCallback? _onTap(FollowUp item) {
    final s = widget.students.where((s) => s.id == item.studentId).firstOrNull;
    return s == null || widget.onDetail == null
        ? null
        : () => widget.onDetail!(s);
  }
}

class _OutcomeBox extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _OutcomeBox(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowUpTile extends StatelessWidget {
  final FollowUp item;
  final int days;
  final VoidCallback? onTap;
  const _FollowUpTile({required this.item, required this.days, this.onTap});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (item.outcome) {
      FollowUpOutcome.returned => (
        item.daysToReturn != null && item.daysToReturn! <= 0
            ? 'Quay lại ngay trong ngày'
            : 'Quay lại sau ${item.daysToReturn ?? '?'} ngày',
        Colors.green.shade700,
      ),
      FollowUpOutcome.noChange => (
        'Chưa quay lại sau $days ngày',
        Colors.red.shade700,
      ),
      FollowUpOutcome.waiting => (
        'Đang theo dõi (còn ${(days - item.daysSince).clamp(1, days)} ngày)',
        context.muted,
      ),
    };
    final at = item.notedAt;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (at != null)
                Text(
                  'Ghi chú ngày ${at.day}/${at.month}/${at.year}',
                  style: TextStyle(fontSize: 11.5, color: context.muted),
                ),
              if (item.note != null)
                Text(
                  '"${item.note}"',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: context.strong,
                  ),
                ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 10,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Hoạt động: ${item.eventsBefore} → ${item.eventsAfter} lượt',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
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

// ============================================================ Who handed in one activity

enum _Submission { notSubmitted, late, onTime }

(String, Color, IconData) _submissionStyle(_Submission s) => switch (s) {
  _Submission.onTime => (
    'Đã nộp đúng hạn',
    Colors.green.shade700,
    Icons.check_circle_outline,
  ),
  _Submission.late => ('Nộp trễ', Colors.orange.shade800, Icons.schedule),
  _Submission.notSubmitted => (
    'Chưa nộp',
    Colors.red.shade700,
    Icons.cancel_outlined,
  ),
};

String _dmy(DateTime d) => '${d.day}/${d.month}/${d.year}';
String _hm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// "3 ngày" or, under a day, "5 giờ".
String _span(Duration d) => d.inHours >= 24
    ? '${(d.inHours / 24).ceil()} ngày'
    : '${d.inHours < 1 ? 1 : d.inHours} giờ';

class _SubmissionRow {
  final InsightStudent student;
  final StudentTaskItem task;
  final _Submission kind;
  _SubmissionRow(this.student, this.task, this.kind);
}

/// The assignment/quiz a submissions sheet is about.
class ActivityRef {
  final String title, type;
  final int? sourceId;
  final DateTime? due;

  /// The course log records activity views, so "Đã mở đề" can be shown.
  final bool viewTracking;
  const ActivityRef({
    required this.title,
    required this.type,
    required this.sourceId,
    this.due,
    this.viewTracking = false,
  });

  ActivityRef.low(LowCompletionActivity a, {bool viewTracking = false})
    : this(
        title: a.title,
        type: a.type,
        sourceId: a.sourceId,
        due: a.due,
        viewTracking: viewTracking,
      );
  ActivityRef.action(ActionActivity a, {bool viewTracking = false})
    : this(
        title: a.title,
        type: a.type,
        sourceId: a.sourceId,
        due: a.due,
        viewTracking: viewTracking,
      );

  bool get duePassed => due != null && due!.isBefore(DateTime.now());
}

/// Every student of the class for one assignment/quiz: on time, late or not handed in.
Future<void> showActivitySubmissionsSheet(
  BuildContext context, {
  required ActivityRef activity,
  required List<InsightStudent> students,
  StudentAction? onDetail,
}) {
  final rows = <_SubmissionRow>[];
  final id = activity.sourceId;
  final remind = ReminderScope.maybeOf(context);
  if (id != null) {
    for (final s in students) {
      final t = s.tasks
          .where((t) => t.isActivity(activity.type, id))
          .firstOrNull;
      if (t == null) continue;
      final kind = t.state != TaskState.completed
          ? _Submission.notSubmitted
          : t.late
          ? _Submission.late
          : _Submission.onTime;
      rows.add(_SubmissionRow(s, t, kind));
    }
  }
  // Who still needs a nudge first, then late, then on time; by name within each.
  rows.sort((a, b) {
    final c = a.kind.index.compareTo(b.kind.index);
    return c != 0 ? c : a.student.name.compareTo(b.student.name);
  });
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
      builder: (_, controller) => _ActivitySheetBody(
        controller: controller,
        activity: activity,
        rows: rows,
        onRemind: remind == null
            ? null
            : (list) => remind(
                list,
                ReminderDraft.forActivity(
                  title: DemoDisplayNames.activity(activity.title),
                  type: activity.type,
                  sourceId: activity.sourceId,
                  due: activity.due,
                ),
              ),
        onDetail: onDetail == null
            ? null
            : (s) {
                Navigator.pop(sheetContext);
                onDetail(s);
              },
      ),
    ),
  );
}

class _ActivitySheetBody extends StatefulWidget {
  final ScrollController controller;
  final ActivityRef activity;
  final List<_SubmissionRow> rows;
  final StudentAction? onDetail;
  final Future<bool> Function(List<InsightStudent>)? onRemind;
  const _ActivitySheetBody({
    required this.controller,
    required this.activity,
    required this.rows,
    this.onDetail,
    this.onRemind,
  });

  @override
  State<_ActivitySheetBody> createState() => _ActivitySheetBodyState();
}

class _ActivitySheetBodyState extends State<_ActivitySheetBody> {
  _Submission? _filter;

  /// Index of a journey step: show the students who reached the step before it but not it.
  int? _stoppedAt;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final a = widget.activity;
    final count = {
      for (final k in _Submission.values)
        k: widget.rows.where((r) => r.kind == k).length,
    };
    final steps = _journeySteps(widget.rows, viewTracking: a.viewTracking);
    final q = _query.trim().toLowerCase();
    final shown = widget.rows
        .where((r) => _filter == null || r.kind == _filter)
        .where(
          (r) =>
              _stoppedAt == null ||
              (steps[_stoppedAt! - 1].test(r) && !steps[_stoppedAt!].test(r)),
        )
        .where(
          (r) =>
              q.isEmpty ||
              r.student.name.toLowerCase().contains(q) ||
              (r.student.code ?? '').toLowerCase().contains(q),
        )
        .toList();

    return ListView(
      controller: widget.controller,
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 8),
              child: Icon(
                a.type == 'quiz'
                    ? Icons.quiz_outlined
                    : Icons.assignment_outlined,
                color: context.muted,
              ),
            ),
            Expanded(
              child: Text(
                DemoDisplayNames.activity(a.title),
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
                [
                  a.type == 'quiz' ? 'Bài kiểm tra' : 'Bài tập',
                  if (a.due != null)
                    'Hạn nộp ${_hm(a.due!)} ${_dmy(a.due!)}'
                  else
                    'Không đặt hạn nộp',
                  if (a.duePassed) 'Đã quá hạn',
                ].join(' · '),
                style: TextStyle(fontSize: 13, color: context.muted),
              ),
              const SizedBox(height: 14),
              if (widget.rows.isEmpty)
                Text(
                  'Chưa có dữ liệu nộp bài của từng sinh viên cho bài này. '
                  'Hãy khởi động lại backend để cập nhật dữ liệu mới.',
                  style: TextStyle(color: context.muted),
                )
              else ...[
                _JourneyView(
                  steps: steps,
                  rows: widget.rows,
                  selected: _stoppedAt,
                  onSelect: (i) => setState(() {
                    _stoppedAt = _stoppedAt == i ? null : i;
                    _filter = null;
                  }),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tình trạng nộp',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.strong,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final k in [
                      _Submission.onTime,
                      _Submission.late,
                      _Submission.notSubmitted,
                    ]) ...[
                      if (k != _Submission.onTime) const SizedBox(width: 6),
                      Expanded(
                        child: _SubmissionCountBox(
                          kind: k,
                          count: count[k]!,
                          total: widget.rows.length,
                          selected: _filter == k,
                          onTap: () => setState(() {
                            _filter = _filter == k ? null : k;
                            _stoppedAt = null;
                          }),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _stoppedAt != null
                      ? 'Đang xem: sinh viên dừng trước bước "${steps[_stoppedAt!].label}". Nhấn lại để xem tất cả.'
                      : _filter == null
                      ? 'Nhấn vào một ô để chỉ xem nhóm đó.'
                      : 'Đang xem: ${_submissionStyle(_filter!).$1}. Nhấn lại ô đó để xem tất cả.',
                  style: TextStyle(fontSize: 12, color: context.muted),
                ),
                if (widget.onRemind != null &&
                    count[_Submission.notSubmitted]! > 0) ...[
                  const SizedBox(height: 10),
                  RemindAllButton(
                    count: count[_Submission.notSubmitted]!,
                    label:
                        'Nhắc ${count[_Submission.notSubmitted]} sinh viên chưa nộp',
                    onPressed: () => widget.onRemind!([
                      for (final r in widget.rows)
                        if (r.kind == _Submission.notSubmitted) r.student,
                    ]),
                  ),
                ],
                if (widget.rows.length > 8) ...[
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(
                      isDense: true,
                      prefixIcon: Icon(Icons.search, size: 20),
                      hintText: 'Tìm theo MSSV hoặc tên',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ],
                const SizedBox(height: 10),
                if (shown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Không có sinh viên nào trong mục này.',
                      style: TextStyle(color: context.muted),
                    ),
                  ),
                for (final r in shown)
                  _SubmissionTile(
                    row: r,
                    onTap: widget.onDetail == null
                        ? null
                        : () => widget.onDetail!(r.student),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SubmissionCountBox extends StatelessWidget {
  final _Submission kind;
  final int count, total;
  final bool selected;
  final VoidCallback onTap;
  const _SubmissionCountBox({
    required this.kind,
    required this.count,
    required this.total,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color, _) = _submissionStyle(kind);
    return Material(
      color: color.withValues(alpha: selected ? .18 : .07),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected ? color : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                percentOf(count, total),
                style: TextStyle(fontSize: 11, color: context.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmissionTile extends StatelessWidget {
  final _SubmissionRow row;
  final VoidCallback? onTap;
  const _SubmissionTile({required this.row, this.onTap});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = _submissionStyle(row.kind);
    final t = row.task;
    final s = row.student;
    final now = DateTime.now();
    final detail = switch (row.kind) {
      _Submission.onTime =>
        t.submittedAt != null
            ? 'Nộp lúc ${_hm(t.submittedAt!)} ${_dmy(t.submittedAt!)}'
            : 'Đã nộp',
      _Submission.late =>
        t.submittedAt != null && t.due != null
            ? 'Nộp lúc ${_hm(t.submittedAt!)} ${_dmy(t.submittedAt!)}, '
                  'trễ ${_span(t.submittedAt!.difference(t.due!))}'
            : 'Nộp sau hạn',
      _Submission.notSubmitted =>
        t.due == null
            ? 'Bài không đặt hạn nộp'
            : t.due!.isBefore(now)
            ? 'Đã quá hạn ${_span(now.difference(t.due!))}'
            : 'Còn hạn đến ${_hm(t.due!)} ${_dmy(t.due!)}',
    };
    final identity = [
      if (s.code != null) 'MSSV ${s.code}',
      if (s.classCode != null) s.classCode!,
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: .3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
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
                        style: TextStyle(fontSize: 12, color: context.muted),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    Text(detail, style: const TextStyle(fontSize: 12.5)),
                    if (t.graded)
                      Text(
                        'Đã chấm${t.gradePercentage != null ? ': ${t.gradePercentage!.toStringAsFixed(t.gradePercentage! % 1 == 0 ? 0 : 1)}%' : ''}'
                        '${t.passed == null
                            ? ''
                            : t.passed!
                            ? ' · Đạt'
                            : ' · Chưa đạt'}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: t.passed == false
                              ? Colors.red.shade700
                              : Colors.green.shade800,
                        ),
                      )
                    else if (row.kind != _Submission.notSubmitted)
                      Text(
                        'Chưa được chấm',
                        style: TextStyle(fontSize: 12.5, color: context.muted),
                      ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, color: context.muted),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ journey: assigned → … → passed

class _JourneyStep {
  final String label, stopHint;
  final bool Function(_SubmissionRow) test;
  const _JourneyStep(this.label, this.stopHint, this.test);
}

/// Được giao → (Đã mở đề) → Đã nộp → Đã chấm → (Đạt). "Đã mở đề" only when the course
/// logs activity views; "Đạt" only when some grade has a pass mark to compare with.
List<_JourneyStep> _journeySteps(
  List<_SubmissionRow> rows, {
  required bool viewTracking,
}) => [
  _JourneyStep('Được giao', '', (_) => true),
  if (viewTracking)
    _JourneyStep(
      'Đã mở đề',
      'chưa mở đề lần nào',
      (r) => r.task.viewed || r.task.state == TaskState.completed,
    ),
  _JourneyStep(
    'Đã nộp',
    'chưa nộp bài',
    (r) => r.task.state == TaskState.completed,
  ),
  _JourneyStep(
    'Đã chấm',
    'đã nộp nhưng chưa được chấm',
    (r) => r.task.state == TaskState.completed && r.task.graded,
  ),
  if (rows.any((r) => r.task.passed != null))
    _JourneyStep(
      'Đạt',
      'được chấm nhưng chưa đạt',
      (r) => r.task.passed == true,
    ),
];

class _JourneyView extends StatelessWidget {
  final List<_JourneyStep> steps;
  final List<_SubmissionRow> rows;
  final int? selected;
  final ValueChanged<int> onSelect;
  const _JourneyView({
    required this.steps,
    required this.rows,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final total = rows.length;
    final counts = [for (final st in steps) rows.where(st.test).length];
    // The step that loses the most students is the one to act on.
    var worst = -1, worstLoss = 0;
    for (var i = 1; i < steps.length; i++) {
      final loss = counts[i - 1] - counts[i];
      if (loss > worstLoss) {
        worst = i;
        worstLoss = loss;
      }
    }
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.subtle,
        border: Border.all(color: context.hairline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hành trình làm bài',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            'Sinh viên đi được đến bước nào. Nhấn vào dòng "dừng lại" để xem tên.',
            style: TextStyle(fontSize: 12, color: context.muted),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0 && counts[i - 1] > counts[i])
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => onSelect(i),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selected == i ? context.tint(Colors.red) : null,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '↓ ${counts[i - 1] - counts[i]} sinh viên dừng lại: ${steps[i].stopHint}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: i == worst
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: Colors.red.shade700,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.red.shade200,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 78,
                    child: Text(
                      steps[i].label,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        minHeight: 12,
                        value: total == 0 ? 0 : counts[i] / total,
                        color: primary.withValues(alpha: 1 - i * .12),
                        backgroundColor: context.hairline,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 64,
                    child: Text(
                      '${counts[i]} (${percentOf(counts[i], total)})',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (worst > 0) ...[
            const SizedBox(height: 8),
            Text(
              steps[worst].label == 'Đã chấm'
                  ? 'Nhiều nhất là $worstLoss bài đã nộp nhưng chưa được chấm: nên chấm trên Moodle để sinh viên có phản hồi.'
                  : 'Rơi nhiều nhất ở bước "${steps[worst].label}": $worstLoss sinh viên ${steps[worst].stopHint}.',
              style: const TextStyle(fontSize: 12.5),
            ),
          ],
        ],
      ),
    );
  }
}

/// V2-N15: 0 = no event; 1–4 = quarters of the class maximum (rounded up), so any activity is ≥ 1.
/// Same rule as ClassInsightsService.heatLevel on the server.
int heatLevel(int events, int max) {
  if (events <= 0 || max <= 0) return 0;
  return (4 * events / max).ceil().clamp(1, 4);
}
