import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/widgets/content_skeleton.dart';
import '../../../../core/widgets/error_state.dart';
import '../intervention_providers.dart';

/// Hides previous context immediately while the new authenticated data loads.
class TeacherSupportBody extends ConsumerWidget {
  const TeacherSupportBody({required this.builder, super.key});
  final Widget Function(TeacherSupportData data) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(teacherSupportDataProvider);
    if (data.isLoading) {
      return const SingleChildScrollView(
        child: ContentSkeleton(
          rows: 3,
          rowHeight: 130,
          delayedMessage: 'Máy chủ phản hồi chậm. Vui lòng chờ thêm một chút…',
        ),
      );
    }
    if (data.hasError) {
      return ErrorState(
        message: userMessageFor(data.error!),
        onRetry: () => refreshInterventions(ref),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        refreshInterventions(ref);
        // Errors are rendered by the provider, not propagated out of refresh.
        await ref
            .read(teacherSupportDataProvider.future)
            .then<void>((_) {}, onError: (Object _, StackTrace _) {});
      },
      child: builder(data.requireValue),
    );
  }
}
