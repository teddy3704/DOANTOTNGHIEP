import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../courses/domain/course_repository.dart';
import '../../../courses/presentation/widgets/course_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final auth = ref.watch(authControllerProvider);
    final courses = ref.watch(myCoursesProvider);
    final name = auth.session?.displayName ?? 'bạn';

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xin chào, $name',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cùng tiếp tục hành trình học tập hôm nay.',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Thông báo',
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Thông báo sẽ được bật sau khi API Moodle được xác nhận.',
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          sliver: SliverToBoxAdapter(child: _StatusHero(config: config)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Khóa học gần đây',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(AppRoutes.courses),
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
          ),
        ),
        courses.when(
          loading: () => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, _) => SliverToBoxAdapter(
            child: _DashboardApiNotice(
              message: userMessageFor(error),
              onRetry: () => ref.invalidate(myCoursesProvider),
            ),
          ),
          data: (items) => items.isEmpty
              ? const SliverToBoxAdapter(
                  child: _DashboardApiNotice(
                    message: 'Chưa có khóa học nào được Moodle trả về.',
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.crossAxisExtent >= 1050
                          ? 3
                          : constraints.crossAxisExtent >= 680
                          ? 2
                          : 1;
                      return SliverGrid.builder(
                        itemCount: items.take(3).length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 238,
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
      ],
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1180),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.primary, colors.primary.withValues(alpha: 0.78)],
          ),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.22),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) => Flex(
              direction: constraints.maxWidth >= 620
                  ? Axis.horizontal
                  : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: constraints.maxWidth >= 620 ? 1 : 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.onPrimary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          child: Text(
                            config.enableDevFixtures
                                ? 'DEV FIXTURE · KHÔNG PHẢI DỮ LIỆU DLU'
                                : 'SẴN SÀNG KẾT NỐI MOODLE',
                            style: TextStyle(
                              color: colors.onPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        config.enableDevFixtures
                            ? 'Giao diện demo đã sẵn sàng.'
                            : 'Kiến trúc đã sẵn sàng tích hợp.',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: colors.onPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        config.enableDevFixtures
                            ? 'Dữ liệu trên màn hình này hoàn toàn synthetic và chỉ được inject qua development entrypoint.'
                            : 'Đang chờ DLU xác nhận cơ chế xác thực và danh sách Moodle Web Services được phép.',
                        style: TextStyle(
                          color: colors.onPrimary.withValues(alpha: 0.86),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (constraints.maxWidth >= 620) const SizedBox(width: 24),
                if (constraints.maxWidth < 620) const SizedBox(height: 24),
                Icon(
                  Icons.auto_stories_rounded,
                  size: 86,
                  color: colors.onPrimary.withValues(alpha: 0.22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardApiNotice extends StatelessWidget {
  const _DashboardApiNotice({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded),
            const SizedBox(width: 12),
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
    ),
  );
}
