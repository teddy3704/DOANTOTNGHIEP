import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/intervention_models.dart';

String interventionDate(DateTime value) {
  final d = value.toLocal();
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

String attentionPath(String courseId, String studentId) =>
    '/teacher/attention/${Uri.encodeComponent(courseId)}/${Uri.encodeComponent(studentId)}';

TeacherIntervention? activeSupportRecord(
  Iterable<TeacherIntervention> records,
  AttentionStudent student,
) {
  final active =
      records
          .where(
            (record) =>
                record.courseId == student.courseId &&
                record.studentId == student.studentId &&
                record.status != InterventionStatus.resolved,
          )
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return active.firstOrNull;
}

class InterventionBody extends StatelessWidget {
  const InterventionBody({required this.children, super.key});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: constraints.maxWidth > 840
            ? (constraints.maxWidth - 800) / 2
            : 20,
        vertical: 24,
      ),
      children: children,
    ),
  );
}

class InterventionHeading extends StatelessWidget {
  const InterventionHeading(this.title, {this.subtitle, super.key});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 8),
        Text(
          subtitle!,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
      const SizedBox(height: 20),
    ],
  );
}

class SupportEmpty extends StatelessWidget {
  const SupportEmpty(this.title, this.message, {super.key});
  final String title, message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Column(
      children: [
        Icon(
          Icons.task_alt_rounded,
          size: 40,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

class AttentionBadge extends StatelessWidget {
  const AttentionBadge(this.priority, {super.key});
  final AttentionPriority priority;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: priority == AttentionPriority.high
            ? colors.tertiaryContainer
            : colors.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        switch (priority) {
          AttentionPriority.high => 'Cần chú ý',
          AttentionPriority.medium => 'Cần theo dõi',
          AttentionPriority.low => 'Theo dõi định kỳ',
        },
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: priority == AttentionPriority.high
              ? colors.onTertiaryContainer
              : colors.onSecondaryContainer,
        ),
      ),
    );
  }
}

class AttentionCard extends StatelessWidget {
  const AttentionCard({
    required this.student,
    this.onContact,
    this.contactLabel = 'Ghi nhận hỗ trợ',
    super.key,
  });
  final AttentionStudent student;
  final VoidCallback? onContact;
  final String contactLabel;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AttentionBadge(student.priority),
          const SizedBox(height: 12),
          Text(
            student.studentName,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            student.courseName,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SnapshotMetrics(snapshot: student.snapshot),
          const SizedBox(height: 14),
          for (final reason in student.reasons.take(2))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('• $reason', style: const TextStyle(height: 1.5)),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => context.push(
                  attentionPath(student.courseId, student.studentId),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Xem chi tiết'),
              ),
              if (onContact != null)
                TextButton.icon(
                  onPressed: onContact,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(contactLabel),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class SnapshotMetrics extends StatelessWidget {
  const SnapshotMetrics({required this.snapshot, super.key});
  final LearningSnapshot snapshot;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 14,
    runSpacing: 10,
    children: [
      _metric(
        context,
        '${snapshot.progressPercent.toStringAsFixed(0)}%',
        'tiến độ',
      ),
      _metric(context, '${snapshot.overdueTasks}', 'việc quá hạn'),
      _metric(context, '${snapshot.pendingTasks}', 'chưa hoàn tất'),
    ],
  );
  Widget _metric(BuildContext context, String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

class InterventionRecordCard extends StatelessWidget {
  const InterventionRecordCard({
    required this.record,
    this.onFollowup,
    this.showStudent = true,
    super.key,
  });
  final TeacherIntervention record;
  final VoidCallback? onFollowup;
  final bool showStudent;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            switch (record.status) {
              InterventionStatus.open => 'Đã ghi nhận',
              InterventionStatus.followingUp => 'Đang theo dõi',
              InterventionStatus.resolved => 'Đã khép lại',
            },
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            showStudent ? record.studentName : record.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (showStudent) ...[
            const SizedBox(height: 4),
            Text(record.courseName),
          ],
          const SizedBox(height: 12),
          Text(record.note, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 12),
          Text(
            '${record.actionType == InterventionAction.contacted ? 'Đã liên hệ' : 'Bắt đầu theo dõi'} · ${interventionDate(record.createdAt)}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (record.followUpAt != null &&
              record.status != InterventionStatus.resolved) ...[
            const SizedBox(height: 8),
            Text(
              'Theo dõi lại: ${interventionDate(record.followUpAt!)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Từ lần ghi nhận đầu tiên',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Tiến độ: ${record.baseline.progressPercent.toStringAsFixed(0)}% → ${record.current.progressPercent.toStringAsFixed(0)}%\nViệc quá hạn: ${record.baseline.overdueTasks} → ${record.current.overdueTasks}\nChưa hoàn tất: ${record.baseline.pendingTasks} → ${record.current.pendingTasks}',
            style: const TextStyle(height: 1.6),
          ),
          const SizedBox(height: 6),
          const Text(
            'So sánh dữ liệu hai thời điểm, không khẳng định quan hệ nhân quả.',
            style: TextStyle(fontSize: 12, height: 1.4),
          ),
          if (record.followups.isNotEmpty) ...[
            const Divider(height: 28),
            for (final followup in record.followups) ...[
              Text(
                interventionDate(followup.createdAt),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(followup.note),
              const SizedBox(height: 4),
              Text(
                '${followup.outcomeStatus == InterventionStatus.resolved ? 'Đã khép lại' : 'Tiếp tục theo dõi'} · ${followup.snapshot.progressPercent.toStringAsFixed(0)}% tiến độ · ${followup.snapshot.overdueTasks} việc quá hạn',
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 8),
            ],
          ],
          if (onFollowup != null &&
              record.status != InterventionStatus.resolved) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onFollowup,
              icon: const Icon(Icons.update_rounded),
              label: const Text('Cập nhật theo dõi'),
            ),
          ],
          if (showStudent)
            TextButton(
              onPressed: () => context.push(
                attentionPath(record.courseId, record.studentId),
              ),
              child: const Text('Xem quá trình hỗ trợ'),
            ),
        ],
      ),
    ),
  );
}
