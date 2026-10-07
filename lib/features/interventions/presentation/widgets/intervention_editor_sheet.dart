import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../auth/domain/auth_session.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/intervention_models.dart';
import '../intervention_providers.dart';
import 'intervention_widgets.dart';

Future<void> showInterventionEditor(
  BuildContext context, {
  AttentionStudent? student,
  TeacherIntervention? existing,
}) async {
  await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) =>
        InterventionEditorSheet(student: student, existing: existing),
  );
}

/// Records support activity only; no message is sent to the learner or LMS.
class InterventionEditorSheet extends ConsumerStatefulWidget {
  const InterventionEditorSheet({
    this.student,
    this.existing,
    this.clock,
    super.key,
  }) : assert(student != null || existing != null);
  final AttentionStudent? student;
  final TeacherIntervention? existing;
  final DateTime Function()? clock;
  @override
  ConsumerState<InterventionEditorSheet> createState() =>
      _InterventionEditorSheetState();
}

class _InterventionEditorSheetState
    extends ConsumerState<InterventionEditorSheet> {
  final _form = GlobalKey<FormState>();
  final _note = TextEditingController();
  InterventionAction _action = InterventionAction.contacted;
  bool _close = false, _saving = false;
  DateTime? _followUp;
  int? _preset = 3;
  String? _error, _owner;
  DateTime _now() => (widget.clock?.call() ?? DateTime.now()).toLocal();

  @override
  void initState() {
    super.initState();
    _owner = ref.read(authControllerProvider).session?.userId;
    _followUp = _afterDays(3);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  DateTime _afterDays(int days) {
    final now = _now();
    return DateTime(now.year, now.month, now.day + days, 9);
  }

  Future<void> _customDate() async {
    final now = _now();
    final firstDate = DateTime(now.year, now.month, now.day + 1);
    final chosen = await showDatePicker(
      context: context,
      initialDate: _followUp ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 2, now.month, now.day),
      helpText: 'Ngày theo dõi lại',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (chosen == null || !mounted) return;
    setState(() {
      _preset = null;
      _followUp = DateTime(chosen.year, chosen.month, chosen.day, 9);
    });
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final auth = ref.read(authControllerProvider);
    final session = auth.session;
    if (auth.status != AuthStatus.authenticated ||
        session?.role != DluRole.teacher ||
        session?.userId != _owner) {
      setState(
        () => _error = 'Phiên làm việc đã thay đổi. Vui lòng mở lại màn hình.',
      );
      return;
    }
    if (!_close && _followUp != null && !_followUp!.isAfter(_now())) {
      setState(() => _error = 'Chọn ngày theo dõi lại trong tương lai.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repository = ref.read(interventionRepositoryProvider);
      final existing = widget.existing;
      if (existing == null) {
        final student = widget.student!;
        await repository.createIntervention(
          InterventionDraft(
            courseId: student.courseId,
            studentId: student.studentId,
            title: _action == InterventionAction.contacted
                ? 'Liên hệ hỗ trợ học tập'
                : 'Theo dõi tiến độ học tập',
            note: _note.text,
            actionType: _action,
            followUpAt: _followUp,
          ),
        );
      } else {
        await repository.addFollowup(
          existing.id,
          FollowupDraft(
            note: _note.text,
            outcomeStatus: _close
                ? InterventionStatus.resolved
                : InterventionStatus.followingUp,
            nextFollowUpAt: _close ? null : _followUp,
          ),
        );
      }
      if (!mounted) return;
      refreshInterventions(ref);
      final current = ref.read(authControllerProvider);
      final stillSameOwner =
          current.status == AuthStatus.authenticated &&
          current.session?.role == DluRole.teacher &&
          current.session?.userId == _owner;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      if (stillSameOwner) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              _close ? 'Đã khép lại lượt hỗ trợ.' : 'Đã lưu ghi nhận hỗ trợ.',
            ),
          ),
        );
      }
    } on Object catch (error) {
      if (!mounted) return;
      if (ref.read(authControllerProvider).session?.userId != _owner) {
        setState(() {
          _saving = false;
          _error = 'Phiên làm việc đã thay đổi. Vui lòng mở lại màn hình.';
        });
        return;
      }
      setState(() {
        _saving = false;
        _error = userMessageFor(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final existing = widget.existing;
    final name = existing?.studentName ?? widget.student!.studentName;
    return PopScope(
      canPop: !_saving,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  existing == null ? 'Ghi nhận hỗ trợ' : 'Cập nhật theo dõi',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(name, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text(
                  'Ghi lại hành động đã thực hiện. Ứng dụng không gửi tin nhắn hoặc thay đổi điểm trên LMS.',
                  style: TextStyle(height: 1.5),
                ),
                const SizedBox(height: 20),
                if (existing == null) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Đã liên hệ'),
                        selected: _action == InterventionAction.contacted,
                        onSelected: _saving
                            ? null
                            : (_) => setState(
                                () => _action = InterventionAction.contacted,
                              ),
                      ),
                      ChoiceChip(
                        label: const Text('Cần theo dõi'),
                        selected: _action == InterventionAction.monitoring,
                        onSelected: _saving
                            ? null
                            : (_) => setState(
                                () => _action = InterventionAction.monitoring,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _note,
                  enabled: !_saving,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: existing == null
                        ? 'Nội dung đã trao đổi'
                        : 'Kết quả theo dõi',
                    hintText: 'Ghi ngắn gọn việc đã làm và bước tiếp theo',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nhập ghi chú trước khi lưu.'
                      : null,
                ),
                if (existing != null)
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Khép lại lượt hỗ trợ'),
                    subtitle: const Text(
                      'Lưu kết quả và không đặt lịch theo dõi tiếp.',
                    ),
                    value: _close,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _close = value),
                  ),
                if (!_close) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Theo dõi lại',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final days in [1, 3, 7])
                        ChoiceChip(
                          label: Text(
                            days == 1 ? 'Ngày mai' : 'Sau $days ngày',
                          ),
                          selected: _preset == days,
                          onSelected: _saving
                              ? null
                              : (_) => setState(() {
                                  _preset = days;
                                  _followUp = _afterDays(days);
                                }),
                        ),
                      ChoiceChip(
                        label: const Text('Không đặt lịch'),
                        selected: _followUp == null,
                        onSelected: _saving
                            ? null
                            : (_) => setState(() {
                                _preset = null;
                                _followUp = null;
                              }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _customDate,
                    icon: const Icon(Icons.edit_calendar_outlined),
                    label: const Text('Chọn ngày khác'),
                  ),
                  if (_followUp != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Theo dõi lại ngày ${interventionDate(_followUp!)}',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_saving ? 'Đang lưu…' : 'Lưu ghi nhận'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Hủy'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
