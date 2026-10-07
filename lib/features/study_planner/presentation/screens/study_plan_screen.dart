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
import '../widgets/study_plan_card.dart';

class StudyPlanScreen extends ConsumerStatefulWidget {
  const StudyPlanScreen({super.key});

  @override
  ConsumerState<StudyPlanScreen> createState() => _StudyPlanScreenState();
}

class _StudyPlanScreenState extends ConsumerState<StudyPlanScreen> {
  StudyPlanPeriod _period = StudyPlanPeriod.today;

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(studyPlanProvider);
    final now = ref.watch(studyPlannerClockProvider)();
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(studyPlanProvider);
        await ref
            .read(studyPlanProvider.future)
            .then<void>((_) {}, onError: (Object _, StackTrace _) {});
      },
      child: ListView(
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
                    'Kế hoạch của bạn',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Giữ một khoảng thời gian rõ ràng cho từng việc học.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (period, label) in const [
                        (StudyPlanPeriod.today, 'Hôm nay'),
                        (StudyPlanPeriod.tomorrow, 'Ngày mai'),
                        (StudyPlanPeriod.week, 'Tuần này'),
                      ])
                        ChoiceChip(
                          label: Text(label),
                          selected: _period == period,
                          onSelected: (_) => setState(() => _period = period),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  plan.when(
                    loading: () => const ContentSkeleton(
                      rows: 2,
                      rowHeight: 200,
                      padding: EdgeInsets.zero,
                    ),
                    error: (error, _) => ErrorState(
                      message: userMessageFor(error),
                      onRetry: () => ref.invalidate(studyPlanProvider),
                    ),
                    data: (items) {
                      final visible = filterStudyPlan(items, _period, now);
                      if (visible.isEmpty) {
                        return const EmptyState(
                          title: 'Lịch học còn trống',
                          message:
                              'Chọn một việc từ Hôm nay và dành thời gian phù hợp để bắt đầu.',
                          icon: Icons.event_available_outlined,
                        );
                      }
                      final pending = visible.where(
                        (item) => item.status == StudyPlanStatus.planned,
                      );
                      final minutes = pending.fold<int>(
                        0,
                        (total, item) => total + item.estimatedMinutes,
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${visible.length} buổi học · $minutes phút còn dự kiến',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 12),
                          for (final item in visible) ...[
                            StudyPlanCard(key: ValueKey(item.id), item: item),
                            const SizedBox(height: 16),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.dashboard),
                    icon: const Icon(Icons.lightbulb_outline_rounded),
                    label: const Text('Chọn việc cần học'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '“Đã xử lý” chỉ cập nhật kế hoạch cá nhân. Trạng thái nộp bài và điểm vẫn do LMS xác nhận.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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
