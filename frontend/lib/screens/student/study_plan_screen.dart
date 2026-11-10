import 'package:flutter/material.dart';

import '../../models/study_plan.dart';
import '../../services/api_exception.dart';
import '../../services/api_service.dart';
import '../../widgets/learning_widgets.dart';
import 'focus_timer_screen.dart';

const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

String _weekday(DateTime d) => _weekdays[d.weekday - 1];
String _dm(DateTime d) => '${d.day}/${d.month}';
bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// V2-N6 "Kế hoạch tuần": 7-day strip, daily list with check-off, minutes used vs budget.
class StudyPlanScreen extends StatefulWidget {
  final ApiService api;
  const StudyPlanScreen({super.key, required this.api});

  @override
  State<StudyPlanScreen> createState() => _StudyPlanScreenState();
}

class _StudyPlanScreenState extends State<StudyPlanScreen> {
  StudyPlanWeek? _week;
  Object? _error;
  bool _busy = false;
  int _budget = 60;
  DateTime? _selected;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final w = await widget.api.getStudyPlan();
      if (!mounted) return;
      setState(() {
        _week = w;
        _budget = w.dailyMinutes;
        _selected ??= w.today;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _generate() async {
    setState(() => _busy = true);
    try {
      final w = await widget.api.generateStudyPlan(_budget);
      if (!mounted) return;
      setState(() {
        _week = w;
        _selected = w.today;
        _changed = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setStatus(PlanItem item, PlanStatus status) async {
    final week = _week;
    if (week == null) return;
    setState(() => _week = week.replace(item.withStatus(status)));
    try {
      final saved = await widget.api.setPlanItemStatus(item.id, status);
      if (mounted) {
        setState(() {
          _week = _week!.replace(saved);
          _changed = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _week = _week!.replace(item));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  Future<void> _focus(int? planItemId) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            FocusTimerScreen(api: widget.api, initialPlanItemId: planItemId),
      ),
    );
    if (changed == true && mounted) {
      _changed = true;
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) Navigator.pop(context, _changed);
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Kế hoạch tuần'),
        actions: [
          IconButton(
            key: const Key('plan-focus'),
            tooltip: 'Học tập trung',
            icon: const Icon(Icons.timer_outlined),
            onPressed: () => _focus(null),
          ),
        ],
      ),
      body: _body(),
    ),
  );

  Widget _body() {
    final week = _week;
    if (week == null) {
      if (_busy) return const Center(child: CircularProgressIndicator());
      return ListView(
        children: [
          EmptyState(
            _error == null
                ? 'Chưa tải được kế hoạch'
                : apiErrorMessage(_error!),
            icon: Icons.cloud_off,
          ),
          Center(
            child: OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ),
        ],
      );
    }
    final day = week.dayOf(_selected ?? week.today) ?? week.days.first;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: SegmentedButton<int>(
                  key: const Key('plan-budget'),
                  showSelectedIcon: false,
                  segments: [
                    for (final m in const [30, 60, 90, 120])
                      ButtonSegment(value: m, label: Text('$m′')),
                  ],
                  selected: {_budget},
                  onSelectionChanged: (s) => setState(() => _budget = s.first),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            key: const Key('plan-generate'),
            onPressed: _busy ? null : _generate,
            icon: const Icon(Icons.auto_awesome),
            label: Text(
              week.isEmpty
                  ? 'Lập kế hoạch $_budget phút/ngày'
                  : 'Lập lại kế hoạch $_budget phút/ngày',
            ),
          ),
          if (week.overloaded.isNotEmpty) _OverloadCard(week.overloaded),
          const SizedBox(height: 12),
          SizedBox(
            // Fixed parts (padding, bar) + text that grows with the user's text scale.
            height: 32 + MediaQuery.textScalerOf(context).scale(76),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final d in week.days)
                  _DayChip(
                    day: d,
                    budget: week.dailyMinutes,
                    selected: _sameDay(d.date, day.date),
                    today: _sameDay(d.date, week.today),
                    onTap: () => setState(() => _selected = d.date),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_sameDay(day.date, week.today) ? 'Hôm nay' : _weekday(day.date)}, ${_dm(day.date)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '${day.plannedMinutes}/${week.dailyMinutes} phút',
                key: const Key('plan-day-minutes'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: week.dailyMinutes == 0
                ? 0
                : (day.doneMinutes / week.dailyMinutes).clamp(0, 1).toDouble(),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          if (day.items.isEmpty)
            EmptyState(
              week.isEmpty ? 'Chưa có kế hoạch' : 'Ngày trống',
              icon: Icons.event_available,
            ),
          for (final item in day.items)
            Card(
              child: CheckboxListTile(
                key: Key('plan-item-${item.id}'),
                value: item.status == PlanStatus.done,
                onChanged: item.status == PlanStatus.skipped
                    ? null
                    : (v) => _setStatus(
                        item,
                        v == true ? PlanStatus.done : PlanStatus.planned,
                      ),
                title: Text(
                  item.title,
                  style: item.status == PlanStatus.planned
                      ? null
                      : const TextStyle(decoration: TextDecoration.lineThrough),
                ),
                subtitle: Text('${item.typeLabel} · ${item.minutes} phút'),
                secondary: PopupMenuButton<String>(
                  tooltip: 'Tùy chọn',
                  onSelected: (v) => v == 'focus'
                      ? _focus(item.id)
                      : _setStatus(item, PlanStatus.values.byName(v)),
                  itemBuilder: (_) => [
                    if (item.status == PlanStatus.planned)
                      const PopupMenuItem(
                        value: 'focus',
                        child: Text('Học tập trung'),
                      ),
                    if (item.status != PlanStatus.skipped)
                      const PopupMenuItem(
                        value: 'skipped',
                        child: Text('Bỏ qua'),
                      )
                    else
                      const PopupMenuItem(
                        value: 'planned',
                        child: Text('Khôi phục'),
                      ),
                  ],
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final PlanDay day;
  final int budget;
  final bool selected;
  final bool today;
  final VoidCallback onTap;

  const _DayChip({
    required this.day,
    required this.budget,
    required this.selected,
    required this.today,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = budget == 0
        ? 0.0
        : (day.plannedMinutes / budget).clamp(0, 1).toDouble();
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 56,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primaryContainer
                : scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: today ? scheme.primary : scheme.outlineVariant,
              width: today ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _weekday(day.date),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(_dm(day.date), style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              SizedBox(
                width: 36,
                child: LinearProgressIndicator(value: fill, minHeight: 4),
              ),
              const SizedBox(height: 4),
              Text(
                '${day.plannedMinutes}′',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverloadCard extends StatelessWidget {
  final List<OverloadItem> items;
  const _OverloadCard(this.items);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: const Key('plan-overload'),
      color: scheme.errorContainer,
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quá tải: ${items.length} việc không kịp trước hạn',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: scheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 4),
            for (final o in items.take(5))
              Text(
                '• ${o.title}${o.due == null ? '' : ' (hạn ${_dm(o.due!)})'}',
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            if (items.length > 5)
              Text(
                'và ${items.length - 5} việc khác',
                style: TextStyle(color: scheme.onErrorContainer),
              ),
          ],
        ),
      ),
    );
  }
}

/// Dashboard card "Hôm nay: 3 việc · 105 phút"; opens the plan. Hidden when the plan cannot load.
class TodayPlanCard extends StatefulWidget {
  final ApiService api;
  const TodayPlanCard({super.key, required this.api});

  @override
  State<TodayPlanCard> createState() => _TodayPlanCardState();
}

class _TodayPlanCardState extends State<TodayPlanCard> {
  late Future<StudyPlanWeek?> _future = _load();

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

  Future<StudyPlanWeek?> _load() async {
    try {
      return await widget.api.getStudyPlan();
    } catch (e) {
      debugPrint('Today plan card: $e');
      return null;
    }
  }

  Future<void> _open() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => StudyPlanScreen(api: widget.api)),
    );
    if (changed == true && mounted) {
      setState(() {
        _future = _load();
      });
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<StudyPlanWeek?>(
    future: _future,
    builder: (context, snap) {
      final w = snap.data;
      if (w == null) return const SizedBox.shrink();
      final today = w.dayOf(w.today);
      final open =
          today?.items.where((i) => i.status == PlanStatus.planned).toList() ??
          const [];
      final minutes = open.fold<int>(0, (s, i) => s + i.minutes);
      return Card(
        key: const Key('today-plan-card'),
        child: ListTile(
          leading: const Icon(Icons.event_note),
          title: Text(
            w.isEmpty
                ? 'Lập kế hoạch học tuần'
                : open.isEmpty
                ? 'Hôm nay: đã xong kế hoạch'
                : 'Hôm nay: ${open.length} việc · $minutes phút',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: _open,
        ),
      );
    },
  );
}
