import 'package:flutter/material.dart';

class AppWordmark extends StatelessWidget {
  const AppWordmark({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(compact ? 12 : 18),
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 10 : 15),
            child: Icon(
              Icons.school_rounded,
              color: colors.onPrimary,
              size: compact ? 22 : 32,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          fit: FlexFit.loose,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'DLU LMS',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    (compact
                            ? Theme.of(context).textTheme.titleMedium
                            : Theme.of(context).textTheme.headlineSmall)
                        ?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
              ),
              if (!compact)
                Text(
                  'Không gian học tập số',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
