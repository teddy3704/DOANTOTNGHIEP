import 'package:flutter/material.dart';

import '../../domain/course.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({required this.course, required this.onTap, super.key});

  final Course course;
  final VoidCallback onTap;

  static const _accents = <Color>[
    Color(0xFF236AA6),
    Color(0xFF6F4FA2),
    Color(0xFF24856D),
    Color(0xFFC36A32),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = _accents[course.accentIndex % _accents.length];
    final progress = course.progress?.clamp(0.0, 1.0).toDouble();
    final progressLabel = progress == null
        ? null
        : 'Tiến độ ${(progress * 100).round()}%';

    return Semantics(
      button: true,
      label: 'Mở khóa học ${course.fullName}',
      value: progressLabel,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          child: Text(
                            course.shortName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Spacer(),
                    Icon(Icons.arrow_forward_rounded, color: accent),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  course.fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  course.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (course.nextActivity case final nextItem?) ...[
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 17, color: accent),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          nextItem,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (progress != null) ...[
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(8),
                    color: accent,
                    backgroundColor: accent.withValues(alpha: 0.12),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    progressLabel!,
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
