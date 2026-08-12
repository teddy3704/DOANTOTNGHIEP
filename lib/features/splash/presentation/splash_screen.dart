import 'package:flutter/material.dart';

import '../../../core/widgets/app_wordmark.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primaryContainer.withValues(alpha: 0.85),
              Theme.of(context).scaffoldBackgroundColor,
              colors.tertiaryContainer.withValues(alpha: 0.55),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppWordmark(),
                const SizedBox(height: 44),
                SizedBox(
                  width: 180,
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Đang chuẩn bị không gian học tập…',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
