import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../domain/course.dart';
import '../../domain/course_repository.dart';
import '../widgets/course_card.dart';

class CoursesScreen extends ConsumerStatefulWidget {
  const CoursesScreen({super.key});

  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(myCoursesProvider);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          sliver: SliverToBoxAdapter(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Khóa học của tôi',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Theo dõi tiến độ và tiếp tục môn học đang tham gia.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên hoặc mã khóa học',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Xóa tìm kiếm',
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        courses.when(
          loading: () => const SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 28),
            sliver: _CourseLoadingSkeleton(),
          ),
          error: (error, _) => SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorState(
              message: userMessageFor(error),
              onRetry: () => ref.invalidate(myCoursesProvider),
            ),
          ),
          data: (items) {
            final filtered = _filter(items, _query);
            if (filtered.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  title: _query.trim().isEmpty
                      ? 'Chưa có khóa học'
                      : 'Không tìm thấy khóa học',
                  message: _query.trim().isEmpty
                      ? 'Khóa học bạn được ghi danh sẽ xuất hiện tại đây.'
                      : 'Thử một tên hoặc mã khóa học khác.',
                  icon: Icons.menu_book_outlined,
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.crossAxisExtent >= 1050
                      ? 3
                      : constraints.crossAxisExtent >= 680
                      ? 2
                      : 1;
                  return SliverGrid.builder(
                    itemCount: filtered.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 218,
                    ),
                    itemBuilder: (context, index) {
                      final course = filtered[index];
                      return CourseCard(
                        course: course,
                        onTap: () => context.push(AppRoutes.course(course.id)),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  List<Course> _filter(List<Course> courses, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return courses;
    return courses
        .where(
          (course) =>
              course.fullName.toLowerCase().contains(normalized) ||
              course.shortName.toLowerCase().contains(normalized) ||
              course.category.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
  }
}

class _CourseLoadingSkeleton extends StatelessWidget {
  const _CourseLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SliverList.builder(
      itemCount: 3,
      itemBuilder: (context, index) => Semantics(
        liveRegion: index == 0,
        label: index == 0 ? 'Đang tải khóa học…' : null,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (index == 0) ...[
                    Text(
                      'Đang tải khóa học…',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _SkeletonLine(width: 84, color: colors.surfaceContainerHigh),
                  const SizedBox(height: 14),
                  _SkeletonLine(
                    width: double.infinity,
                    color: colors.surfaceContainerHigh,
                  ),
                  const SizedBox(height: 9),
                  _SkeletonLine(width: 180, color: colors.surfaceContainerHigh),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, required this.color});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 12,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
  );
}
