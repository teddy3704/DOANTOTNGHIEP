import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/learning_reminder.dart';
import '../../domain/reminder_exception.dart';
import '../../domain/reminder_repository.dart';
import '../reminder_providers.dart';

/// Opens an app-owned reminder editor for a read-only assignment.
///
/// The sheet stores only learner-controlled reminder settings. Academic data
/// remains read-only and is never written back to the LMS from this flow.
Future<LearningReminder?> showReminderEditorSheet(
  BuildContext context, {
  required ReminderRepository repository,
  required String ownerId,
  required String courseId,
  required String assignmentId,
  required String assignmentName,
  required DateTime dueAt,
  LearningReminder? existing,
  DateTime Function()? clock,
}) {
  return showModalBottomSheet<LearningReminder>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => ReminderEditorSheet(
      repository: repository,
      ownerId: ownerId,
      courseId: courseId,
      assignmentId: assignmentId,
      assignmentName: assignmentName,
      dueAt: dueAt,
      existingReminder: existing,
      clock: clock,
    ),
  );
}

/// A reusable editor for learner-controlled, device-local reminders.
///
/// It is intentionally supplied with opaque owner/course/assignment references
/// instead of reading any global academic state. This keeps it usable from a
/// course, assignment, calendar, or dashboard surface without duplicating LMS
/// records locally.
class ReminderEditorSheet extends ConsumerStatefulWidget {
  const ReminderEditorSheet({
    this.repository,
    required this.ownerId,
    required this.courseId,
    required this.assignmentId,
    required this.assignmentName,
    required this.dueAt,
    this.existingReminder,
    this.clock,
    super.key,
  });

  /// An explicit repository makes the modal convenient for a caller that has
  /// already read [reminderRepositoryProvider]. The widget falls back to the
  /// provider when embedded directly in another screen or test.
  final ReminderRepository? repository;
  final String ownerId;
  final String courseId;
  final String assignmentId;
  final String assignmentName;
  final DateTime dueAt;
  final LearningReminder? existingReminder;

  /// Injectable only to make validation deterministic in widget tests.
  final DateTime Function()? clock;

  @override
  ConsumerState<ReminderEditorSheet> createState() =>
      _ReminderEditorSheetState();
}

class _ReminderEditorSheetState extends ConsumerState<ReminderEditorSheet> {
  late DateTime _remindAt;
  late bool _isEnabled;
  _ReminderPreset? _selectedPreset;
  bool _isSaving = false;
  String? _errorMessage;

  DateTime _now() => (widget.clock?.call() ?? DateTime.now()).toLocal();

  @override
  void initState() {
    super.initState();
    final existing = widget.existingReminder;
    _isEnabled = existing?.isEnabled ?? true;
    _remindAt = existing?.remindAt.toLocal() ?? _initialReminderTime();
    _selectedPreset = _ReminderPreset.values.where((preset) {
      return _sameInstant(_remindAt, _remindAtFor(preset));
    }).firstOrNull;
  }

  DateTime _initialReminderTime() {
    for (final preset in _ReminderPreset.values) {
      final candidate = _remindAtFor(preset);
      if (_isCandidateAvailable(candidate)) return candidate;
    }
    return widget.dueAt.toLocal().subtract(const Duration(minutes: 1));
  }

  DateTime _remindAtFor(_ReminderPreset preset) =>
      widget.dueAt.toLocal().subtract(preset.offset);

  bool _isCandidateAvailable(DateTime candidate) {
    final now = _now();
    return candidate.isAfter(now) && candidate.isBefore(widget.dueAt);
  }

  String? _validate() {
    final existing = widget.existingReminder;
    if (existing != null &&
        (existing.ownerId != widget.ownerId ||
            existing.courseId != widget.courseId ||
            existing.assignmentId != widget.assignmentId ||
            !existing.dueAt.isAtSameMomentAs(widget.dueAt))) {
      return 'Nhắc việc này không khớp với bài tập đang mở.';
    }
    if (!widget.dueAt.isAfter(_now())) {
      return 'Hạn nộp đã qua nên không thể tạo nhắc việc mới.';
    }
    if (!_remindAt.isAfter(_now())) {
      return 'Thời điểm nhắc cần ở trong tương lai.';
    }
    if (!_remindAt.isBefore(widget.dueAt)) {
      return 'Thời điểm nhắc cần trước hạn nộp.';
    }
    return null;
  }

