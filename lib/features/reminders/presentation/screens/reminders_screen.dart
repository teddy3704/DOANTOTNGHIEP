import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../assignments/domain/assignment_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/learning_reminder.dart';
import '../reminder_providers.dart';

/// Lists app-owned reminder settings for the active learner.
///
/// The local reminder records intentionally contain only opaque references.
/// A readable assignment name is resolved from the existing read-only source
/// when it is available; identifiers and course content are never displayed.
class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({this.showBackButton = false, super.key});

  final bool showBackButton;

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  final Set<String> _pendingReminderIds = <String>{};

  void _retry(String ownerId) {
    ref.invalidate(remindersForOwnerProvider(ownerId));
    ref.invalidate(upcomingAssignmentsProvider);
  }

  Future<void> _setEnabled({
    required String ownerId,
    required LearningReminder reminder,
    required bool isEnabled,
  }) async {
    if (_pendingReminderIds.contains(reminder.id)) return;
    setState(() => _pendingReminderIds.add(reminder.id));
    try {
      await ref
          .read(reminderRepositoryProvider)
          .setEnabled(
            ownerId: ownerId,
            reminderId: reminder.id,
            isEnabled: isEnabled,
          );
      ref.invalidate(remindersForOwnerProvider(ownerId));
    } on Object catch (error) {
      if (mounted) _showMessage(userMessageFor(error));
    } finally {
      if (mounted) {
        setState(() => _pendingReminderIds.remove(reminder.id));
      }
    }
  }

  Future<void> _confirmDelete({
    required String ownerId,
    required LearningReminder reminder,
  }) async {
    if (_pendingReminderIds.contains(reminder.id)) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa nhắc việc?'),
        content: const Text('Nhắc việc này sẽ bị xóa khỏi thiết bị của bạn.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;

    setState(() => _pendingReminderIds.add(reminder.id));
    try {
      await ref
          .read(reminderRepositoryProvider)
          .delete(ownerId: ownerId, reminderId: reminder.id);
      ref.invalidate(remindersForOwnerProvider(ownerId));
      if (mounted) _showMessage('Đã xóa nhắc việc.');
    } on Object catch (error) {
      if (mounted) _showMessage(userMessageFor(error));
    } finally {
      if (mounted) {
        setState(() => _pendingReminderIds.remove(reminder.id));
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final ownerId = auth.session?.userId;

    if (auth.status == AuthStatus.checking) {
      return _LoadingView(showBackButton: widget.showBackButton);
    }
    if (auth.status != AuthStatus.authenticated || ownerId == null) {
      return _NoActiveLearnerView(showBackButton: widget.showBackButton);
    }

    final reminders = ref.watch(remindersForOwnerProvider(ownerId));
    final assignmentNames = ref
        .watch(upcomingAssignmentsProvider)
        .maybeWhen(
          data: (items) => <String, String>{
            for (final item in items)
              _reference(item.courseId, item.id): item.name,
          },
          orElse: () => const <String, String>{},
        );

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          sliver: SliverToBoxAdapter(
            child: _Header(showBackButton: widget.showBackButton),
          ),
        ),
        reminders.when(
          loading: () => const SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            sliver: _LoadingSliver(),
          ),
          error: (error, _) => SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorState(
              message: userMessageFor(error),
              onRetry: () => _retry(ownerId),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  title: 'Chưa có nhắc việc',
                  message: 'Bạn có thể tạo nhắc việc từ bài tập cần theo dõi.',
                  icon: Icons.notifications_none_rounded,
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              sliver: SliverList.separated(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final reminder = items[index];
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppLayout.maxContentWidth,
                      ),
                      child: _ReminderCard(
                        reminder: reminder,
                        assignmentName:
                            assignmentNames[_reference(
                              reminder.courseId,
                              reminder.assignmentId,
                            )],
                        isPending: _pendingReminderIds.contains(reminder.id),
                        onEnabledChanged: (isEnabled) => _setEnabled(
                          ownerId: ownerId,
                          reminder: reminder,
                          isEnabled: isEnabled,
                        ),
                        onDelete: () => _confirmDelete(
                          ownerId: ownerId,
                          reminder: reminder,
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.showBackButton = false});

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nhắc việc học tập',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Chủ động theo dõi các bài tập quan trọng trên thiết bị của bạn.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
      child: showBackButton
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  tooltip: 'Quay lại',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: AppSpacing.xxs),
                Expanded(child: content),
              ],
            )
          : content,
    );
  }
}

