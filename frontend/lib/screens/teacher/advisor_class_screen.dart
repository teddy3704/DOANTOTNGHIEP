import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/learning_health.dart';
import '../../models/portal.dart';
import '../../services/api_exception.dart';
import '../../services/api_service.dart';
import '../../widgets/learning_health_widgets.dart';
import '../../widgets/learning_widgets.dart';
import '../../widgets/portal_widgets.dart';
import '../portal_sources_screen.dart';

/// V3-P6: advisor class from the training portal, joined with the teacher's own LMS courses.
class AdvisorClassScreen extends StatefulWidget {
  final ApiService api;
  final String classId;
  final bool defaultMask;
  const AdvisorClassScreen({
    super.key,
    required this.api,
    required this.classId,
    this.defaultMask = false,
  });

  @override
  State<AdvisorClassScreen> createState() => _AdvisorClassScreenState();
}

class _AdvisorClassScreenState extends State<AdvisorClassScreen> {
  late bool _mask = widget.defaultMask;
  AdvisorTerm? _term;
  bool _attentionOnly = false;
  late Future<AdvisorOverview> _future = _load();

  Future<AdvisorOverview> _load({bool refresh = false}) =>
      widget.api.getAdvisorOverview(
        widget.classId,
        term: _term,
        mask: _mask,
        refresh: refresh,
      );

  void _reload() => setState(() {
    _future = _load();
  });

