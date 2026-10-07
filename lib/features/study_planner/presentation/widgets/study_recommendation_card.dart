import 'package:flutter/material.dart';
import '../../../../core/external_links/official_lms_button.dart';
import '../../domain/study_plan.dart';
import 'study_plan_editor.dart';
import 'study_priority_badge.dart';

class StudyRecommendationCard extends StatelessWidget {
  const StudyRecommendationCard({
    required this.item,
    required this.now,
    this.featured = false,
    super.key,
  });
  final StudyRecommendation item;
  final DateTime now;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: featured
          ? theme.colorScheme.primaryContainer.withValues(alpha: .45)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: StudyPriorityBadge(item.priority),
            ),
            const SizedBox(height: 16),
            Text(
              item.assignmentName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.courseName,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                Text(studyDeadline(item.dueAt, now)),
                Text('Gợi ý ${item.recommendedDurationMinutes} phút'),
              ],
            ),
            StudyReasons(item.reasons),
            if (item.planned) ...[
              const Row(
                children: [
                  Icon(Icons.event_available_outlined, size: 18),
                  SizedBox(width: 8),
                  Expanded(child: Text('Đã có trong kế hoạch của bạn')),
                ],
              ),
              const SizedBox(height: 12),
            ] else ...[
              FilledButton.icon(
                onPressed: () =>
                    showStudyPlanEditor(context, recommendation: item),
                icon: const Icon(Icons.add_task_rounded),
                label: const Text('Lên kế hoạch'),
              ),
              TextButton(
                onPressed: () => showStudyPlanEditor(
                  context,
                  recommendation: item,
                  initialStart: now.add(const Duration(days: 1)),
                ),
                child: const Text('Dành thời gian ngày mai'),
              ),
            ],
            const OfficialLmsButton(label: 'Mở LMS'),
          ],
        ),
      ),
    );
  }
}
