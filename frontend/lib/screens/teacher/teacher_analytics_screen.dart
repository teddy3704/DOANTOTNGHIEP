import '../../widgets/chart_axis.dart';
import '../../core/data_profile.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/display_text.dart';
import '../../core/reminder_templates.dart';
import '../../models/class_insights.dart';
import '../../services/api_service.dart';
import '../../widgets/metric_card.dart';
import 'teacher_analytics_actions.dart';
import 'teacher_analytics_sections.dart';
import 'teacher_analytics_widgets.dart';
import 'teacher_monitoring_screens.dart';
import 'teacher_notes_screen.dart';
import 'class_forecast_section.dart';
import 'remind_one.dart';
import 'quiz_insights_section.dart';

class TeacherAnalyticsTab extends StatefulWidget {
  final int courseId;
  final String? courseName;
  final ApiService? api;

  const TeacherAnalyticsTab({
    super.key,
    required this.courseId,
    this.courseName,
    this.api,
  });

  @override
  State<TeacherAnalyticsTab> createState() => _TeacherAnalyticsTabState();
}

/// Strong signals a teacher can filter the warning table by; codes match signal_counts.
const _criteria = [
  ('ABSENCE', 'Vắng ≥20% buổi'),
  ('INACTIVE', 'Không truy cập ≥7 ngày'),
  ('OVERDUE', 'Có bài quá hạn'),
  ('LOW_PROGRESS', 'Tiến độ <60%'),
  ('LOW_GRADE', 'Điểm TB <50%'),
];

/// The rules of derived.student_risk_indicator, as the teacher should read them.
const _scoreRules = [
  ('Không truy cập khóa học 7–13 ngày', '+25'),
  ('Không truy cập từ 14 ngày (hoặc chưa từng vào)', '+40'),
  ('Có 1–2 bài quá hạn chưa nộp', '+15'),
  ('Có từ 3 bài quá hạn chưa nộp', '+30'),
  ('Tiến độ dưới 60%', '+10'),
  ('Tiến độ dưới 30%', '+25'),
  ('Không có hoạt động nào trong 7 ngày qua', '+10'),
];

const _groupRange = {
  WatchGroup.needsSupport: '≥60 điểm',
  WatchGroup.watch: '30–59 điểm',
  WatchGroup.onTrack: 'dưới 30 điểm',
  WatchGroup.unknown: 'thiếu dữ liệu',
};

/// Pie order (calm to urgent) and legend order (urgent first).
const _pieOrder = [
  WatchGroup.onTrack,
  WatchGroup.watch,
  WatchGroup.needsSupport,
  WatchGroup.unknown,
];
const _legendOrder = [
  WatchGroup.needsSupport,
  WatchGroup.watch,
  WatchGroup.onTrack,
  WatchGroup.unknown,
];

class _TeacherAnalyticsTabState extends State<TeacherAnalyticsTab> {
  late final ApiService _api = widget.api ?? ApiService();
  late Future<ClassInsights> _insightsFuture;
  int _selectedWeeks = 8;

