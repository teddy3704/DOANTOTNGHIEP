import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/failure_message.dart';
import '../../../core/external_links/official_lms_button.dart';
import '../../../core/widgets/content_skeleton.dart';
import '../../../core/widgets/error_state.dart';
import '../domain/teacher_support_repository.dart';

class TeacherStudentsScreen extends ConsumerStatefulWidget {
  const TeacherStudentsScreen({required this.courseId, super.key});
  final String courseId;
  @override
  ConsumerState<TeacherStudentsScreen> createState() =>
      _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends ConsumerState<TeacherStudentsScreen> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final provider = teacherStudentsProvider(widget.courseId);
    final students = ref.watch(provider);
    return Scaffold(
      appBar: AppBar(title: const Text('Theo dõi sinh viên')),
      body: students.when(
        loading: () => const ContentSkeleton(rows: 4, rowHeight: 100),
        error: (error, _) => ErrorState(
          message: userMessageFor(error),
          onRetry: () => ref.invalidate(provider),
        ),
        data: (data) {
          final matches = data
              .where(
                (s) =>
                    s.name.toLowerCase().contains(_query.trim().toLowerCase()),
              )
              .toList();
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(provider);
              await ref.read(provider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  '${data.length} sinh viên trong học phần',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Chỉ báo hỗ trợ dựa trên quy tắc, không phải đánh giá học lực hay quyết định học vụ.',
                ),
                const SizedBox(height: 20),
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Tìm tên sinh viên',
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 16),
                if (matches.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'Không có sinh viên phù hợp.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (final student in matches) ...[
                  _StudentCard(student: student),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 12),
                const OfficialLmsButton(label: 'Mở LMS'),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student});
  final StudentMonitoring student;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (label, color) = switch (student.supportLevel) {
      LearningSupportLevel.low => ('Theo dõi thường kỳ', colors.primary),
      LearningSupportLevel.medium => ('Nên nhắc tiến độ', colors.tertiary),
      LearningSupportLevel.high => ('Ưu tiên hỗ trợ', colors.error),
    };
    final initials = student.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p.characters.first)
        .join();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: CircleAvatar(child: Text(initials)),
        title: Text(
          student.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(label, style: TextStyle(color: color)),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Tiến độ: ${student.progressPercent.toStringAsFixed(0)}%',
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: student.progressPercent / 100,
            minHeight: 7,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('${student.pendingTasks} việc đang chờ')),
                Chip(label: Text('${student.overdueTasks} việc quá hạn')),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kết quả học tập và thao tác chấm bài được quản lý trên LMS.',
          ),
        ],
      ),
    );
  }
}
