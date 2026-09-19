import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../courses/domain/course.dart';
import '../../../courses/domain/course_repository.dart';

/// Presents the progress values supplied for the student's enrolled courses.
///
/// This screen intentionally has no completion controls: it is a read-only
/// summary of the course data returned by [CourseRepository].
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(myCoursesProvider);
    await ref.read(myCoursesProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(myCoursesProvider);

    return courses.when(
      loading: () => const LoadingState(label: 'Đang tải tiến độ học tập…'),
      error: (error, _) => ErrorState(
        message: userMessageFor(error),
        onRetry: () => ref.invalidate(myCoursesProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            title: 'Chưa có khóa học',
            message: 'Tiến độ học tập sẽ xuất hiện khi bạn tham gia khóa học.',
            icon: Icons.auto_graph_rounded,
          );
        }

        final summary = _ProgressSummary.fromCourses(items);
        if (!summary.hasReportedProgress) {
          return const EmptyState(
            title: 'Chưa có dữ liệu tiến độ',
            message:
                'Tiến độ sẽ xuất hiện khi khóa học có thông tin hoàn thành.',
            icon: Icons.timeline_outlined,
          );
        }

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
                      child: const _ProgressHeader(),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.section,
                ),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: _ProgressOverview(summary: summary),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: Text(
                        'Theo từng khóa học',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
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
                  AppSpacing.xxl,
                ),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  itemBuilder: (context, index) => Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: _CourseProgressCard(course: items[index]),
                    ),
                  ),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.sm),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Tiến độ học tập',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        'Theo dõi mức độ hoàn thành của từng khóa học đang tham gia.',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ],
  );
}

class _ProgressOverview extends StatelessWidget {
  const _ProgressOverview({required this.summary});

  final _ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final averageLabel = _percentage(summary.average);

    return Semantics(
      label: 'Tổng quan tiến độ học tập',
      value:
          'Trung bình $averageLabel phần trăm trên ${summary.reportedCount} trong ${summary.totalCount} khóa học',
      child: Card(
        color: colors.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colors.onPrimaryContainer.withValues(
                      alpha: 0.1,
                    ),
                    foregroundColor: colors.onPrimaryContainer,
                    child: const Icon(Icons.auto_graph_rounded),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trung bình hoàn thành',
                          style: TextStyle(
                            color: colors.onPrimaryContainer.withValues(
                              alpha: 0.78,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '$averageLabel%',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                color: colors.onPrimaryContainer,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              LinearProgressIndicator(
                value: summary.average,
                minHeight: 8,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                color: colors.onPrimaryContainer,
                backgroundColor: colors.onPrimaryContainer.withValues(
                  alpha: 0.14,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${summary.reportedCount}/${summary.totalCount} khóa học đã có dữ liệu tiến độ',
                style: TextStyle(
                  color: colors.onPrimaryContainer.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseProgressCard extends StatelessWidget {
  const _CourseProgressCard({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = course.progress?.clamp(0.0, 1.0).toDouble();
    final percentage = progress == null ? null : _percentage(progress);
    final nextActivity = course.nextActivity?.trim();

    return Semantics(
      label: 'Tiến độ khóa học ${course.fullName}',
      value: percentage == null
          ? 'Chưa có dữ liệu tiến độ'
          : '$percentage phần trăm',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.shortName,
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          course.fullName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          course.category,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _ProgressValue(percentage: percentage),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (progress case final resolvedProgress?) ...[
                Semantics(
                  label: 'Mức độ hoàn thành',
                  value: '$percentage phần trăm',
                  child: LinearProgressIndicator(
                    value: resolvedProgress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ] else
                _NoProgressNotice(color: colors.onSurfaceVariant),
              if (nextActivity != null && nextActivity.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Tiếp theo: $nextActivity',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressValue extends StatelessWidget {
  const _ProgressValue({required this.percentage});

  final int? percentage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (percentage == null) {
      return Icon(
        Icons.info_outline_rounded,
        color: colors.onSurfaceVariant,
        semanticLabel: 'Chưa có dữ liệu tiến độ',
      );
    }

    return Text(
      '$percentage%',
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: colors.primary,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
      ),
    );
  }
}

class _NoProgressNotice extends StatelessWidget {
  const _NoProgressNotice({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(Icons.info_outline_rounded, size: 18, color: color),
      const SizedBox(width: AppSpacing.xs),
      Expanded(
        child: Text(
          'Chưa có dữ liệu tiến độ',
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}

class _ProgressSummary {
  const _ProgressSummary({
    required this.totalCount,
    required this.reportedCount,
    required this.average,
  });

  factory _ProgressSummary.fromCourses(List<Course> courses) {
    final reported = courses
        .where((course) => course.progress != null)
        .map((course) => course.progress!.clamp(0.0, 1.0).toDouble())
        .toList(growable: false);
    final average = reported.isEmpty
        ? 0.0
        : reported.reduce((sum, value) => sum + value) / reported.length;

    return _ProgressSummary(
      totalCount: courses.length,
      reportedCount: reported.length,
      average: average,
    );
  }

  final int totalCount;
  final int reportedCount;
  final double average;

  bool get hasReportedProgress => reportedCount > 0;
}

int _percentage(double value) => (value * 100).round();
