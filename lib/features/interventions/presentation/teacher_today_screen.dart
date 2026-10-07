import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'widgets/intervention_editor_sheet.dart';
import 'widgets/intervention_widgets.dart';
import 'widgets/teacher_support_body.dart';

class TeacherTodayScreen extends StatelessWidget {
  const TeacherTodayScreen({this.clock, super.key});
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) => TeacherSupportBody(
    builder: (data) {
      final due =
          data.interventions
              .where((i) => i.isDue(clock?.call() ?? DateTime.now()))
              .toList()
            ..sort((a, b) => a.followUpAt!.compareTo(b.followUpAt!));
      final attention = data.attention.where((s) => s.needsAttention).toList();
      return InterventionBody(
        children: [
          const InterventionHeading(
            'Hôm nay cần hỗ trợ ai?',
            subtitle:
                'Ưu tiên từ tiến độ và bài tập hiện có. Ghi lại hỗ trợ và hẹn theo dõi lại.',
          ),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${attention.length} lượt cần chú ý · ${due.length} lịch đến hạn',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Mỗi lượt gắn với một sinh viên trong một học phần. Không suy luận việc vắng học hoặc lý do cá nhân.',
                    style: TextStyle(
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: () => context.push('/teacher/interventions'),
                    icon: const Icon(Icons.inbox_outlined),
                    label: const Text('Mở sổ theo dõi'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const InterventionHeading('Theo dõi lại hôm nay'),
          if (due.isEmpty)
            const SupportEmpty(
              'Chưa có lịch đến hạn',
              'Các lịch theo dõi hôm nay và quá hạn xuất hiện ở đây.',
            ),
          for (final record in due.take(3))
            InterventionRecordCard(
              record: record,
              onFollowup: () =>
                  showInterventionEditor(context, existing: record),
            ),
          const SizedBox(height: 16),
          const InterventionHeading('Ưu tiên hỗ trợ'),
          if (attention.isEmpty)
            const SupportEmpty(
              'Chưa có lượt cần ưu tiên',
              'Tiến độ và bài tập hiện tại chưa cho thấy dấu hiệu cần ưu tiên.',
            ),
          for (final student in attention.take(5))
            AttentionCard(
              student: student,
              contactLabel:
                  activeSupportRecord(data.interventions, student) == null
                  ? 'Ghi nhận hỗ trợ'
                  : 'Cập nhật theo dõi',
              onContact: () => showInterventionEditor(
                context,
                student: student,
                existing: activeSupportRecord(data.interventions, student),
              ),
            ),
          if (attention.length > 5)
            TextButton(
              onPressed: () => context.push('/teacher/interventions'),
              child: const Text('Xem tất cả lượt hỗ trợ'),
            ),
        ],
      );
    },
  );
}
