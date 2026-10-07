import 'dart:async';

import 'package:flutter/material.dart';

class ContentSkeleton extends StatefulWidget {
  const ContentSkeleton({
    this.rows = 3,
    this.rowHeight = 88,
    this.padding = const EdgeInsets.all(20),
    this.delayedMessage,
    super.key,
  });

  final int rows;
  final double rowHeight;
  final EdgeInsetsGeometry padding;

  /// Optional context for slow network responses; transport timeout and retry
  /// remain responsible for the finite request lifecycle.
  final String? delayedMessage;

  @override
  State<ContentSkeleton> createState() => _ContentSkeletonState();
}

class _ContentSkeletonState extends State<ContentSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);
  Timer? _delay;
  bool _showMessage = false;

  @override
  void initState() {
    super.initState();
    if (widget.delayedMessage != null) {
      _delay = Timer(const Duration(seconds: 8), () {
        if (mounted) setState(() => _showMessage = true);
      });
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: widget.padding,
      child: Column(
        children: [
          if (_showMessage && widget.delayedMessage != null) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                widget.delayedMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Semantics(
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
                  return Column(
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
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
