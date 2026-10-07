import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/external_links/official_lms_button.dart';
import '../../application/study_plan_coordinator.dart';
import '../../domain/study_plan.dart';
import '../study_planner_providers.dart';
import 'study_plan_editor.dart';
import 'study_priority_badge.dart';

class StudyPlanCard extends ConsumerStatefulWidget {
  const StudyPlanCard({required this.item, super.key});
  final StudyPlanItem item;

  @override
  ConsumerState<StudyPlanCard> createState() => _StudyPlanCardState();
}

class _StudyPlanCardState extends ConsumerState<StudyPlanCard> {
  bool _busy = false;
  String? _error;

  Future<void> _perform(
    Future<StudyPlanResult> Function() action,
    String message,
  ) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await action();
      if (!mounted) return;
      refreshStudyPlanner(ref);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.reminderWarning ?? message)),
      );
    } on Object catch (error) {
      if (mounted) setState(() => _error = userMessageFor(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmRemove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa buổi học này?'),
        content: const Text(
          'Buổi học và nhắc giờ học liên quan sẽ được xóa. Bài tập trên LMS không thay đổi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Giữ lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa buổi học'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _perform(
      () => ref.read(studyPlanCoordinatorProvider).remove(widget.item),
      'Đã xóa buổi học.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final theme = Theme.of(context);
    final handled = item.status == StudyPlanStatus.handled;
    final now = ref.watch(studyPlannerClockProvider)();
    final stale = !handled && item.scheduledStartAt.isBefore(now);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StudyPriorityBadge(item.priority),
                if (handled)
                  const Chip(
                    avatar: Icon(Icons.task_alt_rounded, size: 18),
                    label: Text('Đã xử lý'),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              item.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.courseName,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Text(
              studyDateTime(item.scheduledStartAt),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '${item.estimatedMinutes} phút · ${studyDeadline(item.dueAt, now)}',
            ),
            if (stale)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Giờ học đã qua. Bạn có thể điều chỉnh kế hoạch hoặc đánh dấu đã xử lý.',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            if (item.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(item.notes),
            ],
            StudyReasons(item.reasons),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
            if (!handled) ...[
              FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () => _perform(
                        () => ref
                            .read(studyPlanCoordinatorProvider)
                            .markHandled(item),
                        'Đã đánh dấu xử lý trong kế hoạch cá nhân.',
                      ),
                icon: const Icon(Icons.check_rounded),
                label: Text(_busy ? 'Đang cập nhật…' : 'Đánh dấu đã xử lý'),
              ),
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => showStudyPlanEditor(context, existing: item),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Điều chỉnh / nhắc giờ học'),
              ),
              TextButton.icon(
                onPressed: _busy
                    ? null
                    : () => showStudyPlanEditor(
                        context,
                        existing: item,
                        initialStart: studyDay(now)
                            .add(const Duration(days: 1))
                            .add(
                              Duration(
                                hours: item.scheduledStartAt.toLocal().hour,
                                minutes: item.scheduledStartAt.toLocal().minute,
                              ),
                            ),
                      ),
                icon: const Icon(Icons.update_rounded),
                label: const Text('Dời sang ngày mai'),
              ),
            ],
            const OfficialLmsButton(label: 'Mở LMS'),
            TextButton.icon(
              onPressed: _busy ? null : _confirmRemove,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Xóa khỏi kế hoạch'),
            ),
          ],
        ),
      ),
    );
  }
}