class _NoActiveLearnerView extends StatelessWidget {
  const _NoActiveLearnerView({required this.showBackButton});

  final bool showBackButton;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        sliver: SliverToBoxAdapter(
          child: _Header(showBackButton: showBackButton),
        ),
      ),
      const SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          title: 'Chưa có người học',
          message: 'Chọn người học để xem các nhắc việc của bạn.',
          icon: Icons.person_outline_rounded,
        ),
      ),
    ],
  );
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.showBackButton});

  final bool showBackButton;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        sliver: SliverToBoxAdapter(
          child: _Header(showBackButton: showBackButton),
        ),
      ),
      const SliverPadding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        sliver: _LoadingSliver(),
      ),
    ],
  );
}

class _LoadingSliver extends StatelessWidget {
  const _LoadingSliver();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHigh;
    return SliverList.separated(
      itemCount: 3,
      itemBuilder: (context, index) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppLayout.maxContentWidth,
          ),
          child: Semantics(
            liveRegion: index == 0,
            label: index == 0 ? 'Đang tải nhắc việc học tập' : null,
            child: ExcludeSemantics(
              child: Container(
                height: 156,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
              ),
            ),
          ),
        ),
      ),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.assignmentName,
    required this.isPending,
    required this.onEnabledChanged,
    required this.onDelete,
  });

  final LearningReminder reminder;
  final String? assignmentName;
  final bool isPending;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dueStatus = _dueStatus(reminder.dueAt);
    return Semantics(
      container: true,
      label:
          'Nhắc việc học tập. ${assignmentName ?? 'Bài tập học phần'}. ${_remindAtLabel(reminder.remindAt)}. $dueStatus.',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: reminder.isEnabled
                          ? colors.primaryContainer
                          : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Icon(
                        reminder.isEnabled
                            ? Icons.notifications_active_outlined
                            : Icons.notifications_off_outlined,
                        color: reminder.isEnabled
                            ? colors.onPrimaryContainer
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nhắc việc học tập',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          assignmentName ?? 'Bài tập học phần',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Xóa nhắc việc',
                    onPressed: isPending ? null : onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  _Metadata(
                    icon: Icons.notifications_outlined,
                    label: _remindAtLabel(reminder.remindAt),
                  ),
                  _Metadata(
                    icon: Icons.event_outlined,
                    label: 'Hạn ${_formatDateTime(reminder.dueAt)}',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                dueStatus,
                style: TextStyle(
                  color: _isPast(reminder.dueAt)
                      ? colors.error
                      : colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Divider(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      reminder.isEnabled
                          ? 'Đang bật nhắc việc'
                          : 'Đã tắt nhắc việc',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Switch.adaptive(
                    value: reminder.isEnabled,
                    onChanged: isPending ? null : onEnabledChanged,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        icon,
        size: 16,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: AppSpacing.xxs),
      Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

String _reference(String courseId, String assignmentId) =>
    '$courseId::$assignmentId';

String _remindAtLabel(DateTime value) => 'Nhắc lúc ${_formatDateTime(value)}';

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}, ${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}

String _dueStatus(DateTime dueAt) =>
    _isPast(dueAt) ? 'Đã quá hạn nộp' : 'Hạn nộp vẫn còn hiệu lực';

bool _isPast(DateTime value) => value.isBefore(DateTime.now().toUtc());
