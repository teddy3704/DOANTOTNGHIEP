import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/widgets/content_skeleton.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../assignments/domain/assignment.dart';
import '../../../assignments/domain/assignment_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../calendar/domain/calendar_repository.dart';
import '../../../calendar/domain/learning_event.dart';
import '../../../courses/domain/course.dart';
import '../../../courses/domain/course_repository.dart';
import '../../../courses/presentation/widgets/course_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(myCoursesProvider);
    ref.invalidate(upcomingAssignmentsProvider);
    ref.invalidate(upcomingEventsProvider);
    await Future.wait<void>([
      ref.read(myCoursesProvider.future).then((_) {}),
      ref.read(upcomingAssignmentsProvider.future).then((_) {}),
      ref.read(upcomingEventsProvider.future).then((_) {}),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final courses = ref.watch(myCoursesProvider);
    final assignments = ref.watch(upcomingAssignmentsProvider);
    final events = ref.watch(upcomingEventsProvider);
    final courseById = <String, Course>{
      for (final course in courses.asData?.value ?? const <Course>[])
        course.id: course,
    };
    final firstName = _greetingName(auth.session?.displayName);

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppLayout.maxContentWidth,
                  ),
                  child: _Greeting(firstName: firstName),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppLayout.maxContentWidth,
                  ),
                  child: SectionHeader(
                    title: 'Việc cần ưu tiên',
                    subtitle: 'Theo dõi các bài tập gần hạn nộp.',
                    action: TextButton(
                      onPressed: () => context.go(AppRoutes.assignments),
                      child: const Text('Xem tất cả'),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppLayout.maxContentWidth,
                  ),
                  child: _PriorityAssignments(
                    assignments: assignments,
                    courseById: courseById,
                    onRetry: () => ref.invalidate(upcomingAssignmentsProvider),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.section,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppLayout.maxContentWidth,
                  ),
                  child: SectionHeader(
                    title: 'Khóa học hiện tại',
                    subtitle: 'Tiếp tục từ nội dung bạn đang học.',
                    action: TextButton(
                      onPressed: () => context.go(AppRoutes.courses),
                      child: const Text('Xem tất cả'),
                    ),
                  ),
                ),
              ),
            ),
          ),
          courses.when(
            loading: () => SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppLayout.maxContentWidth,
                  ),
                  child: const ContentSkeleton(rows: 2, rowHeight: 164),
                ),
              ),
            ),
            error: (error, _) => SliverToBoxAdapter(
              child: _DashboardNotice(
                message: userMessageFor(error),
                onRetry: () => ref.invalidate(myCoursesProvider),
              ),
            ),
            data: (items) => items.isEmpty
                ? const SliverToBoxAdapter(
                    child: _DashboardNotice(
                      message: 'Bạn chưa có khóa học nào trong học kỳ này.',
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.crossAxisExtent >= 1050
                            ? 3
                            : constraints.crossAxisExtent >= 680
                            ? 2
                            : 1;
                        return SliverGrid.builder(
                          itemCount: items.take(3).length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: AppSpacing.md,
                                mainAxisSpacing: AppSpacing.md,
                                mainAxisExtent: 220,
                              ),
                          itemBuilder: (context, index) {
                            final course = items[index];
                            return CourseCard(
                              course: course,
                              onTap: () =>
                                  context.push(AppRoutes.course(course.id)),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.section,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppLayout.maxContentWidth,
                  ),
                  child: SectionHeader(
                    title: 'Lịch sắp tới',
                    subtitle: 'Những mốc học tập trong thời gian gần nhất.',
                    action: TextButton(
                      onPressed: () => context.push(AppRoutes.calendar),
                      child: const Text('Xem lịch'),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppLayout.maxContentWidth,
                  ),
                  child: _UpcomingEvents(
                    events: events,
                    courseById: courseById,
                    onRetry: () => ref.invalidate(upcomingEventsProvider),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _greetingName(String? displayName) {
  final normalized = displayName?.trim() ?? '';
  if (normalized.isEmpty) return 'bạn';
  final parts = normalized.split(RegExp(r'\s+'));
  final last = parts.last;
  if (RegExp(r'^\d+$').hasMatch(last)) {
    return parts.length == 1 ? 'bạn' : parts.take(parts.length - 1).join(' ');
  }
  return last;
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xin chào, $firstName',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Sẵn sàng cho một ngày học hiệu quả?',
                    style: TextStyle(
                      color: colors.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Icon(
              Icons.school_rounded,
              size: 48,
              color: colors.onPrimaryContainer.withValues(alpha: 0.65),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityAssignments extends StatelessWidget {
  const _PriorityAssignments({
    required this.assignments,
    required this.courseById,
    required this.onRetry,
  });

  final AsyncValue<List<AssignmentDetail>> assignments;
  final Map<String, Course> courseById;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => assignments.when(
    loading: () =>
        const ContentSkeleton(rows: 2, rowHeight: 92, padding: EdgeInsets.zero),
    error: (error, _) =>
        _InlineNotice(message: userMessageFor(error), onRetry: onRetry),
    data: (items) {
      final visible = items
          .where((item) => item.submissionState != SubmissionState.graded)
          .take(3)
          .toList();
      if (visible.isEmpty) {
        return const _InlineNotice(
          message: 'Bạn không có bài tập nào cần xử lý ngay.',
          icon: Icons.task_alt_rounded,
        );
      }
      return Card(
        child: Column(
          children: [
            for (var index = 0; index < visible.length; index++) ...[
              _AssignmentRow(
                assignment: visible[index],
                courseName: courseById[visible[index].courseId]?.shortName,
              ),
              if (index < visible.length - 1) const Divider(indent: 68),
            ],
          ],
        ),
      );
    },
  );
}

class _AssignmentRow extends StatelessWidget {
  const _AssignmentRow({required this.assignment, this.courseName});

  final AssignmentDetail assignment;
  final String? courseName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isOverdue = assignment.timing == AssignmentTiming.overdue;
    return Semantics(
      button: true,
      label:
          '${assignment.name}, ${courseName ?? 'Khóa học'}, ${_deadlineLabel(assignment.dueAt)}',
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: CircleAvatar(
          backgroundColor: isOverdue
              ? colors.errorContainer
              : colors.secondaryContainer,
          foregroundColor: isOverdue
              ? colors.onErrorContainer
              : colors.onSecondaryContainer,
          child: Icon(
            isOverdue ? Icons.priority_high_rounded : Icons.assignment_outlined,
          ),
        ),
        title: Text(
          assignment.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          [
            ?courseName,
            _deadlineLabel(assignment.dueAt),
            assignment.submissionState.label,
          ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push(
          AppRoutes.assignment(assignment.courseId, assignment.id),
        ),
      ),
    );
  }
}

class _UpcomingEvents extends StatelessWidget {
  const _UpcomingEvents({
    required this.events,
    required this.courseById,
    required this.onRetry,
  });

  final AsyncValue<List<LearningEvent>> events;
  final Map<String, Course> courseById;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => events.when(
    loading: () =>
        const ContentSkeleton(rows: 2, rowHeight: 84, padding: EdgeInsets.zero),
    error: (error, _) =>
        _InlineNotice(message: userMessageFor(error), onRetry: onRetry),
    data: (items) {
      final visible = items.take(3).toList();
      if (visible.isEmpty) {
        return const _InlineNotice(
          message: 'Chưa có lịch học sắp tới.',
          icon: Icons.event_available_rounded,
        );
      }
      return Card(
        child: Column(
          children: [
            for (var index = 0; index < visible.length; index++) ...[
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                leading: _DateBadge(date: visible[index].startsAt),
                title: Text(
                  visible[index].name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  [
                    ?courseById[visible[index].courseId]?.shortName,
                    _dateTimeLabel(visible[index].startsAt),
                  ].join(' · '),
                ),
              ),
              if (index < visible.length - 1) const Divider(indent: 76),
            ],
          ],
        ),
      );
    },
  );
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 46,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            date.day.toString().padLeft(2, '0'),
            style: TextStyle(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'TH${date.month}',
            style: TextStyle(
              color: colors.onPrimaryContainer,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message, this.onRetry, this.icon});

  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(icon ?? Icons.info_outline_rounded),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message)),
          if (onRetry != null)
            IconButton(
              tooltip: 'Thử lại',
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
    ),
  );
}

class _DashboardNotice extends StatelessWidget {
  const _DashboardNotice({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: _InlineNotice(message: message, onRetry: onRetry),
      ),
    ),
  );
}

String _deadlineLabel(DateTime dueAt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(dueAt.year, dueAt.month, dueAt.day);
  final days = dueDay.difference(today).inDays;
  if (days < -1) return 'Quá hạn ${-days} ngày';
  if (days == -1) return 'Quá hạn 1 ngày';
  if (days == 0) return 'Hạn hôm nay';
  if (days == 1) return 'Hạn ngày mai';
  if (days <= 7) return 'Còn $days ngày';
  return 'Hạn ${_shortDate(dueAt)}';
}

String _dateTimeLabel(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}, ${_shortDate(value)}';

String _shortDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';
