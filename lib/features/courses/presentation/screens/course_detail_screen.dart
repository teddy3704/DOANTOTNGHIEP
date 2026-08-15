import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../domain/course.dart';
import '../../domain/course_content.dart';
import '../../domain/course_content_repository.dart';
import '../../domain/course_repository.dart';

class CourseDetailScreen extends ConsumerWidget {
  const CourseDetailScreen({required this.courseId, super.key});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(courseDetailProvider(courseId));
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết khóa học')),
      body: detail.when(
        loading: () => const LoadingState(label: 'Đang tải khóa học…'),
        error: (error, _) => ErrorState(
          message: userMessageFor(error),
          onRetry: () => ref.invalidate(courseDetailProvider(courseId)),
        ),
        data: (course) => _CourseDetailContent(course: course),
      ),
    );
  }
}

class _CourseDetailContent extends ConsumerWidget {
  const _CourseDetailContent({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final sections = ref.watch(courseSectionsProvider(course.id));
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(courseDetailProvider(course.id));
        ref.invalidate(courseSectionsProvider(course.id));
        await ref.read(courseSectionsProvider(course.id).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colors.primary, colors.tertiary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(26),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  course.shortName,
                                  style: TextStyle(
                                    color: colors.onPrimary.withValues(
                                      alpha: 0.8,
                                    ),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  course.fullName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: colors.onPrimary,
                                        fontWeight: FontWeight.w900,
                                        height: 1.25,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  course.category,
                                  style: TextStyle(
                                    color: colors.onPrimary.withValues(
                                      alpha: 0.82,
                                    ),
                                  ),
                                ),
                                if (course.summary case final summary?) ...[
                                  const SizedBox(height: 14),
                                  Text(
                                    summary,
                                    style: TextStyle(
                                      color: colors.onPrimary.withValues(
                                        alpha: 0.88,
                                      ),
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            Icons.auto_stories_rounded,
                            size: 62,
                            color: colors.onPrimary.withValues(alpha: 0.2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.grades(course.id)),
                    icon: const Icon(Icons.insights_rounded),
                    label: const Text('Xem điểm khóa học'),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Nội dung khóa học',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Sections và activities dưới đây dùng canonical SYNTHETIC DATA trong DEV.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),
                  sections.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 36),
                      child: LoadingState(label: 'Đang tải nội dung…'),
                    ),
                    error: (error, _) => ErrorState(
                      message: userMessageFor(error),
                      onRetry: () =>
                          ref.invalidate(courseSectionsProvider(course.id)),
                    ),
                    data: (items) => items.isEmpty
                        ? const EmptyState(
                            title: 'Chưa có nội dung',
                            message:
                                'Khóa học mẫu chưa có section hoặc activity.',
                            icon: Icons.folder_open_outlined,
                          )
                        : Column(
                            children: [
                              for (var index = 0; index < items.length; index++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _SectionCard(
                                    section: items[index],
                                    initiallyExpanded: index == 0,
                                  ),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section, required this.initiallyExpanded});

  final CourseSection section;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      leading: CircleAvatar(
        child: Text(
          section.number.toString().padLeft(2, '0'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      title: Text(
        section.name,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text('${section.activities.length} hoạt động'),
      children: [
        if (section.summary case final summary?)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Align(alignment: Alignment.centerLeft, child: Text(summary)),
          ),
        if (section.activities.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Section này chưa có hoạt động.'),
            ),
          )
        else
          for (final activity in section.activities)
            _ActivityTile(courseId: section.courseId, activity: activity),
      ],
    ),
  );
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.courseId, required this.activity});

  final String courseId;
  final CourseActivity activity;

  @override
  Widget build(BuildContext context) {
    final assignment = activity.kind == CourseActivityKind.assignment;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: CircleAvatar(
        backgroundColor: assignment
            ? Theme.of(context).colorScheme.secondaryContainer
            : Theme.of(context).colorScheme.tertiaryContainer,
        child: Icon(
          assignment ? Icons.assignment_outlined : Icons.description_outlined,
        ),
      ),
      title: Text(
        activity.name,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: activity.statusLabel == null
          ? Text(activity.fileName ?? 'Tài nguyên học tập')
          : Text(
              '${activity.statusLabel} · Hạn ${_formatDate(activity.dueAt!)}',
            ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: assignment
          ? () => context.push(
              AppRoutes.assignment(courseId, activity.instanceId),
            )
          : () => _showResource(context, activity),
    );
  }

  void _showResource(BuildContext context, CourseActivity activity) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.description_rounded, size: 40),
              const SizedBox(height: 14),
              Text(
                activity.name,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              if (activity.description case final description?) ...[
                const SizedBox(height: 8),
                Text(description),
              ],
              const SizedBox(height: 18),
              _ResourceMeta(
                label: 'Tệp mẫu',
                value: activity.fileName ?? 'Không có metadata tệp',
              ),
              _ResourceMeta(
                label: 'Định dạng',
                value: activity.mimeType ?? 'Không xác định',
              ),
              _ResourceMeta(
                label: 'Kích thước',
                value: _formatBytes(activity.fileSize),
              ),
              const SizedBox(height: 12),
              Text(
                'DEV fixture chỉ hiển thị metadata synthetic; không tải tệp DLU thật.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResourceMeta extends StatelessWidget {
  const _ResourceMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _formatBytes(int? bytes) {
  if (bytes == null) return 'Không xác định';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
