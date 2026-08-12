import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../domain/course.dart';
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

class _CourseDetailContent extends StatelessWidget {
  const _CourseDetailContent({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                                color: colors.onPrimary.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              course.fullName,
                              style: Theme.of(context).textTheme.headlineSmall
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
                                color: colors.onPrimary.withValues(alpha: 0.82),
                              ),
                            ),
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
              const SizedBox(height: 28),
              Text(
                'Nội dung khóa học',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              const _PlaceholderModule(
                icon: Icons.folder_open_outlined,
                title: 'Tài liệu và chủ đề',
                description:
                    'Sẽ hiển thị sections, modules và files sau khi API Moodle được xác nhận.',
              ),
              const SizedBox(height: 12),
              const _PlaceholderModule(
                icon: Icons.assignment_outlined,
                title: 'Bài tập',
                description:
                    'Sẽ hiển thị deadline và trạng thái nộp bài theo quyền Moodle.',
              ),
              const SizedBox(height: 12),
              const _PlaceholderModule(
                icon: Icons.bar_chart_rounded,
                title: 'Tiến độ và điểm',
                description:
                    'Không có điểm hard-code; dữ liệu thật chỉ đến từ Moodle được cấp phép.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderModule extends StatelessWidget {
  const _PlaceholderModule({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(child: Icon(icon)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