  int? _selectedWeek;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _selectedWeek = null;
      _insightsFuture = _api.getClassInsights(
        courseId: widget.courseId,
        weeks: _selectedWeeks,
      );
    });
  }

  void _openDetail(InsightStudent s) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => StudentMonitoringDetailScreen(
        api: _api,
        courseId: widget.courseId,
        userId: s.id,
        name: s.name,
      ),
    ),
  );

  void _openNote(InsightStudent s) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => TeacherNotesScreen(
        api: _api,
        studentId: s.id,
        studentName: s.name,
        courseId: widget.courseId,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8.0,
            children: [
              const Text('Khung thời gian: '),
              DropdownButton<int>(
                value: _selectedWeeks,
                items: const [
                  DropdownMenuItem(value: 4, child: Text('4 tuần')),
                  DropdownMenuItem(value: 8, child: Text('8 tuần')),
                  DropdownMenuItem(value: 12, child: Text('12 tuần')),
                  DropdownMenuItem(value: 16, child: Text('16 tuần')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedWeeks = val;
                      _loadData();
                    });
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<ClassInsights>(
            future: _insightsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text('Lỗi: ${snapshot.error}'),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                );
              }

              final data = snapshot.data;
              if (data == null) {
                return const Center(child: Text('Không có dữ liệu'));
              }

              return ReminderScope(
                remind: _remind,
                child: RefreshIndicator(
                  onRefresh: () async {
                    _loadData();
                    await _insightsFuture;
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (data.students.isNotEmpty)
                          Align(
                            alignment: Alignment.centerRight,
                            // Real data: names are anonymous on screen, so no CSV leaves the device.
                            child: OutlinedButton.icon(
                              key: const Key('export-support-csv'),
                              onPressed: DataProfile.isReal
                                  ? null
                                  : () => _export(data),
                              icon: Icon(
                                DataProfile.isReal
                                    ? Icons.lock_outline
                                    : Icons.file_download_outlined,
                              ),
                              label: Text(
                                DataProfile.isReal
                                    ? 'Ẩn danh đang bật: khóa xuất CSV'
                                    : 'Xuất danh sách cần hỗ trợ',
                              ),
                            ),
                          ),
                        const AnalyticsSectionHeader(
                          'Việc cần làm tuần này',
                          'Gợi ý tự động từ dữ liệu lớp, kèm nút làm ngay.',
                        ),
                        ActionItemsCard(
                          items: data.actionItems,
                          students: data.students,
                          viewTracking: data.activityViewTracking,
                          onDetail: _openDetail,
                          onNote: _openNote,
                        ),
                        const SizedBox(height: 28),
                        const AnalyticsSectionHeader(
                          'Tổng quan lớp học',
                          'Nhấn vào từng ô để xem số liệu của từng sinh viên.',
                        ),
                        _buildSummaryGrid(data),
                        if (data.weeklyChange != null) ...[
                          const SizedBox(height: 16),
                          WeeklyChangeCard(
                            change: data.weeklyChange!,
                            students: data.students,
                            onDetail: _openDetail,
                            onNote: _openNote,
                          ),
                        ],
                        const SizedBox(height: 28),
                        const AnalyticsSectionHeader(
                          'Hỗ trợ sinh viên',
                          'Ai cần giúp, ai đang bỏ dở việc học và hỗ trợ đã có hiệu quả chưa.',
                        ),
                        ..._spaced(
                          _buildWarningBoard(data),
                          _groupCounts(data).values.any((c) => c > 0),
                        ),
                        if (data.heatmap != null)
                          ..._spaced(
                            ActivityHeatmapSection(
                              heatmap: data.heatmap!,
                              students: data.students,
                              onDetail: _openDetail,
                              onNote: _openNote,
                            ),
                            data.heatmap!.rows.isNotEmpty &&
                                data.heatmap!.weeks.isNotEmpty,
                          ),
                        if (data.followUps != null)
                          ..._spaced(
                            SupportFollowUpSection(
                              followUps: data.followUps!,
                              students: data.students,
                              onDetail: _openDetail,
                            ),
                            data.students.isNotEmpty,
                          ),
                        const SizedBox(height: 4),
                        const AnalyticsSectionHeader(
                          'Dự báo qua môn',
                          'Ai đã chắc qua, ai cần cố gắng và ai không còn khả năng qua môn.',
                        ),
                        ClassForecastSection(
                          api: _api,
                          courseId: widget.courseId,
                          onRemindOne: (f) async {
                            final s = data.students
                                .where((x) => x.id == f.userId)
                                .firstOrNull;
                            final sent = await remindOne(
                              context,
                              api: _api,
                              courseId: widget.courseId,
                              userId: f.userId,
                              facts: s != null
                                  ? factsFromInsight(s)
                                  : ReminderFacts(
                                      name: f.name,
                                      averageGrade: f.current,
                                    ),
                            );
                            if (sent && mounted) _loadData();
                          },
                          onOpenStudent: (id, name) => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudentMonitoringDetailScreen(
                                api: _api,
                                courseId: widget.courseId,
                                userId: id,
                                name: name,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const AnalyticsSectionHeader(
                          'Tiến độ và kết quả học tập',
                          'Lớp đã hoàn thành bao nhiêu và kết quả các bài đã chấm.',
                        ),
                        ..._spaced(
                          ProgressGradeQuadrants(
                            students: data.students,
                            onDetail: _openDetail,
                            onNote: _openNote,
                          ),
                          data.students.any(ProgressGradeQuadrants.isPlottable),
                        ),
                        ..._spaced(
                          _buildProgressDistribution(data),
                          data.progressDistribution.any((b) => b.count > 0),
                        ),
                        ..._spaced(
                          _buildWeeklyTrendChart(data.weekly),
                          data.weekly.points.isNotEmpty,
                        ),
                        const SizedBox(height: 4),
                        const AnalyticsSectionHeader(
                          'Phân tích bài kiểm tra',
                          'Bài nào quá khó, bị bỏ nhiều hoặc làm quá nhanh.',
                        ),
                        QuizInsightsSection(
                          api: _api,
                          courseId: widget.courseId,
                          students: data.students,
                        ),
                        const SizedBox(height: 28),
                        const AnalyticsSectionHeader(
                          'Bài tập và hoạt động',
                          'Tình hình nộp bài và những bài cần xem lại.',
                        ),
                        ..._spaced(
                          _buildTaskStatusPieChart(data),
                          data.tasks.total > 0,
                        ),
                        _buildLowActivities(data),
                        _buildInterventions(data.interventions),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Confirms the wording with the teacher, sends, then reloads so the to-do list and
  /// the "Hiệu quả hỗ trợ" section pick up the new reminders.
  Future<bool> _remind(
    List<InsightStudent> students,
    ReminderDraft draft,
  ) async {
    final sent = await showReminderComposer(
      context,
      recipients: [for (final s in students) s.name],
      draft: draft,
      templates: students.length == 1
          ? reminderTemplates(factsFromInsight(students.single))
          : const [],
      send: (title, message) => _api.sendReminders(
        courseId: widget.courseId,
        studentIds: [for (final s in students) s.id],
        title: title,
        message: message,
        sourceType: draft.sourceType,
        sourceId: draft.sourceId,
      ),
    );
    if (sent && mounted) _loadData();
    return sent;
  }

  Future<void> _export(ClassInsights data) async {
    try {
      final n = await exportSupportList(
        api: _api,
        courseId: widget.courseId,
        students: data.students,
      );
      if (mounted && n == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lớp chưa có sinh viên cần hỗ trợ')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không xuất được danh sách')),
      );
    }
  }

  List<String> _progressFormula(ClassInsights data) => [
    'Tiến độ của 1 sinh viên = số hoạt động đã hoàn thành ÷ số hoạt động có bật '
        '"theo dõi hoàn thành" trên Moodle'
        '${(data.trackedActivities ?? 0) > 0 ? ' (khóa này có ${data.trackedActivities} hoạt động)' : ''}.',
    'Tiến độ TB = trung bình cộng tiến độ của ${data.progressStudentCount ?? data.studentCount} sinh viên.',
    'Nguồn: dữ liệu hoàn thành hoạt động của Moodle.',
  ];

  List<String> _gradeFormula(ClassInsights data) {
    final graded = data.gradedStudentCount;
    return [
      'Điểm 1 bài = điểm đạt ÷ điểm tối đa của bài, quy ra %.',
      'Điểm TB của 1 sinh viên = trung bình các bài đã được chấm trên Moodle.',
      graded != null
          ? 'Điểm TB lớp = trung bình của $graded sinh viên đã có điểm; '
                '${data.studentCount - graded} sinh viên chưa có bài nào được chấm nên không tính.'
          : 'Điểm TB lớp = trung bình của các sinh viên đã có điểm.',
      'Nguồn: sổ điểm (gradebook) của Moodle.',
    ];
  }

  void _openMetric(ClassInsights data, String key) {
    final all = data.students;
    switch (key) {
      case 'total':
        showStudentListSheet(
          context,
          title: 'Tất cả sinh viên',
          description:
              'Sinh viên đang ghi danh khóa học trên Moodle, xếp từ cần hỗ trợ nhất.',
          color: Theme.of(context).colorScheme.primary,
          students: all,
          filters: _signalFilters,
          onDetail: _openDetail,
          onNote: _openNote,
        );
      case 'watch':
        showStudentListSheet(
          context,
          title: 'Sinh viên cần chú ý',
          description: 'Gộp hai nhóm "Cần hỗ trợ" và "Cần theo dõi".',
          color: Colors.orange,
          students: all
              .where(
                (s) =>
                    s.group == WatchGroup.needsSupport ||
                    s.group == WatchGroup.watch,
              )
              .toList(),
          filters: _signalFilters,
          howCalculated: const [
            'Mỗi sinh viên có một "điểm theo dõi" từ 0 đến 100.',
            'Từ 30 đến 59 điểm: Cần theo dõi. Từ 60 điểm: Cần hỗ trợ.',
            'Mỗi thẻ bên dưới ghi rõ sinh viên bị cộng điểm vì lý do gì.',
          ],
          onDetail: _openDetail,
          onNote: _openNote,
        );
      case 'progress':
        showStudentListSheet(
          context,
          title: 'Tiến độ từng sinh viên',
          description: 'Xếp từ tiến độ thấp nhất đến cao nhất.',
          color: Colors.green,
          students: [...all]
            ..sort((a, b) => (a.progress ?? -1).compareTo(b.progress ?? -1)),
          howCalculated: _progressFormula(data),
          onDetail: _openDetail,
          onNote: _openNote,
        );
      case 'grade':
        showStudentListSheet(
          context,
          title: 'Điểm từng sinh viên',
          description:
              'Xếp từ điểm thấp nhất; sinh viên chưa có điểm nằm cuối danh sách.',
          color: Colors.purple,
          students: [...all]
            ..sort(
              (a, b) =>
                  (a.averageGrade ?? 1000).compareTo(b.averageGrade ?? 1000),
            ),
          howCalculated: _gradeFormula(data),
          onDetail: _openDetail,
          onNote: _openNote,
        );
    }
  }

  Widget _buildSummaryGrid(ClassInsights data) {
    Widget tappable(String key, Widget card) => InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: data.students.isEmpty ? null : () => _openMetric(data, key),
      child: card,
    );
    final graded = data.gradedStudentCount;
    final wc = data.weeklyChange;
    String vsLastWeek(double d, {String unit = ''}) {
      if (d.abs() < .05) return 'Không đổi so với tuần trước';
      final v = d.abs() == d.abs().roundToDouble()
          ? d.abs().toStringAsFixed(0)
          : d.abs().toStringAsFixed(1);
      return '${d > 0 ? '▲' : '▼'} $v$unit so với tuần trước';
    }

    final progressDelta = wc?.progressBefore != null && wc?.progressNow != null
        ? wc!.progressNow! - wc.progressBefore!
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.15,
          children: [
            tappable(
              'total',
              MetricCard(
                title: 'Tổng sinh viên',
                value: '${data.studentCount}',
                subtitle: 'Đang ghi danh khóa học',
                icon: Icons.people,
                iconColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            tappable(
              'watch',
              MetricCard(
                title: 'Cần chú ý',
                value: '${data.watchCount}',
                subtitle: data.studentCount == 0
                    ? null
                    : wc != null
                    ? '${percentOf(data.watchCount, data.studentCount)} lớp · ${vsLastWeek(wc.watchDelta.toDouble())}'
                    : '${percentOf(data.watchCount, data.studentCount)} lớp (theo dõi + hỗ trợ)',
                icon: Icons.warning_amber_rounded,
                iconColor: Colors.orange,
              ),
            ),
            tappable(
              'progress',
              MetricCard(
                title: 'Tiến độ TB',
                value: data.averageProgress != null
                    ? '${data.averageProgress!.toStringAsFixed(1)}%'
                    : '--',
                subtitle: progressDelta != null
                    ? vsLastWeek(progressDelta, unit: '%')
                    : 'TB % hoạt động đã hoàn thành',
                icon: Icons.trending_up,
                iconColor: Colors.green,
              ),
            ),
            tappable(
              'grade',
              MetricCard(
                title: 'Điểm TB',
                value: data.averageGrade != null
                    ? '${data.averageGrade!.toStringAsFixed(1)}%'
                    : '--',
                subtitle: graded != null
                    ? 'TB % điểm bài đã chấm ($graded SV có điểm)'
                    : 'TB % điểm bài đã chấm',
                icon: Icons.grade,
                iconColor: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- warning board

  /// A section followed by the standard gap, or nothing when it has no data.
  List<Widget> _spaced(Widget section, bool show) =>
      show ? [section, const SizedBox(height: 24)] : const [];

  Map<WatchGroup, int> _groupCounts(ClassInsights data) {
    if (data.groups.total > 0) {
      return {for (final g in WatchGroup.values) g: g.count(data.groups)};
    }
    return {
      for (final g in WatchGroup.values)
        g: data.students.where((s) => s.group == g).length,
    };
  }

  /// Quick filters offered inside a group sheet, one per strong signal.
  static final _signalFilters = [
    for (final (code, label) in _criteria)
      SheetFilter(
        DataProfile.tt(label),
        (InsightStudent s) => s.matchesCriterion(code),
      ),
  ];

  void _openGroup(ClassInsights data, WatchGroup g) => showStudentListSheet(
    context,
    title: g.label,
    description:
        '${watchGroupMeaning(g)} Mỗi thẻ ghi rõ sinh viên được cộng điểm vì lý do gì.',
    color: watchGroupColor(g),
    students: data.students.where((s) => s.group == g).toList(),
    filters: _signalFilters,
    onDetail: _openDetail,
    onNote: _openNote,
  );

  void _openCriterion(
    ClassInsights data,
    String code,
    String label,
  ) => showStudentListSheet(
    context,
    title: label,
    description:
        'Sinh viên ở mọi nhóm có dấu hiệu "$label", xếp từ cần hỗ trợ nhất.',
    color: Colors.blueGrey,
    students: data.students.where((s) => s.matchesCriterion(code)).toList(),
    onDetail: _openDetail,
    onNote: _openNote,
  );

  Widget _buildWarningBoard(ClassInsights data) {
    final counts = _groupCounts(data);
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final canOpen = data.students.isNotEmpty;
    final sectionGroups = _pieOrder.where((g) => counts[g]! > 0).toList();

    return InsightCard(
      icon: Icons.support_agent_outlined,
      color: Colors.deepOrange,
      title: 'Mức độ cần hỗ trợ',
      description:
          'Sinh viên được chia 3 nhóm theo điểm theo dõi 0–100, tính tự động từ hoạt động '
          'trên Moodle. Điểm càng cao càng cần quan tâm.',
      takeaway: _groupTakeaway(data, counts, total),
      hint: canOpen
          ? 'Nhấn vào một màu hoặc một dòng để xem danh sách sinh viên của nhóm.'
          : null,
      howCalculated: const [
        'Điểm theo dõi là tổng điểm của các dấu hiệu dưới đây (tối đa 100):',
      ],
      howCalculatedExtra: [
        for (final (rule, pts) in _scoreRules) _RuleRow(rule, pts),
        const SizedBox(height: 4),
        Text(
          'Số buổi vắng và điểm số chỉ hiển thị để tham khảo, không cộng vào điểm theo dõi.',
          style: TextStyle(fontSize: 12, color: context.muted),
        ),
      ],
      children: [
        const _ScoreScale(),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 42,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          if (event is! FlTapUpEvent) return;
                          final i =
                              response?.touchedSection?.touchedSectionIndex ??
                              -1;
                          if (canOpen && i >= 0 && i < sectionGroups.length) {
                            _openGroup(data, sectionGroups[i]);
                          }
                        },
                      ),
                      sections: [
                        for (final g in sectionGroups)
                          PieChartSectionData(
                            color: watchGroupColor(g),
                            value: counts[g]!.toDouble(),
                            title: '${counts[g]}',
                            radius: 30,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IgnorePointer(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'sinh viên',
                          style: TextStyle(fontSize: 11, color: context.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final g in _legendOrder)
              if (counts[g]! > 0 || g != WatchGroup.unknown)
                _GroupLegendRow(
                  color: watchGroupColor(g),
                  label: '${g.label} (${_groupRange[g]})',
                  count: counts[g]!,
                  percent: percentOf(counts[g]!, total),
                  selected: false,
                  onTap: canOpen && counts[g]! > 0
                      ? () => _openGroup(data, g)
                      : null,
                ),
          ],
        ),
        if (canOpen && data.signalCounts.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Xem theo từng dấu hiệu',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.strong,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (code, label) in _criteria)
                ActionChip(
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    '${DataProfile.tt(label)} · ${data.signalCounts[code] ?? 0}',
                  ),
                  onPressed: (data.signalCounts[code] ?? 0) == 0
                      ? null
                      : () => _openCriterion(data, code, label),
                ),
            ],
          ),
        ],
      ],
    );
  }

  String _groupTakeaway(
    ClassInsights data,
    Map<WatchGroup, int> counts,
    int total,
  ) {
    final support = counts[WatchGroup.needsSupport]!,
        watch = counts[WatchGroup.watch]!;
    if (support + watch == 0) {
      return 'Cả lớp đang học ổn định, chưa có sinh viên cần theo dõi.';
    }
    final top = _criteria
        .map((c) => (c.$2, data.signalCounts[c.$1] ?? 0))
        .where((c) => c.$2 > 0)
        .fold<(String, int)?>(
          null,
          (best, c) => best == null || c.$2 > best.$2 ? c : best,
        );
    return '$support sinh viên (${percentOf(support, total)}) cần hỗ trợ sớm và $watch sinh viên cần theo dõi.'
        '${top != null ? ' Dấu hiệu gặp nhiều nhất: "${top.$1}" (${top.$2} sinh viên).' : ''}';
  }

  // ---------------------------------------------------------------- progress distribution

  static const _bucketColors = [
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFFFDD835),
    Color(0xFF43A047),
    Color(0xFF9E9E9E),
  ];

  /// Same buckets as ClassInsightsService.progressDistribution.
  static int _bucketOf(double? p) => p == null
      ? 4
      : p < 25
      ? 0
      : p < 50
      ? 1
      : p < 75
      ? 2
      : 3;

  Widget _buildProgressDistribution(ClassInsights data) {
    final buckets = data.progressDistribution;
    final maxCount = buckets.fold<int>(0, (m, b) => b.count > m ? b.count : m);
    if (buckets.isEmpty || maxCount == 0) return const SizedBox.shrink();
    final total = buckets.fold<int>(0, (a, b) => a + b.count);

    void open(int i) {
      final bucket = i < 4 ? i : 4;
      final students =
          data.students.where((s) => _bucketOf(s.progress) == bucket).toList()
            ..sort((a, b) => (a.progress ?? -1).compareTo(b.progress ?? -1));
      showStudentListSheet(
        context,
        title: 'Tiến độ ${buckets[i].label}',
        description:
            'Sinh viên đã hoàn thành ${buckets[i].label} số hoạt động cần hoàn thành của khóa học, xếp từ thấp đến cao.',
        color: _bucketColors[bucket],
        students: students,
        howCalculated: _progressFormula(data),
        onDetail: _openDetail,
        onNote: _openNote,
      );
    }

    return InsightCard(
      icon: Icons.stacked_bar_chart,
      color: Colors.green.shade700,
      title: 'Phân bố tiến độ học tập',
      description: 'Số sinh viên ở từng mức hoàn thành hoạt động của khóa học.',
      takeaway:
          '${data.averageProgress != null ? 'Tiến độ trung bình của lớp là '
                    '${data.averageProgress!.toStringAsFixed(1)}%. ' : ''}${_progressTakeaway(buckets, total)}',
      hint: data.students.isNotEmpty
          ? 'Nhấn vào một dòng để xem tên sinh viên ở mức đó.'
          : null,
      howCalculated: _progressFormula(data),
      children: [
        for (var i = 0; i < buckets.length; i++)
          _ProgressBucketRow(
            range: i < 4 ? buckets[i].label : 'Chưa có',
            meaning: _bucketMeaning[i < 4 ? i : 4],
            count: buckets[i].count,
            total: total,
            color: _bucketColors[i < 4 ? i : 4],
            onTap: buckets[i].count > 0 && data.students.isNotEmpty
                ? () => open(i)
                : null,
          ),
      ],
    );
  }

  static const _bucketMeaning = [
    'Mới bắt đầu, rất chậm',
    'Đang chậm hơn lớp',
    'Đã qua nửa chặng',
    'Gần hoàn thành',
    'Chưa có dữ liệu tiến độ',
  ];

  String _progressTakeaway(List<BucketCount> buckets, int total) {
    final low = buckets.take(2).fold<int>(0, (a, b) => a + b.count);
    final high = buckets.length > 3 ? buckets[3].count : 0;
    return '$low/$total sinh viên (${percentOf(low, total)}) có tiến độ dưới 50%; '
        '$high sinh viên đã hoàn thành từ 75% trở lên.';
  }

  // ---------------------------------------------------------------- weekly trend

  Widget _buildWeeklyTrendChart(WeeklyTrend trend) {
    if (trend.points.isEmpty) return const SizedBox.shrink();

    final points = trend.points;
    final primary = Theme.of(context).colorScheme.primary;
    final List<FlSpot> activeSpots = [];
    final List<FlSpot> completedSpots = [];
    double maxY = 0;

    for (int i = 0; i < points.length; i++) {
      final active = points[i].activeStudents.toDouble();
      final completed = points[i].completed.toDouble();
      if (active > maxY) maxY = active;
      if (completed > maxY) maxY = completed;
      activeSpots.add(FlSpot(i.toDouble(), active));
      completedSpots.add(FlSpot(i.toDouble(), completed));
    }

    if (maxY == 0) maxY = 5;
    final selected = (_selectedWeek ?? points.length - 1).clamp(
      0,
      points.length - 1,
    );

    final last = points.last.activeStudents;
    final earlier = points.length > 1
        ? points
                  .take(points.length - 1)
                  .fold<int>(0, (a, p) => a + p.activeStudents) /
              (points.length - 1)
        : null;
    final takeaway = !trend.engagementAvailable
        ? DataProfile.tt(
            'Chưa ghi nhận lượt truy cập nào trong ${points.length} tuần qua.',
          )
        : earlier == null
        ? 'Tuần này có $last sinh viên vào học.'
        : 'Tuần này có $last${trend.studentCount > 0 ? '/${trend.studentCount}' : ''} sinh viên vào học, '
              '${last >= earlier ? 'bằng hoặc cao hơn' : 'thấp hơn'} mức trung bình '
              '${earlier.toStringAsFixed(1)} sinh viên/tuần của các tuần trước.';

    return InsightCard(
      icon: Icons.show_chart,
      title: 'Xu hướng học tập theo tuần',
      description:
          'Số sinh viên vào khóa học và số hoạt động được hoàn thành mỗi tuần.',
      takeaway: takeaway,
      hint: 'Nhấn vào một điểm trên biểu đồ để xem chi tiết tuần đó.',
      howCalculated: const [
        'Sinh viên có hoạt động: sinh viên có ít nhất 1 lượt thao tác trong khóa học trong tuần (theo nhật ký Moodle).',
        'Hoạt động hoàn thành: số lần sinh viên hoàn thành một hoạt động có theo dõi hoàn thành trong tuần.',
        'Tuần tính từ thứ Hai đến Chủ nhật.',
      ],
      children: [
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              lineTouchData: LineTouchData(
                touchCallback: (event, response) {
                  if (event is! FlTapUpEvent && event is! FlPanUpdateEvent) {
                    return;
                  }
                  final spots = response?.lineBarSpots;
                  if (spots != null && spots.isNotEmpty) {
                    setState(() => _selectedWeek = spots.first.spotIndex);
                  }
                },
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => Colors.blueGrey.shade800,
                  getTooltipItems: (spots) => [
                    for (final s in spots)
                      LineTooltipItem(
                        s.barIndex == 0
                            ? '${s.y.toInt()} SV hoạt động'
                            : '${s.y.toInt()} HĐ hoàn thành',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                  ],
                ),
              ),
              extraLinesData: ExtraLinesData(
                verticalLines: [
                  VerticalLine(
                    x: selected.toDouble(),
                    color: context.hairline,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ],
              ),
              titlesData: FlTitlesData(
                leftTitles: countAxisTitles(context, maxY * 1.2),
                show: true,
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 &&
                          idx < points.length &&
                          (points.length <= 8 || idx.isEven)) {
                        final date = points[idx].weekStart;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '${date.day}/${date.month}',
                            style: TextStyle(
                              fontSize: 10,
                              color: context.muted,
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (points.length - 1).toDouble(),
              minY: 0,
              maxY: maxY + (maxY * 0.2),
              lineBarsData: [
                LineChartBarData(
                  spots: activeSpots,
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                ),
                LineChartBarData(
                  spots: completedSpots,
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: Colors.green,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            _LegendItem(
              color: primary,
              text: DataProfile.tt('SV có hoạt động'),
            ),
            const _LegendItem(
              color: Colors.green,
              text: 'Hoạt động hoàn thành',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _weekDetail(trend, selected),
      ],
    );
  }

  Widget _weekDetail(WeeklyTrend trend, int i) {
    final p = trend.points[i];
    final end = p.weekStart.add(const Duration(days: 6));
    String d(DateTime t) => '${t.day}/${t.month}';
    final lines = <String>[
      trend.studentCount > 0
          ? DataProfile.tt(
              '${p.activeStudents}/${trend.studentCount} sinh viên có truy cập (${percentOf(p.activeStudents, trend.studentCount)})',
            )
          : DataProfile.tt('${p.activeStudents} sinh viên có truy cập'),
      '${p.completed} hoạt động được hoàn thành',
      '${p.events} lượt thao tác trên LMS',
    ];
    if (i > 0) {
      final diff = p.activeStudents - trend.points[i - 1].activeStudents;
      lines.add(
        diff == 0
            ? 'Số sinh viên hoạt động không đổi so với tuần trước'
            : 'So với tuần trước: ${diff > 0 ? '+' : ''}$diff sinh viên hoạt động',
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tuần ${d(p.weekStart)} – ${d(end)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          if (!trend.engagementAvailable)
            Text(
              DataProfile.tt(
                'Chưa ghi nhận lượt truy cập nào trong khoảng thời gian này.',
              ),
              style: TextStyle(fontSize: 13, color: context.muted),
            )
          else
            for (final l in lines)
              Text('• $l', style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- task status

  Widget _buildTaskStatusPieChart(ClassInsights data) {
    final status = data.tasks;
    if (status.total == 0) return const SizedBox.shrink();

    final slices = [
      (
        TaskState.completed,
        Colors.green,
        status.completed,
        'Sinh viên đã nộp bài tập hoặc đã làm xong bài kiểm tra, xếp theo số bài đã nộp. '
            'Mỗi thẻ liệt kê đúng những bài sinh viên đó đã nộp.',
      ),
      (
        TaskState.pending,
        Colors.orange,
        status.pending,
        'Sinh viên còn bài chưa nộp nhưng vẫn còn hạn; có thể nhắc trước hạn. '
            'Mỗi thẻ liệt kê những bài đó kèm hạn nộp.',
      ),
      (
        TaskState.overdue,
        Colors.red,
        status.overdue,
        'Sinh viên có bài đã quá hạn mà chưa nộp, xếp theo số bài quá hạn. '
            'Mỗi thẻ liệt kê những bài đó và số ngày trễ.',
      ),
    ];
    final visible = slices.where((s) => s.$3 > 0).toList();

    void open(int i) {
      final (state, color, _, description) = visible[i];
      showStudentListSheet(
        context,
        title: taskStateStyle(state).$1,
        description: description,
        color: color,
        students: data.students.where((s) => s.countIn(state) > 0).toList()
          ..sort((a, b) => b.countIn(state).compareTo(a.countIn(state))),
        taskFocus: state,
        onDetail: _openDetail,
        onNote: _openNote,
      );
    }

    final overdueStudents = data.students
        .where((s) => s.countIn(TaskState.overdue) > 0)
        .length;
    return InsightCard(
      icon: Icons.assignment_turned_in_outlined,
      color: Colors.indigo,
      title: 'Tình hình nộp bài tập và bài kiểm tra',
      description: 'Bao nhiêu lượt bài đã nộp, chưa nộp hoặc đã quá hạn.',
      hint:
          'Nhấn vào một màu hoặc một dòng để xem sinh viên và tên các bài tương ứng.',
      howCalculated: const [
        'Mỗi bài giao cho một sinh viên được tính là 1 lượt (ví dụ 10 sinh viên × 4 bài = 40 lượt).',
        'Đã nộp / đã làm: bài tập có trạng thái "đã nộp" hoặc bài kiểm tra đã làm xong trên Moodle.',
        'Quá hạn: đã qua hạn nộp (hoặc thời điểm đóng bài kiểm tra) mà chưa nộp.',
        'Chưa nộp, còn hạn: chưa nộp và chưa đến hạn, hoặc bài không đặt hạn.',
      ],
      takeaway: status.overdue == 0
          ? 'Không có lượt bài nào quá hạn; ${percentOf(status.completed, status.total)} lượt đã hoàn thành.'
          : '${status.overdue} lượt bài (${percentOf(status.overdue, status.total)}) đã quá hạn'
                '${overdueStudents > 0 ? ', thuộc về $overdueStudents sinh viên' : ''}. Nhấn màu đỏ để xem đó là ai.',
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 42,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          if (event is! FlTapUpEvent) return;
                          final i =
                              response?.touchedSection?.touchedSectionIndex ??
                              -1;
                          if (i >= 0 && i < visible.length) open(i);
                        },
                      ),
                      sections: [
                        for (final s in visible)
                          PieChartSectionData(
                            color: s.$2,
                            value: s.$3.toDouble(),
                            title: '${s.$3}',
                            radius: 28,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IgnorePointer(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${status.total}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'lượt bài',
                          style: TextStyle(fontSize: 11, color: context.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < slices.length; i++)
              _GroupLegendRow(
                color: slices[i].$2,
                label: taskStateStyle(slices[i].$1).$1,
                count: slices[i].$3,
                percent: percentOf(slices[i].$3, status.total),
                selected: false,
                onTap: slices[i].$3 > 0
                    ? () => open(visible.indexOf(slices[i]))
                    : null,
              ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- low completion

  Widget _buildLowActivities(ClassInsights data) {
    final activities = data.lowActivities;
    if (activities.isEmpty) return const SizedBox.shrink();
    final canOpen = data.students.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: InsightCard(
        icon: Icons.report_gmailerrorred_outlined,
        color: Colors.red.shade700,
        title: 'Bài có tỷ lệ hoàn thành thấp',
        description:
            'Bài tập và bài kiểm tra có dưới 50% sinh viên hoàn thành; bài đã quá hạn nên xem lại trước.',
        hint: canOpen
            ? 'Nhấn vào một bài để xem từng sinh viên đã nộp đúng hạn, nộp trễ hay chưa nộp.'
            : null,
        howCalculated: const [
          'Tỷ lệ hoàn thành = số sinh viên đã hoàn thành bài ÷ số sinh viên của lớp.',
          'Chỉ hiển thị bài có tỷ lệ dưới 50%; bài đã quá hạn được xếp lên trước.',
          'Nộp trễ: lần nộp bài (hoặc lần làm xong bài kiểm tra) gần nhất sau hạn nộp trên Moodle.',
        ],
        children: [
          for (final a in activities)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: canOpen
                  ? () => showActivitySubmissionsSheet(
                      context,
                      activity: ActivityRef.low(
                        a,
                        viewTracking: data.activityViewTracking,
                      ),
                      students: data.students,
                      onDetail: _openDetail,
                    )
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          a.type == 'quiz'
                              ? Icons.quiz_outlined
                              : Icons.assignment_outlined,
                          size: 18,
                          color: context.muted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            DemoDisplayNames.activity(a.title),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          a.duePassed ? 'Đã quá hạn' : 'Chưa đến hạn',
                          style: TextStyle(
                            fontSize: 12,
                            color: a.duePassed
                                ? Colors.red.shade700
                                : context.muted,
                          ),
                        ),
                        if (canOpen)
                          Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: context.muted,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: ((a.rate ?? 0) / 100).clamp(0, 1),
                        color: a.duePassed ? Colors.red : Colors.orange,
                        backgroundColor: context.hairline,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${a.doneCount}/${a.studentCount} sinh viên hoàn thành (${(a.rate ?? 0).toStringAsFixed(0)}%)',
                      style: TextStyle(fontSize: 12, color: context.muted),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInterventions(List<Intervention> interventions) {
    if (interventions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AnalyticsSectionHeader(
          'Đề xuất can thiệp',
          'Các hành động gợi ý để cải thiện việc học của lớp.',
        ),
        const SizedBox(height: 12),
        ...interventions.map((i) {
          final dateStr = i.createdAt != null
              ? '${i.createdAt!.hour.toString().padLeft(2, '0')}:${i.createdAt!.minute.toString().padLeft(2, '0')} ${i.createdAt!.day}/${i.createdAt!.month}'
              : '';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(
                Icons.lightbulb_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
              title: Text(
                i.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(i.reason),
                  if (dateStr.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Tạo lúc: $dateStr',
                        style: TextStyle(fontSize: 11, color: context.muted),
                      ),
                    ),
                ],
              ),
              isThreeLine: dateStr.isNotEmpty,
            ),
          );
        }),
      ],
    );
  }
}

/// One progress band: range, what it means, a share-of-class bar and the count.
class _ProgressBucketRow extends StatelessWidget {
  final String range, meaning;
  final int count, total;
  final Color color;
  final VoidCallback? onTap;

  const _ProgressBucketRow({
    required this.range,
    required this.meaning,
    required this.count,
    required this.total,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final share = total == 0 ? 0.0 : count / total;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    range,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color.lerp(color, Colors.black, .35),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(meaning, style: const TextStyle(fontSize: 13)),
                ),
                if (onTap != null)
                  Icon(Icons.chevron_right, size: 18, color: context.muted),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      minHeight: 10,
                      value: share,
                      color: color,
                      backgroundColor: context.hairline,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 2,
                  child: Text(
                    '$count SV (${percentOf(count, total)})',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 0–100 bar split into the three groups, so the thresholds are visible at a glance.
class _ScoreScale extends StatelessWidget {
  const _ScoreScale();

  @override
  Widget build(BuildContext context) {
    Widget segment(int flex, WatchGroup g, String range, BorderRadius radius) =>
        Expanded(
          flex: flex,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: watchGroupColor(g),
                  borderRadius: radius,
                ),
              ),
              const SizedBox(height: 4),
              Text(range, style: TextStyle(fontSize: 11, color: context.muted)),
              Text(
                g.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: watchGroupColor(g),
                ),
              ),
            ],
          ),
        );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        segment(
          30,
          WatchGroup.onTrack,
          '0–29',
          const BorderRadius.horizontal(left: Radius.circular(5)),
        ),
        const SizedBox(width: 2),
        segment(30, WatchGroup.watch, '30–59', BorderRadius.zero),
        const SizedBox(width: 2),
        segment(
          40,
          WatchGroup.needsSupport,
          '60–100',
          const BorderRadius.horizontal(right: Radius.circular(5)),
        ),
      ],
    );
  }
}

class _RuleRow extends StatelessWidget {
  final String rule, points;
  const _RuleRow(this.rule, this.points);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '• ${DataProfile.tt(rule)}',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            points,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

/// A tappable legend line: colour, label, count and share of the whole.
class _GroupLegendRow extends StatelessWidget {
  final Color color;
  final String label, percent;
  final int count;
  final bool selected;
  final VoidCallback? onTap;

  const _GroupLegendRow({
    required this.color,
    required this.label,
    required this.count,
    required this.percent,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: .12) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              Text(
                '$count ($percent)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, size: 16, color: context.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
