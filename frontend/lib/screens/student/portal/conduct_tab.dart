import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../models/portal.dart';
import '../../../services/api_service.dart';
import '../../../widgets/learning_widgets.dart';
import '../../../widgets/portal_widgets.dart';

/// V3-P4: own conduct (rèn luyện) scores per term.
class ConductTab extends StatelessWidget {
  final ApiService api;
  const ConductTab({super.key, required this.api});

  @override
  Widget build(BuildContext context) => PortalView<ConductHistory>(
    load: (refresh) => api.getConduct(refresh: refresh),
    builder: (context, h, refresh) => RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (h.terms.isEmpty)
            const EmptyState(
              'Chưa có điểm rèn luyện',
              icon: Icons.emoji_events_outlined,
            )
          else ...[
            PortalStatRow([
              PortalStat('Trung bình', vn(h.average, 1)),
              PortalStat('Gần nhất', vn(h.terms.last.finalScore, 0)),
              if (h.terms.last.classification != null)
                PortalStat('Xếp loại', h.terms.last.classification!),
            ]),
            const SectionHeader('Theo học kỳ'),
            _ConductChart(h.terms),
            const SizedBox(height: 8),
            for (final t in h.terms.reversed)
              Card(
                child: ListTile(
                  title: Text(t.label),
                  subtitle: Text(
                    'Tự đánh giá ${vn(t.selfScore, 0)} · Lớp ${vn(t.classScore, 0)} · Khoa ${vn(t.departmentScore, 0)}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        vn(t.finalScore, 0),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (t.classification != null) Text(t.classification!),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    ),
  );
}

class _ConductChart extends StatelessWidget {
  final List<ConductTerm> terms;
  const _ConductChart(this.terms);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: SizedBox(
          height: 170,
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: 100,
              gridData: const FlGridData(drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 25,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (v, meta) {
                      final i = v.toInt();
                      return i < 0 || i >= terms.length
                          ? const SizedBox.shrink()
                          : Padding(
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
              barGroups: [
                for (var i = 0; i < terms.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: terms[i].finalScore ?? 0,
                        color: color,
                        width: 16,
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
