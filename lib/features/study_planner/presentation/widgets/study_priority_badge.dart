import 'package:flutter/material.dart';
import '../../domain/study_plan.dart';

class StudyPriorityBadge extends StatelessWidget {
  const StudyPriorityBadge(this.priority, {super.key});
  final StudyPriority priority;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground) = switch (priority) {
      StudyPriority.high => (colors.errorContainer, colors.onErrorContainer),
      StudyPriority.medium => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
      StudyPriority.low => (
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          priority.label,
          style: TextStyle(
            color: foreground,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class StudyReasons extends StatelessWidget {
  const StudyReasons(this.reasons, {super.key});
  final List<String> reasons;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(bottom: 12),
    title: const Text('Vì sao việc này được đề xuất?'),
    leading: const Icon(Icons.lightbulb_outline_rounded),
    expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final reason in reasons)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_rounded, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(reason)),
            ],
          ),
        ),
      const Text(
        'Gợi ý dựa trên tình trạng học tập hiện có; bạn quyết định thời điểm phù hợp.',
        style: TextStyle(fontSize: 12),
      ),
    ],
  );
}
