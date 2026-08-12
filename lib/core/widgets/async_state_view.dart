import 'package:flutter/material.dart';

import '../errors/failure_message.dart';
import 'empty_state.dart';
import 'error_state.dart';
import 'loading_state.dart';

class AsyncStateView<T> extends StatelessWidget {
  const AsyncStateView({
    required this.value,
    required this.data,
    required this.onRetry,
    this.isEmpty,
    this.emptyTitle = 'Chưa có dữ liệu',
    this.emptyMessage = 'Dữ liệu sẽ xuất hiện tại đây khi Moodle cung cấp.',
    super.key,
  });

  final AsyncSnapshot<T> value;
  final Widget Function(T data) data;
  final VoidCallback onRetry;
  final bool Function(T data)? isEmpty;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (value.connectionState == ConnectionState.waiting) {
      return const LoadingState();
    }
    if (value.hasError) {
      return ErrorState(
        message: userMessageFor(value.error!),
        onRetry: onRetry,
      );
    }
    final resolved = value.requireData;
    if (isEmpty?.call(resolved) ?? false) {
      return EmptyState(title: emptyTitle, message: emptyMessage);
    }
    return data(resolved);
  }
}
