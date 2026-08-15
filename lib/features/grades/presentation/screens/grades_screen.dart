import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../courses/domain/course_repository.dart';
import '../../domain/grade_entry.dart';
import '../../domain/grade_repository.dart';

class GradesScreen extends ConsumerWidget {
  const GradesScreen({required this.courseId, super.key});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(courseDetailProvider(courseId)).asData?.value;
    final grades = ref.watch(courseGradesProvider(courseId));
    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả học tập')),
      body: grades.when(
        loading: () => const LoadingState(label: 'Đang tải điểm…'),
        error: (error, _) => ErrorState(
          message: userMessageFor(error),
          onRetry: () => ref.invalidate(courseGradesProvider(courseId)),
        ),
        data: (items) => items.isEmpty
            ? const EmptyState(
                title: 'Chưa có mục điểm',
                message:
                    'Các mục điểm được phép hiển thị sẽ xuất hiện tại đây.',
                icon: Icons.insights_outlined,
              )
            : _GradesContent(
                courseName: course?.fullName ?? 'Khóa học mẫu',
                grades: items,
              ),
      ),
    );
  }
}

class _GradesContent extends StatelessWidget {
  const _GradesContent({required this.courseName, required this.grades});

  final String courseName;
  final List<GradeEntry> grades;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final graded = grades.where((entry) => entry.fraction != null).toList();
    final average = graded.isEmpty
        ? null
        : graded.map((entry) => entry.fraction!).reduce((a, b) => a + b) /
              graded.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: colors.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          child: Icon(Icons.insights_rounded),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                courseName,
                                style: TextStyle(
                                  color: colors.onPrimaryContainer,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                average == null
                                    ? 'Chưa có điểm tổng hợp'
                                    : 'Trung bình các mục đã chấm: ${(average * 100).toStringAsFixed(1)}%',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: colors.onPrimaryContainer,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Chỉ số DEV được tính cục bộ từ fixture, không phải kết quả chính thức.',
                                style: TextStyle(
                                  color: colors.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                for (final grade in grades) ...[
                  _GradeTile(grade: grade),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GradeTile extends StatelessWidget {
  const _GradeTile({required this.grade});

  final GradeEntry grade;

  @override
  Widget build(BuildContext context) {
    final value = grade.finalGrade;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              child: Text(
                value == null ? '—' : _number(value),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grade.itemName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value == null
                        ? 'Chưa chấm'
                        : '${_number(value)} / ${_number(grade.maximum)}',
                  ),
                  if (grade.feedback case final feedback?) ...[
                    const SizedBox(height: 5),
                    Text(
                      feedback,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (grade.fraction case final fraction?)
              SizedBox(
                width: 54,
                height: 54,
                child: CircularProgressIndicator(
                  value: fraction,
                  strokeWidth: 6,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _number(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);
