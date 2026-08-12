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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 8,
                      ),
                      child: Text(
                        course.shortName,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_rounded, color: accent),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                course.fullName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                course.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (course.nextActivity != null) ...[
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 17, color: accent),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        course.nextActivity!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              if (course.progress != null) ...[
                LinearProgressIndicator(
                  value: course.progress,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(8),
                  color: accent,
                  backgroundColor: accent.withValues(alpha: 0.12),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(course.progress! * 100).round()}% tiến độ',
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
    );
  }
}
