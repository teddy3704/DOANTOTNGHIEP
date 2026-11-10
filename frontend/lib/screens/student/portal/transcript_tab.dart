import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../models/portal.dart';
import '../../../services/api_service.dart';
import '../../../widgets/learning_widgets.dart';
import '../../../widgets/portal_widgets.dart';

/// V3-P1: transcript by term, GPA (term and cumulative) and a failed-courses filter.
class TranscriptTab extends StatefulWidget {
  final ApiService api;
  const TranscriptTab({super.key, required this.api});

  @override
  State<TranscriptTab> createState() => _TranscriptTabState();
}

class _TranscriptTabState extends State<TranscriptTab> {
  bool _failedOnly = false;

  @override
  Widget build(BuildContext context) => PortalView<Transcript>(
    load: (refresh) => widget.api.getTranscript(refresh: refresh),
    builder: (context, t, refresh) {
      final s = t.summary;
      final terms = t.terms.reversed.where((term) {
        return !_failedOnly || term.courses.any((c) => c.failed);
      }).toList();
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PortalStatRow([
              PortalStat('GPA tích lũy (hệ 4)', vn(s.cumulativeGpa4)),
              PortalStat('Hệ 10', vn(s.cumulativeGpa10)),
              PortalStat('Tín chỉ tích lũy', vn(s.cumulativeCredits, 0)),
              if (s.rank != null) PortalStat('Xếp loại', s.rank!),
            ]),
            DataUntilText(t.dataUntil),
            if (t.scoredTerms.length >= 2) ...[
              const SectionHeader('GPA theo học kỳ'),
              GpaChart(terms: t.scoredTerms),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(child: SectionHeader('Bảng điểm')),
                FilterChip(
                  key: const Key('failed-filter'),
                  label: const Text('Chưa đạt'),
                  selected: _failedOnly,
                  onSelected: (v) => setState(() => _failedOnly = v),
                ),
              ],
            ),
            if (terms.isEmpty) const EmptyState('Không có học phần chưa đạt'),
            for (final term in terms)
              _TermCard(
                term,
                failedOnly: _failedOnly,
                key: ValueKey('${term.yearStudy}${term.termId}$_failedOnly'),
              ),
          ],
        ),
      );
    },
  );
}

class _TermCard extends StatelessWidget {
  final TranscriptTerm term;
  final bool failedOnly;
  const _TermCard(this.term, {required this.failedOnly, super.key});

  @override
  Widget build(BuildContext context) {
    final courses = failedOnly
        ? term.courses.where((c) => c.failed).toList()
        : term.courses;
    final t = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: failedOnly,
        title: Text(term.label, style: t.titleSmall),
        subtitle: Text(
          term.hasScores
              ? 'TB học kỳ ${vn(term.gpa4)} · tích lũy ${vn(term.cumulativeGpa4)}'
              : 'Đang học · ${term.courses.length} học phần',
        ),
        children: [for (final c in courses) _CourseRow(c)],
      ),
    );
  }
}

class _CourseRow extends StatelessWidget {
  final TranscriptCourse c;
  const _CourseRow(this.c);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = !c.scored
        ? scheme.outline
        : c.passed
        ? Colors.green.shade700
        : scheme.error;
    return ListTile(
      dense: true,
      title: Text(c.name),
      subtitle: Text(
        [
          if (c.code != null) c.code!,
          if (c.credits != null) '${c.credits} TC',
        ].join(' · '),
      ),
      trailing: c.scored
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  c.letter ?? vn(c.score4),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                Text('${vn(c.score10, 1)} · ${vn(c.score4, 1)}'),
              ],
            )
          : Text('Chưa có điểm', style: TextStyle(color: color)),
    );
  }
}

/// Term GPA and cumulative GPA (4-point scale) across scored terms.
class GpaChart extends StatelessWidget {
  final List<TranscriptTerm> terms;
  const GpaChart({super.key, required this.terms});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    List<FlSpot> spots(double? Function(TranscriptTerm) f) => [
      for (var i = 0; i < terms.length; i++)
        if (f(terms[i]) != null) FlSpot(i.toDouble(), f(terms[i])!),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 4,
                  minX: 0,
                  maxX: (terms.length - 1).toDouble(),
                  gridData: const FlGridData(drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: 1,
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          if (i < 0 || i >= terms.length || v != i.toDouble()) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              terms[i].shortLabel,
                              style: const TextStyle(fontSize: 9),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots((t) => t.gpa4),
                      color: scheme.tertiary,
                      barWidth: 2,
                      dotData: const FlDotData(show: true),
                    ),
                    LineChartBarData(
                      spots: spots((t) => t.cumulativeGpa4),
                      color: scheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              children: [
                _Legend(color: scheme.primary, label: 'Tích lũy'),
                _Legend(color: scheme.tertiary, label: 'Học kỳ'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 12, height: 3, color: color),
      const SizedBox(width: 4),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}
