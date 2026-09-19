import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/external_links/official_lms_launcher.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
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
        loading: () => const _CourseDetailLoading(),
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
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colors.primaryContainer,
                            Color.alphaBlend(
                              colors.primary.withValues(alpha: 0.08),
                              colors.primaryContainer,
                            ),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
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
                                      color: colors.onPrimaryContainer
                                          .withValues(alpha: 0.8),
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
                                          color: colors.onPrimaryContainer,
                                          fontWeight: FontWeight.w900,
                                          height: 1.25,
                                        ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    course.category,
                                    style: TextStyle(
                                      color: colors.onPrimaryContainer
                                          .withValues(alpha: 0.82),
                                    ),
                                  ),
                                  if (course.summary case final summary?) ...[
                                    const SizedBox(height: 14),
                                    Text(
                                      summary,
                                      style: TextStyle(
                                        color: colors.onPrimaryContainer
                                            .withValues(alpha: 0.88),
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.auto_stories_rounded,
                              size: 54,
                              color: colors.onPrimaryContainer.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: colors.secondaryContainer,
                            foregroundColor: colors.onSecondaryContainer,
                            child: const Icon(Icons.insights_rounded),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kết quả học tập',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                                SizedBox(height: 3),
                                Text('Xem các điểm đã được công bố'),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            tooltip: 'Xem điểm khóa học',
                            onPressed: () =>
                                context.push(AppRoutes.grades(course.id)),
                            icon: const Icon(Icons.arrow_forward_rounded),
                          ),
                        ],
                      ),
                    ),
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
                    'Tài liệu và bài tập được sắp xếp theo từng chủ đề.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),
                  sections.when(
                    loading: () => const _ContentLoadingSkeleton(),
                    error: (error, _) => ErrorState(
                      message: userMessageFor(error),
                      onRetry: () =>
                          ref.invalidate(courseSectionsProvider(course.id)),
                    ),
                    data: (items) => items.isEmpty
                        ? const EmptyState(
                            title: 'Chưa có nội dung',
                            message: 'Nội dung môn học sẽ xuất hiện tại đây.',
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
      subtitle: Text(_contentCountLabel(section.activities.length)),
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
              child: Text('Chủ đề này chưa có nội dung.'),
            ),
          )
        else
          for (final activity in section.activities)
            _ActivityTile(courseId: section.courseId, activity: activity),
      ],
    ),
  );
}

class _ActivityTile extends ConsumerWidget {
  const _ActivityTile({required this.courseId, required this.activity});

  final String courseId;
  final CourseActivity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignment = activity.kind == CourseActivityKind.assignment;
    final subtitle = <String>[assignment ? 'Bài tập' : 'Tài liệu'];
    final status = activity.statusLabel;
    if (status != null) subtitle.add(status);
    final dueAt = activity.dueAt;
    if (assignment && dueAt != null) {
      subtitle.add('Hạn ${_formatDate(dueAt)}');
    }
    final fileName = activity.fileName;
    if (!assignment && fileName != null) subtitle.add(fileName);
    return Semantics(
      button: true,
      label: '${assignment ? 'Mở bài tập' : 'Xem tài liệu'} ${activity.name}',
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        leading: CircleAvatar(
          backgroundColor: assignment
              ? Theme.of(context).colorScheme.secondaryContainer
              : Theme.of(context).colorScheme.tertiaryContainer,
          foregroundColor: assignment
              ? Theme.of(context).colorScheme.onSecondaryContainer
              : Theme.of(context).colorScheme.onTertiaryContainer,
          child: Icon(
            assignment ? Icons.assignment_outlined : Icons.description_outlined,
          ),
        ),
        title: Text(
          activity.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(subtitle.join(' · ')),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: assignment
            ? () => context.push(
                AppRoutes.assignment(courseId, activity.instanceId),
              )
            : () => _showResource(
                context,
                activity,
                ref.read(officialLmsLauncherProvider),
              ),
      ),
    );
  }

  void _showResource(
    BuildContext context,
    CourseActivity activity,
    OfficialLmsLauncher lmsLauncher,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final screenHeight = MediaQuery.sizeOf(context).height;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: screenHeight * 0.78),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.tertiaryContainer,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onTertiaryContainer,
                        child: const Icon(Icons.description_rounded),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Đóng',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    activity.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (activity.description case final description?) ...[
                    const SizedBox(height: 8),
                    Text(description),
                  ],
                  if (activity.fileName != null ||
                      activity.mimeType != null ||
                      activity.fileSize != null) ...[
                    const SizedBox(height: 22),
                    Text(
                      'Thông tin tài liệu',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (activity.fileName case final fileName?)
                      _ResourceMeta(label: 'Tên tệp', value: fileName),
                    if (activity.mimeType case final mimeType?)
                      _ResourceMeta(
                        label: 'Định dạng',
                        value: _friendlyFileType(mimeType),
                      ),
                    if (activity.fileSize case final fileSize?)
                      _ResourceMeta(
                        label: 'Dung lượng',
                        value: _formatBytes(fileSize),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: () async {
                          try {
                            await lmsLauncher.openHome();
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(userMessageFor(error))),
                            );
                          }
                        },
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('Mở LMS'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tài liệu chính thức được mở an toàn trên DLU LMS.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ResourceMeta extends StatelessWidget {
  const _ResourceMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
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

class _CourseDetailLoading extends StatelessWidget {
  const _CourseDetailLoading();

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: 'Đang tải khóa học…',
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LoadingBlock(height: 190),
                SizedBox(height: 16),
                Text('Đang tải khóa học…'),
                SizedBox(height: 16),
                _LoadingBlock(height: 86),
                SizedBox(height: 24),
                _LoadingBlock(height: 132),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _ContentLoadingSkeleton extends StatelessWidget {
  const _ContentLoadingSkeleton();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      _LoadingBlock(height: 122),
      SizedBox(height: 12),
      _LoadingBlock(height: 122),
    ],
  );
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(20),
    ),
    child: SizedBox(height: height),
  );
}

String _contentCountLabel(int count) => switch (count) {
  0 => 'Chưa có nội dung',
  1 => '1 nội dung',
  _ => '$count nội dung',
};

String _friendlyFileType(String mimeType) {
  final normalized = mimeType.toLowerCase();
  if (normalized.contains('pdf')) return 'PDF';
  if (normalized.contains('word') || normalized.contains('document')) {
    return 'Tài liệu Word';
  }
  if (normalized.contains('presentation') ||
      normalized.contains('powerpoint')) {
    return 'Bài trình chiếu';
  }
  if (normalized.startsWith('image/')) return 'Hình ảnh';
  if (normalized.startsWith('video/')) return 'Video';
  if (normalized.startsWith('audio/')) return 'Âm thanh';
  return 'Tệp tài liệu';
}

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
