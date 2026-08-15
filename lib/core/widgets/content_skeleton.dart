import 'package:flutter/material.dart';

class ContentSkeleton extends StatefulWidget {
  const ContentSkeleton({
    this.rows = 3,
    this.rowHeight = 88,
    this.padding = const EdgeInsets.all(20),
    super.key,
  });

  final int rows;
  final double rowHeight;
  final EdgeInsetsGeometry padding;

  @override
  State<ContentSkeleton> createState() => _ContentSkeletonState();
}

class _ContentSkeletonState extends State<ContentSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      label: 'Đang tải nội dung',
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final color = Color.lerp(
              colors.surfaceContainerHighest,
              colors.surfaceContainerLow,
              _controller.value,
            )!;
            return Padding(
              padding: widget.padding,
              child: Column(
                children: [
                  for (var index = 0; index < widget.rows; index++) ...[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: SizedBox(
                        height: widget.rowHeight,
                        width: double.infinity,
                      ),
                    ),
                    if (index < widget.rows - 1) const SizedBox(height: 12),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
