import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_message.dart';
import '../../application/study_plan_coordinator.dart';
import '../../domain/study_plan.dart';
import '../study_planner_providers.dart';

Future<void> showStudyPlanEditor(
  BuildContext context, {
  StudyRecommendation? recommendation,
  StudyPlanItem? existing,
  DateTime? initialStart,
}) async {
  assert(recommendation != null || existing != null);
  final result = await showModalBottomSheet<StudyPlanResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => StudyPlanEditor(
      recommendation: recommendation,
      existing: existing,
      initialStart: initialStart,
    ),
  );
  if (result != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.reminderWarning ?? 'Đã lưu buổi học vào kế hoạch.',
        ),
      ),
    );
  }
}

class StudyPlanEditor extends ConsumerStatefulWidget {
  const StudyPlanEditor({
    this.recommendation,
    this.existing,
    this.initialStart,
    super.key,
  });
  final StudyRecommendation? recommendation;
  final StudyPlanItem? existing;
  final DateTime? initialStart;

  @override
  ConsumerState<StudyPlanEditor> createState() => _StudyPlanEditorState();
}

class _StudyPlanEditorState extends ConsumerState<StudyPlanEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _duration;
  late final TextEditingController _notes;
  late final StudyPlanCoordinator _coordinator;
  late final ProviderSubscription<StudyPlanCoordinator>
  _coordinatorSubscription;
  late DateTime _start;
  bool _remind = true;
  bool _saving = false;
  bool _loadingReminder = false;
  String? _error;

  DateTime get _now => ref.read(studyPlannerClockProvider)();

  @override
  void initState() {
    super.initState();
    // Keep the editor's original owner. A new profile must not inherit this
    // open form and its assignment, reminder settings or pending write.
    _coordinatorSubscription = ref.listenManual(
      studyPlanCoordinatorProvider,
      (_, _) {},
    );
    _coordinator = _coordinatorSubscription.read();
    _start =
        widget.initialStart ??
        widget.existing?.scheduledStartAt.toLocal() ??
        _now.add(const Duration(hours: 1));
    _duration = TextEditingController(
      text:
          '${widget.existing?.estimatedMinutes ?? widget.recommendation?.recommendedDurationMinutes ?? 45}',
    );
    _notes = TextEditingController(text: widget.existing?.notes ?? '');
    if (widget.existing != null) _loadReminder();
  }

  Future<void> _loadReminder() async {
    _loadingReminder = true;
    try {
      final enabled = await _coordinator.reminderEnabled(widget.existing!);
      if (mounted) setState(() => _remind = enabled);
    } on Object {
      if (mounted) {
        setState(
          () => _error =
              'Chưa đọc được trạng thái nhắc giờ học. Bạn có thể chọn lại trước khi lưu.',
        );
      }
    } finally {
      if (mounted) setState(() => _loadingReminder = false);
    }
  }

  @override
  void dispose() {
    _coordinatorSubscription.close();
    _duration.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final today = studyDay(_now);
    final latest = today.add(const Duration(days: 730));
    final initial = studyDay(_start);
    final date = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: latest,
      initialDate: initial.isBefore(today)
          ? today
          : initial.isAfter(latest)
          ? latest
          : initial,
      helpText: 'Chọn ngày học',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
      helpText: 'Chọn giờ bắt đầu',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (time == null || !mounted) return;
    setState(() {
      _start = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final duration = int.parse(_duration.text);
    final validation = StudyPlanCoordinator.validateSchedule(
      _start,
      duration,
      _now,
    );
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      FocusScope.of(context).unfocus();
      final result = await _coordinator.save(
        assignmentId:
            widget.existing?.assignmentId ??
            widget.recommendation!.assignmentId,
        scheduledStartAt: _start,
        estimatedMinutes: duration,
        notes: _notes.text.trim(),
        remind: _remind,
        existing: widget.existing,
      );
      if (!mounted) return;
      refreshStudyPlanner(ref);
      Navigator.of(context).pop(result);
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = userMessageFor(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_saving,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _form,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.existing == null
                    ? 'Dành thời gian cho việc này'
                    : 'Điều chỉnh buổi học',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                widget.existing?.title ?? widget.recommendation!.assignmentName,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                widget.existing?.courseName ??
                    widget.recommendation!.courseName,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _saving ? null : _pickStart,
                icon: const Icon(Icons.edit_calendar_outlined),
                label: Text(studyDateTime(_start)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _duration,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: 'Thời lượng (phút)',
                  helperText: 'Từ 5 đến 480 phút, tùy nhịp học của bạn.',
                  helperMaxLines: 2,
                  errorMaxLines: 2,
                ),
                validator: (value) {
                  final minutes = int.tryParse(value ?? '');
                  return minutes == null || minutes < 5 || minutes > 480
                      ? 'Nhập số phút từ 5 đến 480.'
                      : null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notes,
                enabled: !_saving,
                minLines: 2,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Mục tiêu cho buổi học',
                  hintText: 'Bạn muốn xử lý phần nào? (không bắt buộc)',
                  hintMaxLines: 2,
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Nhắc khi đến giờ học'),
                subtitle: const Text(
                  'Nhắc trên thiết bị này, không thay đổi lịch LMS.',
                ),
                value: _remind,
                onChanged: _saving || _loadingReminder
                    ? null
                    : (value) => setState(() => _remind = value),
              ),
              const SizedBox(height: 12),
              Text(
                'Đây là kế hoạch cá nhân. Nộp bài và kết quả học tập vẫn được xác nhận trên LMS.',
                style: theme.textTheme.bodySmall,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _saving || _loadingReminder ? null : _save,
                child: Text(_saving ? 'Đang lưu…' : 'Lưu kế hoạch'),
              ),
              TextButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                child: const Text('Hủy'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
