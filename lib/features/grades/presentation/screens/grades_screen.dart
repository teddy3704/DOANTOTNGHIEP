import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
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
        loading: () => const _GradesLoading(),
        error: (error, _) => ErrorState(
          message: userMessageFor(error),
          onRetry: () => ref.invalidate(courseGradesProvider(courseId)),
        ),
        data: (items) {
          final visible = items
              .where((entry) => !entry.hidden)
              .toList(growable: false);
          if (visible.isEmpty) {
            return const EmptyState(
              title: 'Chưa có kết quả',
              message: 'Điểm được công bố sẽ xuất hiện tại đây.',
              icon: Icons.school_outlined,
            );
          }
          return _GradesContent(
            courseName: course?.fullName ?? 'Điểm khóa học',
            grades: visible,
          );
        },
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
    final releasedCount = grades
        .where((entry) => entry.finalGrade != null)
        .length;
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: colors.onPrimaryContainer.withValues(
                            alpha: 0.1,
                          ),
                          foregroundColor: colors.onPrimaryContainer,
                          child: const Icon(Icons.school_rounded),
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
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                releasedCount == 0
                                    ? 'Chưa có điểm được công bố'
                                    : '$releasedCount/${grades.length} kết quả đã công bố',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
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
                const SizedBox(height: 24),
                Text(
                  'Các mục đánh giá',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
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
    final colors = Theme.of(context).colorScheme;
    final value = grade.finalGrade;
    return Semantics(
      label: value == null
          ? '${grade.itemName}, chưa có điểm'
          : '${grade.itemName}, ${_number(value)} trên ${_number(grade.maximum)} điểm',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: value == null
                    ? colors.surfaceContainerHighest
                    : colors.secondaryContainer,
                foregroundColor: value == null
                    ? colors.onSurfaceVariant
                    : colors.onSecondaryContainer,
                child: Icon(
                  value == null
                      ? Icons.hourglass_empty_rounded
                      : Icons.check_rounded,
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
                    const SizedBox(height: 7),
                    Text(
                      value == null
                          ? 'Chưa có điểm'
                          : '${_number(value)} / ${_number(grade.maximum)} điểm',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: value == null
                            ? colors.onSurfaceVariant
                            : colors.primary,
                      ),
                    ),
                    if (grade.feedback case final feedback?) ...[
                      const SizedBox(height: 8),
                      Text(
                        feedback,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradesLoading extends StatelessWidget {
  const _GradesLoading();

  @override
  Widget build(BuildContext context) {
    final skeletonColor = Theme.of(context).colorScheme.surfaceContainerHigh;
    return Semantics(
      liveRegion: true,
      label: 'Đang tải điểm…',
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
                    height: 124,
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Đang tải điểm…',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (var index = 0; index < 3; index++) ...[
                    Container(
                      height: 104,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _number(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);
