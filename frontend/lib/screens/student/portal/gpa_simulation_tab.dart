import 'package:flutter/material.dart';

import '../../../core/gpa_simulator.dart';
import '../../../models/portal.dart';
import '../../../services/api_service.dart';
import '../../../widgets/learning_widgets.dart';
import '../../../widgets/portal_widgets.dart';

/// V3-P3: cumulative GPA projection and graduation-band targets, bridging N1 forecasts.
class GpaSimulationTab extends StatelessWidget {
  final ApiService api;
  const GpaSimulationTab({super.key, required this.api});

  @override
  Widget build(BuildContext context) => PortalView<GpaSimulation>(
    load: (refresh) => api.getGpaSimulation(refresh: refresh),
    builder: (context, s, refresh) => RefreshIndicator(
      onRefresh: refresh,
      child: GpaSimulationView(sim: s),
    ),
  );
}

class GpaSimulationView extends StatefulWidget {
  final GpaSimulation sim;
  const GpaSimulationView({super.key, required this.sim});

  @override
  State<GpaSimulationView> createState() => _GpaSimulationViewState();
}

class _GpaSimulationViewState extends State<GpaSimulationView> {
  late final GpaSimulator _engine = GpaSimulator.of(widget.sim);

  /// course index → chosen letter; LMS courses start at their forecast.
  late final Map<int, String> _chosen = {
    for (var i = 0; i < widget.sim.courses.length; i++)
      if (widget.sim.courses[i].forecastLetter != null)
        i: widget.sim.courses[i].forecastLetter!,
  };

  String _sentence(SimulationResult r) {
    final s = widget.sim;
    final lms = s.courses
        .asMap()
        .entries
        .where(
          (e) =>
              e.value.forecastLetter != null &&
              _chosen[e.key] == e.value.forecastLetter,
        )
        .length;
    final target = r.targets.firstWhere(
      (t) => t.status == TargetStatus.feasible,
      orElse: () => r.targets.isEmpty
          ? const TargetResult(GradeBand('', 0), null, TargetStatus.notFeasible)
          : r.targets.last,
    );
    final buffer = StringBuffer();
    if (_chosen.isEmpty) {
      buffer.write('GPA tích lũy hiện tại ${vn(s.gpa4)}');
    } else if (lms == _chosen.length) {
      buffer.write(
        'Nếu giữ phong độ hiện tại ở $lms môn đang học trên LMS, GPA tích lũy dự kiến ${vn(r.projectedGpa)}',
      );
    } else {
      buffer.write(
        'Với điểm đã chọn, GPA tích lũy dự kiến ${vn(r.projectedGpa)}',
      );
    }
    if (target.band.name.isNotEmpty &&
        target.needed != null &&
        r.remainingCredits > 0) {
      buffer.write(
        '; để đạt ${target.band.name} cần trung bình ${vn(target.needed)} ở ${r.remainingCredits} tín chỉ còn lại',
      );
    }
    buffer.write('.');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sim;
    final r = _engine.simulate([
      for (final e in _chosen.entries) (s.courses[e.key].credits, e.value),
    ]);
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 24,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    PortalStat('GPA hiện tại', vn(s.gpa4)),
                    PortalStat('GPA dự kiến', vn(r.projectedGpa)),
                    if (r.band != null) Chip(label: Text(r.band!)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _sentence(r),
                  key: const Key('gpa-sentence'),
                  style: t.bodyLarge,
                ),
              ],
            ),
          ),
        ),
        DataUntilText(s.dataUntil),
        const SectionHeader('Mục tiêu xếp loại'),
        Card(
          child: Column(
            children: [for (final target in r.targets) _TargetRow(target)],
          ),
        ),
        SectionHeader('Nếu tôi được… (${s.courses.length} học phần)'),
        if (s.courses.isEmpty) const EmptyState('Không còn học phần nào'),
        for (var i = 0; i < s.courses.length; i++)
          _CoursePicker(
            course: s.courses[i],
            letters: [for (final g in s.conversion) g.letter],
            value: _chosen[i],
            onChanged: (v) => setState(() {
              if (v == null) {
                _chosen.remove(i);
              } else {
                _chosen[i] = v;
              }
            }),
          ),
      ],
    );
  }
}

class _TargetRow extends StatelessWidget {
  final TargetResult t;
  const _TargetRow(this.t);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color, icon) = switch (t.status) {
      TargetStatus.achieved => (
        'Đã chắc',
        Colors.green.shade700,
        Icons.verified,
      ),
      TargetStatus.feasible => ('Khả thi', scheme.primary, Icons.trending_up),
      TargetStatus.notFeasible => (
        'Không còn khả thi',
        scheme.outline,
        Icons.block,
      ),
    };
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text('${t.band.name} (≥ ${vn(t.band.min, 1)})'),
      subtitle: Text(label, style: TextStyle(color: color)),
      trailing: t.needed == null || t.status == TargetStatus.achieved
          ? null
          : Text(
              'cần ${vn(t.needed)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
    );
  }
}

class _CoursePicker extends StatelessWidget {
  final SimCourse course;
  final List<String> letters;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _CoursePicker({
    required this.course,
    required this.letters,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final lms = course.lmsCourseName != null;
    final details = [
      '${course.credits} TC',
      if (lms) 'LMS: ${course.lmsCourseName}',
      if (course.forecastPercent != null)
        'hiện ${vn(course.forecastPercent, 1)}%',
      if (!lms && course.status == ProgramStatus.inProgress) 'Đang học',
    ].join(' · ');
    return Card(
      child: ListTile(
        leading: Icon(
          lms ? Icons.school : Icons.menu_book_outlined,
          color: lms ? Theme.of(context).colorScheme.primary : null,
        ),
        title: Text(course.name),
        subtitle: Text(details),
        trailing: DropdownButton<String?>(
          key: Key('pick-${course.code}'),
          value: value,
          hint: const Text('—'),
          underline: const SizedBox.shrink(),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('—')),
            for (final l in letters) DropdownMenuItem(value: l, child: Text(l)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
