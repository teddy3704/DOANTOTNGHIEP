import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../courses/domain/course.dart';
import '../../../courses/domain/course_repository.dart';
import '../../domain/assignment.dart';
import '../../domain/assignment_repository.dart';

class AssignmentsScreen extends ConsumerStatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  ConsumerState<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends ConsumerState<AssignmentsScreen> {
  _AssignmentFilter _filter = _AssignmentFilter.all;

  void _retry() {
    ref.invalidate(upcomingAssignmentsProvider);
    ref.invalidate(myCoursesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final assignments = ref.watch(upcomingAssignmentsProvider);
    final courses = ref.watch(myCoursesProvider);

    return CustomScrollView(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          sliver: SliverToBoxAdapter(child: _AssignmentsHeader()),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: _AssignmentFilters(
              selected: _filter,
              onSelected: (value) => setState(() => _filter = value),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
        if (assignments.isLoading || courses.isLoading)
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            sliver: _AssignmentsLoading(),
          )
        else if (assignments.hasError || courses.hasError)
          SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorState(
              message: userMessageFor(assignments.error ?? courses.error!),
              onRetry: _retry,
            ),
          )
        else
          _AssignmentsList(
            assignments: _filteredAssignments(assignments.requireValue),
            courseById: {
              for (final course in courses.requireValue) course.id: course,
            },
            filter: _filter,
          ),
      ],
    );
  }

  List<AssignmentDetail> _filteredAssignments(
    List<AssignmentDetail> assignments,
  ) => assignments.where(_filter.matches).toList(growable: false);
}

class _AssignmentsHeader extends StatelessWidget {
  const _AssignmentsHeader();

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bài tập',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Theo dõi hạn nộp và kết quả đã được công bố.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class _AssignmentFilters extends StatelessWidget {
  const _AssignmentFilters({required this.selected, required this.onSelected});

  final _AssignmentFilter selected;
  final ValueChanged<_AssignmentFilter> onSelected;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in _AssignmentFilter.values) ...[
            ChoiceChip(
              label: Text(filter.label),
              selected: selected == filter,
              onSelected: (_) => onSelected(filter),
            ),
            if (filter != _AssignmentFilter.values.last)
              const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    ),
  );
}

class _AssignmentsList extends StatelessWidget {
  const _AssignmentsList({
    required this.assignments,
    required this.courseById,
    required this.filter,
  });

  final List<AssignmentDetail> assignments;
  final Map<String, Course> courseById;
  final _AssignmentFilter filter;

  @override
  Widget build(BuildContext context) {
    if (assignments.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          title: filter.emptyTitle,
          message: filter.emptyMessage,
          icon: filter.emptyIcon,
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
        itemCount: assignments.length,
        itemBuilder: (context, index) {
          final assignment = assignments[index];
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppLayout.maxContentWidth,
              ),
              child: _AssignmentCard(
                assignment: assignment,
                courseName:
                    courseById[assignment.courseId]?.fullName ??
                    'Khóa học chưa xác định',
              ),
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.assignment, required this.courseName});

  final AssignmentDetail assignment;
  final String courseName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final grade = assignment.grade;
    final gradeMax = assignment.gradeMax;
    final status = _statusVisual(assignment);

    return Semantics(
      button: true,
      label:
          '${assignment.name}, $courseName, ${_dueLabel(assignment.dueAt)}, ${assignment.submissionState.label}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(
            AppRoutes.assignment(assignment.courseId, assignment.id),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: status.backgroundColor(colors),
                      foregroundColor: status.foregroundColor(colors),
                      child: Icon(status.icon),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            assignment.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            courseName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _InfoPill(
                      icon: Icons.event_outlined,
                      label: _dueLabel(assignment.dueAt),
                    ),
                    _StatusPill(
                      label: assignment.submissionState.label,
                      visual: status,
                    ),
                    if (grade != null)
                      _GradePill(
                        label: gradeMax == null
                            ? 'Điểm ${_number(grade)}'
                            : 'Điểm ${_number(grade)} / ${_number(gradeMax)}',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colors.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xxs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.visual});

