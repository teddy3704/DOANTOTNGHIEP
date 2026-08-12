import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_state.dart';
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
                    'Truy cập nhanh nội dung và hoạt động học tập.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
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
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: LoadingState(label: 'Đang tải khóa học…'),
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
                      ? 'Các khóa học được Moodle cho phép sẽ xuất hiện tại đây.'
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
                      mainAxisExtent: 238,
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
              course.shortName.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
  }
}
