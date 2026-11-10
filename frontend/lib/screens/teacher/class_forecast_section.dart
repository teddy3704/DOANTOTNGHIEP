import 'package:flutter/material.dart';

import '../../core/display_text.dart';
import '../../models/class_forecast.dart';
import '../../services/api_service.dart';

/// V2-N4 "Dự báo qua môn": the N1 engine applied to every student of the course.
/// Loads independently, so a failure never hides the rest of the analytics tab.
class ClassForecastSection extends StatefulWidget {
  final ApiService api;
  final int courseId;
  final void Function(int userId, String name) onOpenStudent;

  /// Optional "Nhắc riêng" action for one student (V2-N8).
  final void Function(StudentPassForecast student)? onRemindOne;

  const ClassForecastSection({
    super.key,
    required this.api,
    required this.courseId,
    required this.onOpenStudent,
    this.onRemindOne,
  });

  @override
  State<ClassForecastSection> createState() => _ClassForecastSectionState();
}

class _ClassForecastSectionState extends State<ClassForecastSection> {
  late Future<ClassForecast> _future = _load();
  PassBand? _filter;

  Future<ClassForecast> _load() =>
      widget.api.getClassForecast(courseId: widget.courseId);

  static Color bandColor(BuildContext context, PassBand band) {
    final scheme = Theme.of(context).colorScheme;
    return switch (band) {
      PassBand.notFeasible => scheme.error,
      PassBand.highRisk => const Color(0xFFE65100),
      PassBand.effort => const Color(0xFFF9A825),
      PassBand.safe => const Color(0xFF2E7D32),
      PassBand.surePass => scheme.primary,
      PassBand.noData => scheme.outline,
    };
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ClassForecast>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (snapshot.hasError) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.cloud_off_outlined),
            title: const Text('Chưa tải được dự báo qua môn'),
            trailing: TextButton(
              onPressed: () => setState(() {
                _future = _load();
              }),
              child: const Text('Thử lại'),
            ),
          ),
        );
      }
      return _content(snapshot.data!);
    },
  );

  Widget _content(ClassForecast data) {
    final theme = Theme.of(context);
    if (data.students.isEmpty) {
      return const Card(
        child: ListTile(title: Text('Lớp chưa có sinh viên để dự báo')),
      );
    }
    final shown = _filter == null
        ? data.students
        : data.students.where((s) => s.band == _filter).toList();
    return Card(
      key: const Key('class-forecast'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Dựa trên điểm thật đã chấm và tỷ trọng từng bài; ngưỡng qua '
              '${formatPercentageVi(data.passPercent)}. Nhóm theo điểm trung bình '
              'còn cần ở các bài chưa chấm: An toàn ≤60%, Cần cố gắng ≤85%, '
              'Nguy cơ cao ≤100%.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final band in PassBand.values)
                  if ((data.counts[band] ?? 0) > 0)
                    FilterChip(
                      avatar: CircleAvatar(
                        backgroundColor: bandColor(context, band),
                        radius: 6,
                      ),
                      label: Text('${band.label} (${data.counts[band]})'),
                      selected: _filter == band,
                      onSelected: (on) =>
                          setState(() => _filter = on ? band : null),
                    ),
              ],
            ),
            const SizedBox(height: 4),
            for (final s in shown) _row(s),
          ],
        ),
      ),
    );
  }

  Widget _row(StudentPassForecast s) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 12),
        InkWell(
          onTap: () => widget.onOpenStudent(s.userId, s.name),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: CircleAvatar(
                    radius: 6,
                    backgroundColor: bandColor(context, s.band),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name, style: theme.textTheme.titleSmall),
                      Text(
                        '${s.band.label} · ${s.band.explain(s.need)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        'Hiện tại ${formatPercentageVi(s.current)} · đã chấm '
                        '${s.gradedCount}, còn ${s.remainingCount} bài · tối đa '
                        '${formatPercentageVi(s.bestCase)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  semanticLabel: 'Xem chi tiết ${s.name}',
                ),
              ],
            ),
          ),
        ),
        if (widget.onRemindOne != null &&
            s.band != PassBand.surePass &&
            s.band != PassBand.noData)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => widget.onRemindOne!(s),
              icon: const Icon(Icons.notifications_active_outlined, size: 16),
              label: const Text('Nhắc riêng'),
            ),
          ),
      ],
    );
  }
}