  Future<void> _chooseCustomDateTime() async {
    if (_isSaving) return;

    final now = _now();
    final due = widget.dueAt.toLocal();
    final firstDate = _dayOnly(now);
    final lastDate = _dayOnly(due);
    if (lastDate.isBefore(firstDate)) {
      setState(() {
        _errorMessage = 'Hạn nộp đã qua nên không thể tạo nhắc việc mới.';
      });
      return;
    }

    final selected = _remindAt.toLocal();
    final selectedDate = _clampDay(_dayOnly(selected), firstDate, lastDate);
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Chọn ngày nhắc việc',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selected),
      helpText: 'Chọn giờ nhắc việc',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (time == null || !mounted) return;

    final custom = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      _remindAt = custom;
      _selectedPreset = null;
      _errorMessage = _validate();
    });
  }

  void _selectPreset(_ReminderPreset preset) {
    final candidate = _remindAtFor(preset);
    if (!_isCandidateAvailable(candidate) || _isSaving) return;
    setState(() {
      _remindAt = candidate;
      _selectedPreset = preset;
      _errorMessage = null;
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final validation = _validate();
    if (validation != null) {
      setState(() => _errorMessage = validation);
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final ReminderRepository repository =
          widget.repository ?? ref.read(reminderRepositoryProvider);
      final existing = widget.existingReminder;
      final reminder = existing == null
          ? await repository.create(
              ownerId: widget.ownerId,
              draft: LearningReminderDraft(
                courseId: widget.courseId,
                assignmentId: widget.assignmentId,
                dueAt: widget.dueAt,
                remindAt: _remindAt,
                isEnabled: _isEnabled,
              ),
            )
          : await repository.update(
              ownerId: widget.ownerId,
              reminder: existing.withUserSettings(
                remindAt: _remindAt,
                isEnabled: _isEnabled,
                updatedAt: _now(),
              ),
            );
      if (!mounted) return;
      ref.invalidate(remindersForOwnerProvider(widget.ownerId));
      Navigator.of(context).pop(reminder);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = error is ReminderException
            ? error.message
            : 'Không thể lưu nhắc việc lúc này. Vui lòng thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isEditing = widget.existingReminder != null;
    final validation = _validate();
    final error = _errorMessage ?? validation;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? 'Chỉnh sửa nhắc việc' : 'Tạo nhắc việc',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.assignmentName.trim().isEmpty
                    ? 'Bài tập học phần'
                    : widget.assignmentName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hạn nộp: ${_formatDateTime(widget.dueAt)}',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              Text(
                'Nhắc trước hạn nộp',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final preset in _ReminderPreset.values)
                    ChoiceChip(
                      label: Text(preset.label),
                      selected: _selectedPreset == preset,
                      onSelected: _isCandidateAvailable(_remindAtFor(preset))
                          ? (_) => _selectPreset(preset)
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _chooseCustomDateTime,
                icon: const Icon(Icons.edit_calendar_outlined),
                label: const Text('Tùy chỉnh thời điểm'),
              ),
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notifications_active_outlined,
                        color: colors.onSecondaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thời điểm nhắc',
                              style: TextStyle(
                                color: colors.onSecondaryContainer,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _formatDateTime(_remindAt),
                              style: TextStyle(
                                color: colors.onSecondaryContainer,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Bật nhắc việc'),
                subtitle: const Text('Bạn có thể thay đổi trong ứng dụng.'),
                value: _isEnabled,
                onChanged: _isSaving
                    ? null
                    : (isEnabled) => setState(() => _isEnabled = isEnabled),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Semantics(
                  liveRegion: true,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.errorContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        error,
                        style: TextStyle(color: colors.onErrorContainer),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: Text(
                  _isSaving
                      ? 'Đang lưu…'
                      : isEditing
                      ? 'Lưu thay đổi'
                      : 'Lưu nhắc việc',
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isSaving
                    ? null
                    : () => Navigator.of(context).maybePop(),
                child: const Text('Hủy'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ReminderPreset {
  threeDays('3 ngày trước', Duration(days: 3)),
  oneDay('1 ngày trước', Duration(days: 1)),
  oneHour('1 giờ trước', Duration(hours: 1));

  const _ReminderPreset(this.label, this.offset);

  final String label;
  final Duration offset;
}

DateTime _dayOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime _clampDay(DateTime value, DateTime minimum, DateTime maximum) {
  if (value.isBefore(minimum)) return minimum;
  if (value.isAfter(maximum)) return maximum;
  return value;
}

bool _sameInstant(DateTime left, DateTime right) =>
    left.isAtSameMomentAs(right);

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} lúc ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
