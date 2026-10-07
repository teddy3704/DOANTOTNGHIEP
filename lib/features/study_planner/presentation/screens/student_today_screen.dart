import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/widgets/content_skeleton.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../domain/study_plan.dart';
import '../study_planner_providers.dart';
import '../widgets/study_recommendation_card.dart';

/// The recommendation order and reasons come from the repository, not the UI.
class StudentTodayScreen extends ConsumerWidget {
  const StudentTodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendations = ref.watch(studyRecommendationsProvider);
    final plan = ref.watch(studyPlanProvider);
    final now = ref.watch(studyPlannerClockProvider)();
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        refreshStudyPlanner(ref);
        await Future.wait([
          ref
              .read(studyRecommendationsProvider.future)
              .then<void>((_) {}, onError: (Object _, StackTrace _) {}),
          ref
              .read(studyPlanProvider.future)
              .then<void>((_) {}, onError: (Object _, StackTrace _) {}),
        ]);
      },
      child: ListView(
        key: const PageStorageKey('student-today'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Hôm nay nên học gì?',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bắt đầu từ một việc quan trọng. Chia nhỏ thời gian để học chủ động hơn.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  plan.when(
                    loading: () => const ContentSkeleton(
                      rows: 1,
                      rowHeight: 96,
                      padding: EdgeInsets.zero,
                    ),
                    error: (error, _) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(userMessageFor(error)),
                            TextButton(
                              onPressed: () =>
                                  ref.invalidate(studyPlanProvider),
                              child: const Text('Tải lại kế hoạch'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (items) => _TodayPlanSummary(
                      items: filterStudyPlan(items, StudyPlanPeriod.today, now),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Việc nên ưu tiên',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('Mỗi gợi ý đều có lý do để bạn cân nhắc.'),
                  const SizedBox(height: 16),
                  recommendations.when(
                    loading: () => const ContentSkeleton(
                      rows: 2,
                      rowHeight: 220,
                      padding: EdgeInsets.zero,
                    ),
                    error: (error, _) => ErrorState(
                      message: userMessageFor(error),
                      onRetry: () =>
                          ref.invalidate(studyRecommendationsProvider),
                    ),
                    data: (items) => items.isEmpty
                        ? const EmptyState(
                            title: 'Bạn đã có khoảng trống để chủ động',
                            message:
                                'Chưa có bài tập cần ưu tiên. Bạn có thể ôn lại nội dung trong các khóa học.',
                            icon: Icons.wb_sunny_outlined,
                          )
                        : Column(
                            children: [
                              for (
                                var index = 0;
                                index < items.length;
                                index++
                              ) ...[
                                StudyRecommendationCard(
                                  item: items[index],
                                  now: now,
                                  featured: index == 0,
                                ),
                                if (index < items.length - 1)
                                  const SizedBox(height: 16),
                              ],
                            ],
                          ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.courses),
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('Khám phá khóa học'),
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

class _TodayPlanSummary extends StatelessWidget {
  const _TodayPlanSummary({required this.items});
  final List<StudyPlanItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = items.where(
      (item) => item.status == StudyPlanStatus.planned,
    );
    final minutes = pending.fold<int>(
      0,
      (sum, item) => sum + item.estimatedMinutes,
    );
    final handled = items.length - pending.length;
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.secondaryContainer.withValues(alpha: .5),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.event_note_outlined, size: 28),
            const SizedBox(height: 12),
            Text(
              'Nhịp học hôm nay',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              items.isEmpty
                  ? 'Chưa có buổi học nào. Chọn một gợi ý bên dưới để bắt đầu.'
                  : '${pending.length} buổi đang chờ · $minutes phút dự kiến\n$handled buổi đã xử lý',
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => context.go(AppRoutes.studyPlan),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Mở kế hoạch học tập'),
            ),
          ],
        ),
      ),
    );
  }
}
