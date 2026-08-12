import 'package:flutter/material.dart';

class LoadingState extends StatelessWidget {
  const LoadingState({this.label = 'Đang tải dữ liệu…', super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      liveRegion: true,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(
            dimension: 32,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}
