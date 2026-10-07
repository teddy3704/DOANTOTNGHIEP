import 'package:flutter/material.dart';
import 'widgets/intervention_editor_sheet.dart';
import 'widgets/intervention_widgets.dart';
import 'widgets/teacher_support_body.dart';

class StudentAttentionDetailScreen extends StatelessWidget {
  const StudentAttentionDetailScreen({
    required this.courseId,
    required this.studentId,
    super.key,
  });
  final String courseId, studentId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Quá trình hỗ trợ')),
    body: TeacherSupportBody(
      builder: (data) {
        final students = data.attention.where(
          (s) => s.courseId == courseId && s.studentId == studentId,
        );
        if (students.isEmpty) {
          return const InterventionBody(
            children: [
              SupportEmpty(
                'Không tìm thấy sinh viên',
                'Sinh viên không thuộc phạm vi học phần hiện tại hoặc dữ liệu đã thay đổi.',
              ),
            ],
          );
        }
        final student = students.first;
        final records =
            data.interventions
                .where(
                  (r) => r.courseId == courseId && r.studentId == studentId,
                )
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final activeRecord = activeSupportRecord(records, student);
        return InterventionBody(
          children: [
            InterventionHeading(
              student.studentName,
              subtitle: student.courseName,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: AttentionBadge(student.priority),
            ),
            const SizedBox(height: 20),
            SnapshotMetrics(snapshot: student.snapshot),
            const SizedBox(height: 24),
            Text(
              'Vì sao cần chú ý?',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (final reason in student.reasons)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('• $reason', style: const TextStyle(height: 1.5)),
              ),
            const SizedBox(height: 8),
            const Text(
              'Chỉ số phản ánh dữ liệu học tập hiện có, không kết luận nguyên nhân hoặc hiệu quả của việc hỗ trợ.',
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => showInterventionEditor(
                context,
                student: student,
                existing: activeRecord,
              ),
              icon: const Icon(Icons.note_add_outlined),
              label: Text(
                activeRecord == null ? 'Ghi nhận hỗ trợ' : 'Cập nhật theo dõi',
              ),
            ),
            const SizedBox(height: 28),
            const InterventionHeading('Lịch sử và kết quả'),
            if (records.isEmpty)
              const SupportEmpty(
                'Chưa có lượt hỗ trợ',
                'Ghi lại hành động đã thực hiện để theo dõi tiến độ ở lần tiếp theo.',
              ),
            for (final record in records)
              InterventionRecordCard(
                record: record,
                showStudent: false,
                onFollowup: () =>
                    showInterventionEditor(context, existing: record),
              ),
          ],
        );
      },
    ),
  );
}
