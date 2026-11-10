import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/student_course.dart';
import '../../models/study_plan.dart';
import '../../models/study_session.dart';
import '../../services/api_exception.dart';
import '../../services/api_service.dart';

enum _Phase { setup, focus, saving, rest, done }

String _mmss(Duration d) {
  final s = d.inSeconds < 0 ? 0 : d.inSeconds;
  return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

/// V2-N10 focus session (Pomodoro). Time left is always computed from the start timestamp and the
/// clock, so it stays correct when the app was in the background; the 1 s ticker only repaints.
class FocusTimerScreen extends StatefulWidget {
  final ApiService api;
  final DateTime Function() now;
  final int? initialPlanItemId;
  const FocusTimerScreen({
    super.key,
    required this.api,
    this.now = DateTime.now,
    this.initialPlanItemId,
  });

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  FocusPreset _preset = FocusPreset.short;
  List<StudentCourse> _courses = const [];
  List<PlanItem> _planItems = const [];
  int? _courseId;
  int? _planItemId;
  bool _markDone = true;
  _Phase _phase = _Phase.setup;
  DateTime? _start, _end, _restStart;
  int _savedMinutes = 0;
  int _sessionsDone = 0;
  Object? _saveError;
  Timer? _ticker;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _planItemId = widget.initialPlanItemId;
    _loadTargets();
  }

  Future<void> _loadTargets() async {
    try {
      final courses = await widget.api.getStudentCourses();
      if (mounted) setState(() => _courses = courses);
    } catch (e) {
      debugPrint('Focus courses: $e');
    }
    try {
      final week = await widget.api.getStudyPlan();
      final today = week.dayOf(week.today);
      if (!mounted) return;
      setState(() {
        _planItems =
            today?.items
                .where((i) => i.status == PlanStatus.planned)
                .toList() ??
            const [];
        if (_planItemId != null &&
            !_planItems.any((i) => i.id == _planItemId)) {
          _planItemId = null;
        }
        _courseId = _planItem?.courseId ?? _courseId;
      });
    } catch (e) {
      debugPrint('Focus plan: $e');
    }
  }

  PlanItem? get _planItem =>
      _planItems.where((i) => i.id == _planItemId).firstOrNull;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _tick() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final now = widget.now();
      if (_phase == _Phase.focus && !now.isBefore(_focusEnd)) {
        _finish();
      } else if (_phase == _Phase.rest && !now.isBefore(_restEnd)) {
        _ticker?.cancel();
        setState(() => _phase = _Phase.done);
      } else {
        setState(() {});
      }
    });
  }

  DateTime get _focusEnd => _start!.add(Duration(minutes: _preset.focus));
  DateTime get _restEnd => _restStart!.add(Duration(minutes: _preset.rest));

  void _begin() {
    setState(() {
      _start = widget.now();
      _end = null;
      _saveError = null;
      _phase = _Phase.focus;
    });
    _tick();
  }

  void _cancel() {
    _ticker?.cancel();
    setState(() => _phase = _Phase.setup);
  }

  Future<void> _finish() async {
    _ticker?.cancel();
    final now = widget.now();
    _end = now.isAfter(_focusEnd) ? _focusEnd : now;
    final minutes = focusMinutes(_start!, _end!, _preset.focus);
    if (minutes < 1) {
      setState(() => _phase = _Phase.setup);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phiên dưới 1 phút nên không được lưu')),
      );
      return;
    }
    await _save(minutes);
  }

  Future<void> _save(int minutes) async {
    setState(() {
      _phase = _Phase.saving;
      _saveError = null;
    });
    try {
      final markDone = _planItemId != null && _markDone;
      await widget.api.recordStudySession(
        startedAt: _start!,
        endedAt: _end!,
        focusMinutes: minutes,
        courseId: _courseId,
        planItemId: _planItemId,
        markPlanItemDone: markDone,
      );
      if (!mounted) return;
      _changed = true;
      setState(() {
        _savedMinutes += minutes;
        _sessionsDone++;
        if (markDone) {
          _planItems = _planItems.where((i) => i.id != _planItemId).toList();
          _planItemId = null;
        }
        _restStart = widget.now();
        _phase = _Phase.rest;
      });
      _tick();
    } catch (e) {
      if (mounted) setState(() => _saveError = e);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) Navigator.pop(context, _changed);
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('Học tập trung')),
      body: switch (_phase) {
        _Phase.setup => _setup(),
        _ => _running(),
      },
    ),
  );

  Widget _setup() {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Thời lượng (phút tập trung/nghỉ)',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SegmentedButton<FocusPreset>(
          key: const Key('focus-preset'),
          showSelectedIcon: false,
          segments: [
            for (final p in FocusPreset.values)
              ButtonSegment(value: p, label: Text(p.label)),
          ],
          selected: {_preset},
          onSelectionChanged: (s) => setState(() => _preset = s.first),
        ),
        const SizedBox(height: 20),
        if (_planItems.isNotEmpty) ...[
          Text(
            'Việc trong kế hoạch hôm nay',
            style: theme.textTheme.titleSmall,
          ),
          DropdownButton<int?>(
            key: const Key('focus-plan-item'),
            isExpanded: true,
            value: _planItemId,
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Không chọn'),
              ),
              for (final i in _planItems)
                DropdownMenuItem<int?>(
                  value: i.id,
                  child: Text(i.title, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() {
              _planItemId = v;
              _courseId = _planItem?.courseId ?? _courseId;
            }),
          ),
          if (_planItemId != null)
            CheckboxListTile(
              key: const Key('focus-mark-done'),
              contentPadding: EdgeInsets.zero,
              value: _markDone,
              onChanged: (v) => setState(() => _markDone = v ?? false),
              title: const Text('Đánh dấu xong khi kết thúc phiên'),
            ),
          const SizedBox(height: 12),
        ],
        Text('Khóa học', style: theme.textTheme.titleSmall),
        DropdownButton<int?>(
          key: const Key('focus-course'),
          isExpanded: true,
          value: _courses.any((c) => c.courseId == _courseId)
              ? _courseId
              : null,
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Không chọn'),
            ),
            for (final c in _courses)
              DropdownMenuItem<int?>(
                value: c.courseId,
                child: Text(c.courseName, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) => setState(() => _courseId = v),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          key: const Key('focus-start'),
          onPressed: _begin,
          icon: const Icon(Icons.play_arrow),
          label: Text('Bắt đầu ${_preset.focus} phút'),
        ),
        if (_sessionsDone > 0) ...[
          const SizedBox(height: 16),
          Text(
            'Đã lưu $_sessionsDone phiên · $_savedMinutes phút',
            key: const Key('focus-total'),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _running() {
    final theme = Theme.of(context);
    final now = widget.now();
    final focus = _phase == _Phase.focus || _phase == _Phase.saving;
    final total = Duration(minutes: focus ? _preset.focus : _preset.rest);
    final left = switch (_phase) {
      _Phase.focus => _focusEnd.difference(now),
      _Phase.rest => _restEnd.difference(now),
      _ => Duration.zero,
    };
    final progress = total.inSeconds == 0
        ? 1.0
        : (1 - left.inSeconds / total.inSeconds).clamp(0.0, 1.0);
    final label = switch (_phase) {
      _Phase.focus => 'Đang tập trung',
      _Phase.saving =>
        _saveError == null ? 'Đang lưu phiên…' : 'Chưa lưu được phiên',
      _Phase.rest => 'Nghỉ ngắn',
      _ => 'Hết giờ nghỉ',
    };
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        if (_planItem != null && focus)
          Text(_planItem!.title, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Center(
          child: SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
                Center(
                  child: Text(
                    _mmss(left),
                    key: const Key('focus-left'),
                    style: theme.textTheme.displayMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_phase == _Phase.focus) ...[
          FilledButton.tonalIcon(
            key: const Key('focus-stop'),
            onPressed: _finish,
            icon: const Icon(Icons.stop),
            label: const Text('Kết thúc và lưu'),
          ),
          TextButton(
            key: const Key('focus-cancel'),
            onPressed: _cancel,
            child: const Text('Hủy phiên'),
          ),
        ],
        if (_phase == _Phase.saving && _saveError != null) ...[
          Text(apiErrorMessage(_saveError!), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          FilledButton(
            key: const Key('focus-retry'),
            onPressed: () => _save(focusMinutes(_start!, _end!, _preset.focus)),
            child: const Text('Thử lưu lại'),
          ),
          TextButton(onPressed: _cancel, child: const Text('Bỏ phiên này')),
        ],
        if (_phase == _Phase.rest || _phase == _Phase.done) ...[
          Text(
            'Đã lưu $_sessionsDone phiên · $_savedMinutes phút',
            key: const Key('focus-total'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('focus-next'),
            onPressed: () {
              _ticker?.cancel();
              setState(() => _phase = _Phase.setup);
            },
            icon: const Icon(Icons.replay),
            label: Text(
              _phase == _Phase.rest ? 'Bỏ qua nghỉ' : 'Phiên tiếp theo',
            ),
          ),
        ],
      ],
    );
  }
}

/// Dashboard entry "Học tập trung · Hôm nay N phút"; hidden when the summary cannot load.
class FocusEntryCard extends StatefulWidget {
  final ApiService api;
  const FocusEntryCard({super.key, required this.api});

  @override
  State<FocusEntryCard> createState() => _FocusEntryCardState();
}

class _FocusEntryCardState extends State<FocusEntryCard> {
  late Future<StudySummary?> _future = _load();

  @override
  void initState() {
    super.initState();
    widget.api.studyDataVersion.addListener(_reload);
  }

  @override
  void dispose() {
    widget.api.studyDataVersion.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _future = _load();
    });
  }

  Future<StudySummary?> _load() async {
    try {
      return await widget.api.getStudySummary();
    } catch (e) {
      debugPrint('Focus card: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<StudySummary?>(
    future: _future,
    builder: (context, snap) {
      final s = snap.data;
      if (s == null) return const SizedBox.shrink();
      final today = s.minutesOn(DateTime.now());
      return Card(
        key: const Key('focus-entry-card'),
        child: ListTile(
          leading: const Icon(Icons.timer_outlined),
          title: const Text('Học tập trung'),
          subtitle: Text('Hôm nay $today phút · 7 ngày ${s.totalMinutes} phút'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            // The card refreshes through api.studyDataVersion when a session is saved.
            await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => FocusTimerScreen(api: widget.api),
              ),
            );
          },
        ),
      );
    },
  );
}

/// Analytics "Phút học 7 ngày" bar chart; hidden when the summary cannot load.
class StudyMinutesChart extends StatefulWidget {
  final ApiService api;
  const StudyMinutesChart({super.key, required this.api});

  @override
  State<StudyMinutesChart> createState() => _StudyMinutesChartState();
}

class _StudyMinutesChartState extends State<StudyMinutesChart> {
  static const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  late final Future<StudySummary> _future = widget.api.getStudySummary();

  @override
  Widget build(BuildContext context) => FutureBuilder<StudySummary>(
    future: _future,
    builder: (context, snap) {
      final s = snap.data;
      if (s == null) return const SizedBox.shrink();
      final color = Theme.of(context).colorScheme.primary;
      final max = s.days.fold(0, (m, d) => d.minutes > m ? d.minutes : m);
      return Card(
        key: const Key('study-minutes-chart'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  'Phút học 7 ngày · ${s.totalMinutes} phút',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: BarChart(
                  BarChartData(
                    minY: 0,
                    maxY: max < 30 ? 30 : (max * 1.15).ceilToDouble(),
                    gridData: const FlGridData(drawVerticalLine: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          getTitlesWidget: (v, meta) {
                            final i = v.toInt();
                            if (i < 0 || i >= s.days.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                _weekdays[s.days[i].date.weekday - 1],
                                style: const TextStyle(fontSize: 11),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < s.days.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: s.days[i].minutes.toDouble(),
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
            ],
          ),
        ),
      );
    },
  );
}
