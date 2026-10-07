import 'package:flutter/material.dart';
import '../domain/intervention_models.dart';
import 'widgets/intervention_editor_sheet.dart';
import 'widgets/intervention_widgets.dart';
import 'widgets/teacher_support_body.dart';

enum _InboxFilter { attention, due, active, resolved, all }

class InterventionInboxScreen extends StatefulWidget {
  const InterventionInboxScreen({this.clock, super.key});
  final DateTime Function()? clock;
  @override
  State<InterventionInboxScreen> createState() =>
      _InterventionInboxScreenState();
}

class _InterventionInboxScreenState extends State<InterventionInboxScreen> {
  _InboxFilter _filter = _InboxFilter.attention;
  String _query = '';
  bool _matches(String name, String course) =>
      '$name $course'.toLowerCase().contains(_query.trim().toLowerCase());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sổ theo dõi hỗ trợ')),
    body: TeacherSupportBody(
      builder: (data) {
        final attention = data.attention
            .where(
              (s) => s.needsAttention && _matches(s.studentName, s.courseName),
            )
            .toList();
        final records =
            data.interventions
                .where(
                  (r) =>
                      _matches(r.studentName, r.courseName) &&
                      switch (_filter) {
                        _InboxFilter.due => r.isDue(
                          widget.clock?.call() ?? DateTime.now(),
                        ),
                        _InboxFilter.active =>
                          r.status != InterventionStatus.resolved,
                        _InboxFilter.resolved =>
                          r.status == InterventionStatus.resolved,
                        _ => true,
                      },
                )
                .toList()
              ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return InterventionBody(
          children: [
            const InterventionHeading(
              'Một nơi để theo dõi',
              subtitle:
                  'Ghi nhận hành động, xem lịch hẹn và quá trình hỗ trợ trong học phần phụ trách.',
            ),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Tìm sinh viên hoặc học phần',
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final filter in _InboxFilter.values)
                  ChoiceChip(
                    label: Text(switch (filter) {
                      _InboxFilter.attention => 'Cần chú ý',
                      _InboxFilter.due => 'Đến hạn',
                      _InboxFilter.active => 'Đang theo dõi',
                      _InboxFilter.resolved => 'Đã khép lại',
                      _InboxFilter.all => 'Lịch sử',
                    }),
                    selected: _filter == filter,
                    onSelected: (_) => setState(() => _filter = filter),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            if (_filter == _InboxFilter.attention) ...[
              if (attention.isEmpty)
                const SupportEmpty(
                  'Không có sinh viên phù hợp',
                  'Thử tìm tên khác hoặc kéo xuống để cập nhật dữ liệu.',
                ),
              for (final student in attention)
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
            ] else ...[
              if (records.isEmpty)
                const SupportEmpty(
                  'Chưa có ghi nhận phù hợp',
                  'Bạn có thể ghi nhận hỗ trợ từ chi tiết sinh viên và hẹn theo dõi lại.',
                ),
              for (final record in records)
                InterventionRecordCard(
                  record: record,
                  onFollowup: () =>
                      showInterventionEditor(context, existing: record),
                ),
            ],
          ],
        );
      },
    ),
  );
}
