import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../domain/assignment.dart';
import '../../domain/assignment_repository.dart';

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
    final assignment = ref.watch(assignmentDetailProvider(assignmentId));
    return Scaffold(
      appBar: AppBar(title: const Text('Bài tập')),
      body: assignment.when(
        loading: () => const LoadingState(label: 'Đang tải bài tập…'),
        error: (error, _) => ErrorState(
          message: userMessageFor(error),
          onRetry: () => ref.invalidate(assignmentDetailProvider(assignmentId)),
        ),
        data: (item) => _AssignmentContent(assignment: item),
      ),
    );
  }
}

class _AssignmentContent extends StatelessWidget {
  const _AssignmentContent({required this.assignment});

  final AssignmentDetail assignment;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          assignment.description,
                          style: TextStyle(color: colors.onPrimaryContainer),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      _InfoTile(
                        icon: Icons.play_circle_outline_rounded,
                        label: 'Mở nộp bài',
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
                      const Divider(height: 1),
                      _InfoTile(
                        icon: Icons.lock_clock_outlined,
                        label: 'Đóng nhận bài',
                        value: _formatDateTime(assignment.cutoffAt),
                      ),
                      if (assignment.submittedAt case final submittedAt?) ...[
                        const Divider(height: 1),
                        _InfoTile(
                          icon: Icons.cloud_done_outlined,
                          label: 'Nộp gần nhất',
                          value: _formatDateTime(submittedAt),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _GradeCard(assignment: assignment),
                const SizedBox(height: 16),
                Card(
                  color: colors.surfaceContainerHighest,
                  child: const Padding(
                    padding: EdgeInsets.all(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.science_outlined),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Màn hình này chỉ đọc canonical SYNTHETIC DATA. Nộp bài là chức năng write và chỉ được bật qua Moodle API/capability đã xác nhận.',
                          ),
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
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(label),
    trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
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
                  const Text(
                    'Kết quả',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    grade == null
                        ? 'Chưa có điểm'
                        : '${_formatNumber(grade)} / ${_formatNumber(maximum ?? 100)}',
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

String _formatDateTime(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} · ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _formatNumber(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);