  final String label;
  final _StatusVisual visual;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: visual.backgroundColor(colors),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: visual.foregroundColor(colors),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _GradePill extends StatelessWidget {
  const _GradePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: colors.onPrimaryContainer,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _AssignmentsLoading extends StatelessWidget {
  const _AssignmentsLoading();

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
            label: index == 0 ? 'Đang tải bài tập…' : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (index == 0) ...[
                  Text(
                    'Đang tải bài tập…',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                Container(
                  height: 136,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
    );
  }
}

enum _AssignmentFilter {
  all('Tất cả'),
  upcoming('Sắp đến hạn'),
  submitted('Đã nộp'),
  notSubmitted('Chưa nộp'),
  overdue('Quá hạn');

  const _AssignmentFilter(this.label);

  final String label;

  bool matches(AssignmentDetail assignment) => switch (this) {
    _AssignmentFilter.all => true,
    _AssignmentFilter.upcoming =>
      assignment.timing == AssignmentTiming.future ||
          assignment.timing == AssignmentTiming.soon,
    _AssignmentFilter.submitted => switch (assignment.submissionState) {
      SubmissionState.submitted ||
      SubmissionState.late ||
      SubmissionState.graded => true,
      _ => false,
    },
    _AssignmentFilter.notSubmitted => switch (assignment.submissionState) {
      SubmissionState.notSubmitted ||
      SubmissionState.draft ||
      SubmissionState.returnedForResubmission ||
      SubmissionState.missing => true,
      _ => false,
    },
    _AssignmentFilter.overdue => assignment.timing == AssignmentTiming.overdue,
  };

  String get emptyTitle => switch (this) {
    _AssignmentFilter.all => 'Chưa có bài tập',
    _AssignmentFilter.upcoming => 'Chưa có bài tập sắp đến hạn',
    _AssignmentFilter.submitted => 'Chưa có bài tập đã nộp',
    _AssignmentFilter.notSubmitted => 'Không còn bài tập chưa nộp',
    _AssignmentFilter.overdue => 'Không có bài tập quá hạn',
  };

  String get emptyMessage => switch (this) {
    _AssignmentFilter.all => 'Bài tập của các khóa học sẽ xuất hiện tại đây.',
    _AssignmentFilter.upcoming =>
      'Bạn chưa có bài tập nào cần chú ý trong lúc này.',
    _AssignmentFilter.submitted =>
      'Các bài tập đã gửi sẽ được liệt kê tại đây.',
    _AssignmentFilter.notSubmitted =>
      'Bạn đã hoàn thành các bài tập đang hiển thị.',
    _AssignmentFilter.overdue => 'Không có bài tập nào đã qua hạn nộp.',
  };

  IconData get emptyIcon => switch (this) {
    _AssignmentFilter.all => Icons.assignment_outlined,
    _AssignmentFilter.upcoming => Icons.event_available_outlined,
    _AssignmentFilter.submitted => Icons.assignment_turned_in_outlined,
    _AssignmentFilter.notSubmitted => Icons.task_alt_rounded,
    _AssignmentFilter.overdue => Icons.event_busy_outlined,
  };
}

class _StatusVisual {
  const _StatusVisual({
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final Color Function(ColorScheme colors) backgroundColor;
  final Color Function(ColorScheme colors) foregroundColor;
}

_StatusVisual _statusVisual(AssignmentDetail assignment) {
  if (assignment.submissionState == SubmissionState.graded) {
    return _StatusVisual(
      icon: Icons.verified_outlined,
      backgroundColor: (colors) => colors.secondaryContainer,
      foregroundColor: (colors) => colors.onSecondaryContainer,
    );
  }
  if (assignment.timing == AssignmentTiming.overdue ||
      assignment.submissionState == SubmissionState.late ||
      assignment.submissionState == SubmissionState.missing) {
    return _StatusVisual(
      icon: Icons.priority_high_rounded,
      backgroundColor: (colors) => colors.errorContainer,
      foregroundColor: (colors) => colors.onErrorContainer,
    );
  }
  if (assignment.submissionState == SubmissionState.submitted) {
    return _StatusVisual(
      icon: Icons.assignment_turned_in_outlined,
      backgroundColor: (colors) => colors.tertiaryContainer,
      foregroundColor: (colors) => colors.onTertiaryContainer,
    );
  }
  return _StatusVisual(
    icon: Icons.assignment_outlined,
    backgroundColor: (colors) => colors.primaryContainer,
    foregroundColor: (colors) => colors.onPrimaryContainer,
  );
}

String _dueLabel(DateTime? dueAt) {
  if (dueAt == null) return 'Chưa đặt hạn';
  final date = dueAt.year == DateTime.now().year
      ? '${dueAt.day.toString().padLeft(2, '0')}/${dueAt.month.toString().padLeft(2, '0')}'
      : '${dueAt.day.toString().padLeft(2, '0')}/${dueAt.month.toString().padLeft(2, '0')}/${dueAt.year}';
  return 'Hạn $date lúc ${dueAt.hour.toString().padLeft(2, '0')}:${dueAt.minute.toString().padLeft(2, '0')}';
}

String _number(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);
