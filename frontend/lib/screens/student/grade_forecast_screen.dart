import 'package:flutter/material.dart';

import '../../core/display_text.dart';
import '../../models/grade_forecast.dart';
import '../../services/api_exception.dart';
import '../../services/api_service.dart';
import '../../widgets/async_tab.dart';
import '../../widgets/learning_widgets.dart';
import '../../widgets/moodle_button.dart';

/// V2-N1: "what do I still need?" plus a what-if slider per ungraded activity.
class GradeForecastScreen extends StatefulWidget {
  final ApiService api;
  final int courseId;
  final String courseName;

  const GradeForecastScreen({
    super.key,
    required this.api,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<GradeForecastScreen> createState() => _GradeForecastScreenState();
}

class _GradeForecastScreenState extends State<GradeForecastScreen> {
  late Future<GradeForecast> _future = _load();
  GradeForecast? _data;
  double? _target;
  bool _customTarget = false;
  final Map<int, double> _planned = {};
  bool _saving = false;

  Future<GradeForecast> _load() async {
    final data = await widget.api.getGradeForecast(courseId: widget.courseId);
    _data = data;
    _setTarget(data.passPercent, custom: false);
    return data;
  }

  /// Changing the target resets every slider to the average still needed (0–100).
  void _setTarget(double target, {required bool custom}) {
    final data = _data;
    if (data == null) return;
    _target = target;
    _customTarget = custom;
    final need = (data.needFor(target) ?? 0).clamp(0, 100).toDouble();
    _planned
      ..clear()
      ..addEntries(data.remaining.map((i) => MapEntry(i.gradeItemId, need)));
  }

  Future<void> _askCustomTarget() async {
    final controller = TextEditingController();
    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mục tiêu tự chọn'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Điểm mục tiêu (%)',
            hintText: 'Từ 1 đến 100',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(
                controller.text.trim().replaceAll(',', '.'),
              );
              if (v != null && v >= 1 && v <= 100) Navigator.pop(context, v);
            },
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && mounted) {
      setState(() => _setTarget(value, custom: true));
    }
  }

  Future<void> _saveGoal(double target) async {
    setState(() => _saving = true);
    try {
      await widget.api.createStudentGoal({
        'goal_type': 'target_grade',
        'target_value': double.parse(target.toStringAsFixed(2)),
        'course_id': widget.courseId,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã lưu mục tiêu điểm ${formatPercentageVi(target)} cho khóa học.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mô phỏng điểm')),
    body: SafeArea(
      child: FutureBuilder<GradeForecast>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return CourseTabList(
              children: [
                CourseLoadError(
                  onRetry: () => setState(() {
                    _future = _load();
                  }),
                ),
              ],
            );
          }
          return CourseTabList(children: _content(snapshot.data!));
        },
      ),
    ),
  );

  List<Widget> _content(GradeForecast data) {
    final theme = Theme.of(context);
    if (data.items.isEmpty) {
      return const [
        EmptyState(
          'Khóa học chưa có hoạt động tính điểm',
          subtitle:
              'Khi giảng viên tạo bài tập hoặc bài kiểm tra có điểm, '
              'mô phỏng sẽ xuất hiện ở đây.',
        ),
      ];
    }
    final target = _target ?? data.passPercent;
    final projected = data.projected(_planned);
    final presets = <(String, double)>[
      ('Qua môn', data.passPercent),
      ('70%', 70),
      ('80%', 80),
      ('90%', 90),
    ];
    return [
      DetailCard(
        title: DemoDisplayNames.course(widget.courseName),
        children: [
          Text('Điểm hiện tại', style: theme.textTheme.bodySmall),
          Text(
            formatPercentageVi(data.current),
            key: const Key('forecast-current'),
            style: theme.textTheme.headlineMedium,
          ),
          Text(
            'Trung bình các bài đã chấm (${data.graded.length}/${data.items.length} bài).',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          DetailLine(
            'Ngưỡng qua môn',
            '${formatPercentageVi(data.passPercent)}'
                '${data.passFromDefault ? ' (mặc định, khóa chưa đặt ngưỡng)' : ''}',
          ),
          DetailLine(
            'Khoảng có thể đạt',
            '${formatPercentageVi(data.gradedContribution)} – ${formatPercentageVi(data.bestCase)}',
          ),
        ],
      ),
      const SectionHeader('Chọn mục tiêu'),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final (label, value) in presets)
            ChoiceChip(
              label: Text(label),
              selected: !_customTarget && (target - value).abs() < 1e-6,
              onSelected: (_) =>
                  setState(() => _setTarget(value, custom: false)),
            ),
          ChoiceChip(
            label: Text(
              _customTarget
                  ? 'Tự nhập: ${formatPercentageVi(target)}'
                  : 'Tự nhập',
            ),
            selected: _customTarget,
            onSelected: (_) => _askCustomTarget(),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Card(
        color: _outcomeColor(theme, data.outcomeFor(target)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            data.conclusion(target),
            key: const Key('forecast-conclusion'),
            style: theme.textTheme.titleMedium,
          ),
        ),
      ),
      if (data.hasRemaining) ...[
        const SectionHeader('Thử điểm cho các bài còn lại'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.calculate_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Điểm tổng kết dự kiến: ${formatPercentageVi(projected)}',
                    key: const Key('forecast-projected'),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        for (final item in data.remaining) _slider(item),
      ],
      if (data.graded.isNotEmpty) ...[
        const SectionHeader('Bài đã có điểm'),
        for (final item in data.graded)
          DetailCard(
            title: DemoDisplayNames.activity(item.name),
            children: [
              DetailLine('Điểm', formatPercentageVi(item.scorePercent)),
              DetailLine('Tỷ trọng', formatPercentageVi(item.weight * 100)),
            ],
          ),
      ],
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: _saving ? null : () => _saveGoal(target),
        icon: const Icon(Icons.flag_outlined),
        label: Text('Lưu làm mục tiêu (${formatPercentageVi(target)})'),
      ),
      const SizedBox(height: 8),
      Text(
        'Cách tính: mỗi nhóm điểm lấy trung bình các bài trong nhóm '
        '(Mean of grades), tỷ trọng ghi ở từng bài.'
        '${data.approximation ? ' Cấu trúc điểm của khóa phức tạp hơn mô hình này nên kết quả là ước lượng.' : ''}',
        style: theme.textTheme.bodySmall,
      ),
    ];
  }

  Widget _slider(ForecastItem item) {
    final value = _planned[item.gradeItemId] ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              DemoDisplayNames.activity(item.name),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              'Tỷ trọng ${formatPercentageVi(item.weight * 100)} · '
              'giả sử được ${formatPercentageVi(value)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Slider(
              key: Key('forecast-slider-${item.gradeItemId}'),
              value: value,
              max: 100,
              divisions: 20,
              label: formatPercentageVi(value),
              semanticFormatterCallback: (v) =>
                  'Điểm giả định ${formatPercentageVi(v)}',
              onChanged: (v) => setState(() => _planned[item.gradeItemId] = v),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: MoodleButton(
                path: item.moodlePath,
                courseModuleId: item.courseModuleId,
                compact: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color? _outcomeColor(ThemeData theme, ForecastOutcome outcome) =>
      switch (outcome) {
        ForecastOutcome.achieved => theme.colorScheme.primaryContainer,
        ForecastOutcome.feasible => theme.colorScheme.secondaryContainer,
        ForecastOutcome.notFeasible => theme.colorScheme.errorContainer,
        ForecastOutcome.noRemaining => null,
      };
}