  Future<void> _export(AdvisorOverview o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xuất danh sách lớp?'),
        content: Text(
          'Danh sách ${o.students.length} sinh viên lớp ${o.classId} (${o.term?.label ?? ''}) có họ tên, MSSV và điểm sẽ được sao chép dạng CSV.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Sao chép CSV'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final csv = await widget.api.exportAdvisorCsv(
        widget.classId,
        term: _term,
      );
      await Clipboard.setData(ClipboardData(text: csv));
      messenger.showSnackBar(
        SnackBar(
          content: Text('Đã sao chép CSV ${o.students.length} sinh viên'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Lớp cố vấn ${widget.classId}'),
      actions: [
        IconButton(
          tooltip: 'Nguồn dữ liệu',
          icon: const Icon(Icons.verified_user_outlined),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PortalSourcesScreen(api: widget.api, teacher: true),
            ),
          ),
        ),
      ],
    ),
    body: FutureBuilder<AdvisorOverview>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return PortalErrorView(error: snap.error!, onRetry: _reload);
        }
        final o = snap.data!;
        final students = _attentionOnly
            ? o.students.where((s) => s.attention).toList()
            : o.students;
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _future = _load(refresh: true);
            });
            await _future.catchError((_) => o);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<AdvisorTerm>(
                      key: const Key('advisor-term'),
                      isExpanded: true,
                      value: o.term,
                      items: [
                        for (final t in o.terms)
                          DropdownMenuItem(value: t, child: Text(t.label)),
                      ],
                      onChanged: (t) {
                        _term = t;
                        _reload();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Ẩn danh'),
                  Switch(
                    key: const Key('advisor-mask'),
                    value: _mask,
                    onChanged: (v) {
                      _mask = v;
                      _reload();
                    },
                  ),
                ],
              ),
              PortalStatRow([
                PortalStat('Sĩ số', '${o.size}'),
                PortalStat('ĐTB lớp (hệ 4)', vn(o.averageGpa4)),
                if (o.trend != null)
                  PortalStat(
                    'So với ${o.previousTerm?.label ?? 'kỳ trước'}',
                    '${o.trend! >= 0 ? '+' : ''}${vn(o.trend)}',
                    color: o.trend! >= 0
                        ? Colors.green.shade700
                        : Theme.of(context).colorScheme.error,
                  ),
                PortalStat(
                  'Cần quan tâm',
                  '${o.attentionCount}',
                  color: o.attentionCount > 0
                      ? Theme.of(context).colorScheme.error
                      : null,
                ),
              ]),
              const SectionHeader('Phân bố ĐTB hệ 4'),
              _Histogram(o.histogram),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final e in o.ranks.entries)
                    Chip(label: Text('${e.key}: ${e.value}')),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: SectionHeader('Sinh viên (${students.length})'),
                  ),
                  FilterChip(
                    key: const Key('attention-filter'),
                    label: const Text('Cần quan tâm'),
                    selected: _attentionOnly,
                    onSelected: (v) => setState(() => _attentionOnly = v),
                  ),
                  IconButton(
                    key: const Key('advisor-export'),
                    tooltip: _mask ? 'Tắt ẩn danh để xuất' : 'Xuất CSV',
                    onPressed: _mask ? null : () => _export(o),
                    icon: const Icon(Icons.download_outlined),
                  ),
                ],
              ),
              for (final s in students)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${s.no}')),
                    title: Text(s.name),
                    subtitle: Text(
                      [
                        if (s.studentId != null) s.studentId!,
                        if (s.rank != null) s.rank!,
                        if (s.conduct != null) 'RL ${vn(s.conduct, 0)}',
                        ...s.flags.map((f) => f.label),
                      ].join(' · '),
                    ),
                    trailing: Text(
                      vn(s.gpa4),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: s.attention
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdvisorStudentScreen(
                          api: widget.api,
                          classId: widget.classId,
                          no: s.no,
                          term: o.term,
                          mask: _mask,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

class _Histogram extends StatelessWidget {
  final List<HistogramBin> bins;
  const _Histogram(this.bins);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final maxY = bins
        .fold<int>(1, (m, b) => b.count > m ? b.count : m)
        .toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              maxY: maxY * 1.2,
              gridData: const FlGridData(drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (v, meta) {
                      final i = v.toInt();
                      if (i < 0 || i >= bins.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${vn(bins[i].from, 1)}–${vn(bins[i].to, 1)}',
                          style: const TextStyle(fontSize: 9),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < bins.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: bins[i].count.toDouble(),
                        color: color,
                        width: 18,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One advisee: Portal results by term and, when linked, the LMS signals in this teacher's courses.
class AdvisorStudentScreen extends StatelessWidget {
  final ApiService api;
  final String classId;
  final int no;
  final AdvisorTerm? term;
  final bool mask;

  const AdvisorStudentScreen({
    super.key,
    required this.api,
    required this.classId,
    required this.no,
    required this.term,
    required this.mask,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sinh viên cố vấn')),
    body: PortalView<AdvisorStudentDetail>(
      load: (_) => api.getAdvisorStudent(classId, no, term: term, mask: mask),
      builder: (context, d, refresh) {
        final s = d.student;
        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text('${s.no}')),
                title: Text(
                  s.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                subtitle: Text(
                  [if (s.studentId != null) s.studentId!, classId].join(' · '),
                ),
              ),
              if (s.flags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: [
                    for (final f in s.flags)
                      Chip(
                        label: Text(f.label),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.errorContainer,
                      ),
                  ],
                ),
              PortalStatRow([
                PortalStat('ĐTB học kỳ', vn(s.gpa4)),
                PortalStat('TB tích lũy', vn(s.cumulativeGpa4)),
                PortalStat('Tín chỉ', vn(s.credits, 0)),
                if (s.rank != null) PortalStat('Xếp loại', s.rank!),
                PortalStat('Rèn luyện', vn(s.conduct, 0)),
              ]),
              const SectionHeader('Kết quả theo học kỳ'),
              Card(
                child: Column(
                  children: [
                    for (final h in d.history)
                      ListTile(
                        dense: true,
                        title: Text(h.term.label),
                        subtitle: Text('Rèn luyện ${vn(h.conduct, 0)}'),
                        trailing: Text(
                          '${vn(h.gpa4)} · TL ${vn(h.cumulativeGpa4)}',
                        ),
                      ),
                  ],
                ),
              ),
              const SectionHeader('Học tập trên LMS'),
              if (!d.lmsLinked)
                const EmptyState(
                  'Chưa có dữ liệu LMS cho sinh viên này',
                  icon: Icons.link_off,
                )
              else if (d.lmsCourses.isEmpty)
                const EmptyState('Sinh viên không học khóa nào của bạn')
              else
                for (final c in d.lmsCourses)
                  HealthSummaryTile(
                    level: HealthLevel.parse(c.level),
                    title: c.courseName,
                    summary: [
                      if (c.score != null) 'Điểm theo dõi ${c.score}',
                      if (c.progress != null) 'Tiến độ ${vn(c.progress, 0)}%',
                      if (c.overdue != null) '${c.overdue} việc quá hạn',
                    ].join(' · '),
                  ),
            ],
          ),
        );
      },
    ),
  );
}

/// Teacher home entry; hidden when the teacher has no advisor class or the Portal is off.
class AdvisorClassEntry extends StatefulWidget {
  final ApiService api;
  const AdvisorClassEntry({super.key, required this.api});

  @override
  State<AdvisorClassEntry> createState() => _AdvisorClassEntryState();
}

class _AdvisorClassEntryState extends State<AdvisorClassEntry> {
  late final Future<AdvisorClasses?> _future = () async {
    try {
      return await widget.api.getAdvisorClasses();
    } catch (e) {
      debugPrint('Advisor classes: $e');
      return null;
    }
  }();

  @override
  Widget build(BuildContext context) => FutureBuilder<AdvisorClasses?>(
    future: _future,
    builder: (context, snap) {
      final data = snap.data;
      if (data == null || data.classes.isEmpty) return const SizedBox.shrink();
      return Column(
        children: [
          for (final c in data.classes)
            Card(
              key: Key('advisor-entry-$c'),
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: Text('Lớp cố vấn $c'),
                subtitle: const Text('Kết quả học tập từ Portal đào tạo'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdvisorClassScreen(
                      api: widget.api,
                      classId: c,
                      defaultMask: data.presentationMask,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
