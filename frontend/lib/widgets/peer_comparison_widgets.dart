import 'package:fl_chart/fl_chart.dart';
import '../core/data_profile.dart';
import 'package:flutter/material.dart';

import '../core/display_text.dart';
import '../models/peer_comparison.dart';
import '../models/student_course.dart';
import '../services/api_service.dart';

/// V2-N3 card for one course: conclusion text plus a 5-bin histogram with "my" bar highlighted.
/// Hidden when the request fails, so it never blocks the rest of the screen.
class PeerComparisonCard extends StatefulWidget {
  final ApiService api;
  final int courseId;
  final String? courseName;

  const PeerComparisonCard({
    super.key,
    required this.api,
    required this.courseId,
    this.courseName,
  });

  @override
  State<PeerComparisonCard> createState() => _PeerComparisonCardState();
}

class _PeerComparisonCardState extends State<PeerComparisonCard> {
  late final Future<PeerComparison?> _future = () async {
    try {
      return await widget.api.getPeerComparison(courseId: widget.courseId);
    } catch (error) {
      debugPrint('Peer comparison: $error');
      return null;
    }
  }();
  bool _grade = false;

  @override
  Widget build(BuildContext context) => FutureBuilder<PeerComparison?>(
    future: _future,
    builder: (context, snapshot) {
      final data = snapshot.data;
      if (data == null) return const SizedBox.shrink();
      final metric = _grade ? data.grade : data.progress;
      final theme = Theme.of(context);
      return Card(
        key: Key('peer-comparison-${widget.courseId}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.courseName == null
                    ? 'Vị trí của tôi trong lớp'
                    : DemoDisplayNames.course(widget.courseName!),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Tiến độ')),
                  ButtonSegment(value: true, label: Text('Điểm TB')),
                ],
                selected: {_grade},
                onSelectionChanged: (s) => setState(() => _grade = s.first),
              ),
              const SizedBox(height: 8),
              Text(
                metric.conclusion(
                  _grade ? 'Điểm trung bình' : DataProfile.progress,
                ),
                key: const Key('peer-conclusion'),
                style: theme.textTheme.bodyLarge,
              ),
              if (!metric.suppressed && metric.histogram.length == 5) ...[
                const SizedBox(height: 12),
                SizedBox(height: 150, child: _chart(context, metric)),
              ],
              const SizedBox(height: 6),
              Text(
                metric.suppressed
                    ? 'Chỉ so sánh khi lớp có từ ${data.minClassSize} sinh viên có dữ liệu '
                          '(hiện có ${metric.classSize}), để không ai đoán được kết quả của người khác.'
                    : 'Ẩn danh: chỉ có số lượng theo khoảng 20%, không có tên hay điểm của ai. '
                          'Lớp có ${metric.classSize} sinh viên có dữ liệu.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _chart(BuildContext context, PeerMetric metric) {
    final scheme = Theme.of(context).colorScheme;
    final maxCount = metric.histogram.fold<int>(1, (a, b) => b > a ? b : a);
    return Semantics(
      label:
          'Biểu đồ phân bố lớp theo 5 khoảng 20%, cột của bạn là khoảng ${(metric.myBin ?? 0) * 20}–${(metric.myBin ?? 0) * 20 + 20}%',
      child: BarChart(
        BarChartData(
          maxY: maxCount.toDouble(),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 1,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (v, meta) => Text(
                  '${v.toInt() * 20}–${v.toInt() * 20 + 20}',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < 5; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: metric.histogram[i].toDouble(),
                    width: 22,
                    color: i == metric.myBin
                        ? scheme.primary
                        : scheme.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Analytics screen block: one card per enrolled course.
class PeerComparisonList extends StatefulWidget {
  final ApiService api;
  const PeerComparisonList({super.key, required this.api});

  @override
  State<PeerComparisonList> createState() => _PeerComparisonListState();
}

class _PeerComparisonListState extends State<PeerComparisonList> {
  late final Future<List<StudentCourse>?> _courses = () async {
    try {
      return await widget.api.getStudentCourses();
    } catch (error) {
      debugPrint('Peer comparison courses: $error');
      return null;
    }
  }();

  ApiService get api => widget.api;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<StudentCourse>?>(
    future: _courses,
    builder: (context, snapshot) {
      final courses = snapshot.data;
      if (courses == null || courses.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Vị trí của tôi trong lớp',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          for (final c in courses)
            PeerComparisonCard(
              api: api,
              courseId: c.courseId,
              courseName: c.courseName,
            ),
        ],
      );
    },
  );
}
