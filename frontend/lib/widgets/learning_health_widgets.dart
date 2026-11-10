import 'package:flutter/material.dart';

import '../core/display_text.dart';
import '../models/learning_health.dart';
import 'moodle_button.dart';

/// Background/foreground for a health level; readable in light and dark themes.
(Color, Color) healthColors(BuildContext context, HealthLevel? level) {
  final scheme = Theme.of(context).colorScheme;
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (level) {
    HealthLevel.red => (scheme.errorContainer, scheme.onErrorContainer),
    HealthLevel.yellow => (
      dark ? const Color(0xFF4A3B00) : const Color(0xFFFFF0C2),
      dark ? const Color(0xFFFFE08A) : const Color(0xFF5C4300),
    ),
    HealthLevel.green => (
      dark ? const Color(0xFF1E3A1E) : const Color(0xFFDDF3D5),
      dark ? const Color(0xFFB8E6A8) : const Color(0xFF1F4D14),
    ),
    null => (scheme.surfaceContainerHighest, scheme.onSurface),
  };
}

/// One compact coloured row: level dot, title, one-line summary. Taps open the detail.
class HealthSummaryTile extends StatelessWidget {
  final HealthLevel? level;
  final String title;
  final String summary;
  final VoidCallback? onTap;

  const HealthSummaryTile({
    super.key,
    required this.level,
    required this.title,
    required this.summary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = healthColors(context, level);
    return Card(
      color: bg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.monitor_heart_outlined, color: fg),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(color: fg),
                    ),
                    Text(
                      summary,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: fg),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: fg,
                  semanticLabel: 'Xem chi tiết',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full card for one course: level, score, every reason with its points, and the actions.
class CourseHealthCard extends StatelessWidget {
  final CourseHealth health;
  final bool showCourseName;
  final void Function(HealthAction action)? onAction;

  const CourseHealthCard({
    super.key,
    required this.health,
    this.showCourseName = true,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = healthColors(context, health.level);
    final theme = Theme.of(context);
    final level = health.level;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    level == null
                        ? 'Chưa rõ'
                        : '${level.label} · ${level.meaning}',
                    style: theme.textTheme.labelLarge?.copyWith(color: fg),
                  ),
                ),
                const Spacer(),
                Text(
                  'Điểm theo dõi ${health.score}/100',
                  style: theme.textTheme.labelLarge,
                ),
              ],
            ),
            if (showCourseName) ...[
              const SizedBox(height: 8),
              Text(
                DemoDisplayNames.course(health.courseName),
                style: theme.textTheme.titleMedium,
              ),
            ],
            const SizedBox(height: 8),
            if (health.reasons.isEmpty)
              const Text('Không có dấu hiệu cần chú ý trong khóa này.')
            else ...[
              Text(
                'Vì sao có điểm này (giống điểm giảng viên đang thấy):',
                style: theme.textTheme.bodySmall,
              ),
              for (final r in health.reasons)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text(
                          '+${r.points}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                      Expanded(child: Text(r.label)),
                    ],
                  ),
                ),
            ],
            if (health.actions.isNotEmpty) ...[
              const Divider(height: 20),
              Text('Làm gì để lên Xanh', style: theme.textTheme.titleSmall),
              Text(
                'Cần dưới 30 điểm. Mỗi việc dưới đây giảm số điểm ghi kèm.',
                style: theme.textTheme.bodySmall,
              ),
              for (final a in health.actions) _action(context, a),
            ],
          ],
        ),
      ),
    );
  }

  Widget _action(BuildContext context, HealthAction a) {
    final label = '${a.title} (−${a.scoreDrop} điểm)';
    if (a.target == HealthTarget.openLms) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            MoodleButton(
              path: a.moodlePath,
              courseModuleId: a.courseModuleId,
              compact: true,
            ),
          ],
        ),
      );
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(
        a.target == HealthTarget.tasks
            ? Icons.assignment_late_outlined
            : Icons.menu_book_outlined,
      ),
      title: Text(label),
      trailing: onAction == null ? null : const Icon(Icons.chevron_right),
      onTap: onAction == null ? null : () => onAction!(a),
    );
  }
}
