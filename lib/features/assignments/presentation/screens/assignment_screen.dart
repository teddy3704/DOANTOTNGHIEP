import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/external_links/official_lms_launcher.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../domain/assignment.dart';
import '../../domain/assignment_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../reminders/domain/learning_reminder.dart';
import '../../../reminders/presentation/reminder_providers.dart';
import '../../../reminders/presentation/widgets/reminder_editor_sheet.dart';

class AssignmentScreen extends ConsumerWidget {
  const AssignmentScreen({
    required this.courseId,
    required this.assignmentId,
    super.key,
  });

  final String courseId;
  final String assignmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reference = AssignmentReference(
      courseId: courseId,
      assignmentId: assignmentId,
    );
    final assignment = ref.watch(assignmentDetailProvider(reference));
    return Scaffold(
      appBar: AppBar(title: const Text('Bài tập')),
      body: assignment.when(
        loading: () => const _AssignmentLoading(),
        error: (error, _) => ErrorState(
          message: userMessageFor(error),
          onRetry: () => ref.invalidate(assignmentDetailProvider(reference)),
        ),
        data: (item) => item.courseId == courseId
            ? _AssignmentContent(assignment: item)
            : const EmptyState(
                title: 'Không thể mở bài tập',
                message: 'Bài tập này không thuộc khóa học hiện tại.',
                icon: Icons.assignment_late_outlined,
              ),
      ),
    );
  }
}

class _AssignmentContent extends ConsumerWidget {
  const _AssignmentContent({required this.assignment});

  final AssignmentDetail assignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final auth = ref.watch(authControllerProvider);
    final ownerId = auth.session?.userId;
    final reminders = ownerId == null
        ? null
        : ref.watch(remindersForOwnerProvider(ownerId));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _StatusChip(
                              icon: Icons.assignment_turned_in_outlined,
                              label: assignment.submissionState.label,
                            ),
                            _StatusChip(
                              icon: Icons.schedule_rounded,
                              label: assignment.timing.label,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          assignment.name,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: colors.onPrimaryContainer,
                                fontWeight: FontWeight.w900,
                                height: 1.25,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          assignment.description.isEmpty
                              ? 'Bài tập này chưa có mô tả.'
                              : assignment.description,
                          style: TextStyle(
                            color: colors.onPrimaryContainer,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Semantics(
                          label: 'Hạn nộp ${_formatDateTime(assignment.dueAt)}',
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.onPrimaryContainer.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.event_available_rounded,
                                    color: colors.onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Hạn nộp',
                                          style: TextStyle(
                                            color: colors.onPrimaryContainer,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _formatDateTime(assignment.dueAt),
                                          style: TextStyle(
                                            color: colors.onPrimaryContainer,
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
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Mốc thời gian',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Column(
                    children: [
                      _InfoTile(
                        icon: Icons.play_circle_outline_rounded,
                        label: 'Bắt đầu nhận bài',
                        value: _formatDateTime(
                          assignment.allowsSubmissionsFrom,
                        ),
                      ),
                      const Divider(height: 1),
                      _InfoTile(
                        icon: Icons.event_rounded,
                        label: 'Hạn nộp',
                        value: _formatDateTime(assignment.dueAt),
                      ),
                      if (assignment.cutoffAt case final cutoffAt?) ...[
                        const Divider(height: 1),
                        _InfoTile(
                          icon: Icons.lock_clock_outlined,
                          label: 'Kết thúc nhận bài',
                          value: _formatDateTime(cutoffAt),
                        ),
                      ],
                      if (assignment.submittedAt case final submittedAt?) ...[
                        const Divider(height: 1),
                        _InfoTile(
                          icon: Icons.cloud_done_outlined,
                          label: 'Đã nộp lúc',
                          value: _formatDateTime(submittedAt),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Kết quả',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                _GradeCard(assignment: assignment),
                if (ownerId != null &&
                    reminders != null &&
                    (assignment.dueAt?.isAfter(DateTime.now()) ?? false)) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Nhắc việc học tập',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _AssignmentReminderCard(
                    ownerId: ownerId,
                    assignment: assignment,
                    reminders: reminders,
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Thao tác chính thức',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Nộp bài và thao tác học vụ chính thức được thực hiện trên DLU LMS.',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 14),
                        FilledButton.tonalIcon(
                          onPressed: () => _openOfficialLms(context, ref),
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text('Nộp bài trên LMS'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openOfficialLms(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(officialLmsLauncherProvider).openHome();
    } on Object catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userMessageFor(error))));
    }
  }
}

class _AssignmentReminderCard extends ConsumerWidget {
  const _AssignmentReminderCard({
    required this.ownerId,
    required this.assignment,
    required this.reminders,
  });

  final String ownerId;
  final AssignmentDetail assignment;
  final AsyncValue<List<LearningReminder>> reminders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: reminders.when(
          loading: () => const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Đang tải nhắc việc…'),
            ],
          ),
          error: (error, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Không thể tải nhắc việc lúc này.',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.invalidate(remindersForOwnerProvider(ownerId)),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
          data: (items) {
            final existing = items.where((reminder) {
              return reminder.courseId == assignment.courseId &&
                  reminder.assignmentId == assignment.id;
            }).firstOrNull;
            final isEditing = existing != null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing
                      ? 'Bạn đã đặt nhắc lúc ${_formatDateTime(existing.remindAt)}.'
                      : 'Tạo lời nhắc hạn nộp trên thiết bị của bạn.',
                  style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () =>
                      _openEditor(context, ref, existing: existing),
                  icon: Icon(
                    isEditing
                        ? Icons.edit_notifications_outlined
                        : Icons.add_alert_outlined,
                  ),
                  label: Text(
                    isEditing ? 'Chỉnh sửa nhắc việc' : 'Đặt nhắc việc',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    required LearningReminder? existing,
  }) async {
    final dueAt = assignment.dueAt;
    if (dueAt == null) return;
    final saved = await showReminderEditorSheet(
      context,
      repository: ref.read(reminderRepositoryProvider),
      ownerId: ownerId,
      courseId: assignment.courseId,
      assignmentId: assignment.id,
      assignmentName: assignment.name,
      dueAt: dueAt,
      existing: existing,
    );
    if (saved == null || !context.mounted) return;
    ref.invalidate(remindersForOwnerProvider(ownerId));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã lưu nhắc việc.')));
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 18),
    label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
  );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 3),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _GradeCard extends StatelessWidget {
  const _GradeCard({required this.assignment});

  final AssignmentDetail assignment;

  @override
  Widget build(BuildContext context) {
    final grade = assignment.grade;
    final maximum = assignment.gradeMax;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              child: Icon(
                grade == null ? Icons.hourglass_empty_rounded : Icons.grade,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grade == null ? 'Chưa có điểm' : 'Điểm đã công bố',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  if (grade != null)
                    Text(
                      '${_formatNumber(grade)} / ${_formatNumber(maximum ?? 100)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  if (assignment.feedback case final feedback?) ...[
                    const SizedBox(height: 8),
                    Text(feedback),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentLoading extends StatelessWidget {
  const _AssignmentLoading();

  @override
  Widget build(BuildContext context) {
    final skeletonColor = Theme.of(context).colorScheme.surfaceContainerHigh;
    return Semantics(
      liveRegion: true,
      label: 'Đang tải bài tập…',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 260,
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Đang tải bài tập…',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 210,
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime? value) => value == null
    ? 'Chưa đặt hạn'
    : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} lúc ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _formatNumber(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);
