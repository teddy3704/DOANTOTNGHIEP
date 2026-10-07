import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';

/// Makes the explicitly selected staging preview visibly distinct from the
/// production application without exposing implementation details or secrets.
class StagingReadOnlyNotice extends StatelessWidget {
  const StagingReadOnlyNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: colors.tertiaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          Icon(
            Icons.visibility_outlined,
            size: 18,
            color: colors.onTertiaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Dữ liệu mô phỏng · Học tập chính thức trên LMS',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.onTertiaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Adds the staging disclosure to root-navigator pages that do not live in
/// [AppShell]. It is intentionally inactive for development and production.
class StagingReadOnlyFrame extends ConsumerWidget {
  const StagingReadOnlyFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(appConfigProvider).isStaging) return child;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const StagingReadOnlyNotice(),
          Expanded(child: child),
        ],
      ),
    );
  }
}
