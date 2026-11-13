import 'package:flutter/material.dart';
import '../core/data_profile.dart';

import '../models/portal.dart';
import '../services/api_exception.dart';
import 'learning_widgets.dart';

/// Loading / not linked / not connected / error-with-retry for every Portal screen (V3-P8).
class PortalView<T> extends StatefulWidget {
  final Future<T> Function(bool refresh) load;
  final Widget Function(
    BuildContext context,
    T data,
    Future<void> Function() refresh,
  )
  builder;

  const PortalView({super.key, required this.load, required this.builder});

  @override
  State<PortalView<T>> createState() => _PortalViewState<T>();
}

class _PortalViewState<T> extends State<PortalView<T>>
    with AutomaticKeepAliveClientMixin {
  late Future<T> _future = widget.load(false);

  @override
  bool get wantKeepAlive => true;

  Future<void> _refresh() async {
    setState(() {
      _future = widget.load(true);
    });
    try {
      await _future;
    } catch (_) {
      /* shown by the builder */
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return PortalErrorView(error: snapshot.error!, onRetry: _refresh);
        }
        return widget.builder(context, snapshot.data as T, _refresh);
      },
    );
  }
}

class PortalErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const PortalErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final e = error is ApiException ? error as ApiException : null;
    if (e != null && (e.portalNotLinked || e.portalDisabled)) {
      return ListView(
        children: [
          EmptyState(
            DataProfile.isReal
                ? DataProfile.portalNotLinked
                : e.portalNotLinked
                ? 'Tài khoản chưa liên kết Portal đào tạo'
                : 'Chưa kết nối Portal đào tạo',
            icon: Icons.link_off,
          ),
        ],
      );
    }
    return ListView(
      children: [
        EmptyState(apiErrorMessage(error), icon: Icons.cloud_off),
        Center(
          child: OutlinedButton.icon(
            key: const Key('portal-retry'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ),
      ],
    );
  }
}

abstract final class PortalErrorFilter {
  /// Not linked / not configured: entry points stay hidden instead of showing an error.
  static bool hidden(Object e) =>
      e is ApiException && (e.portalNotLinked || e.portalDisabled);
}

/// Small caption "Dữ liệu Portal đến HK2 năm 2025-2026".
class DataUntilText extends StatelessWidget {
  final DataUntil? until;
  const DataUntilText(this.until, {super.key});

  @override
  Widget build(BuildContext context) => until == null
      ? const SizedBox.shrink()
      : Text(
          until!.label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
}

/// Label + value tile used in Portal summaries.
class PortalStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const PortalStat(this.label, this.value, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: t.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(label, style: t.bodySmall),
      ],
    );
  }
}

class PortalStatRow extends StatelessWidget {
  final List<Widget> stats;
  const PortalStatRow(this.stats, {super.key});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(spacing: 24, runSpacing: 12, children: stats),
    ),
  );
}

/// Colour for a program status / letter.
Color statusColor(BuildContext context, ProgramStatus s) {
  final c = Theme.of(context).colorScheme;
  return switch (s) {
    ProgramStatus.passed => Colors.green.shade700,
    ProgramStatus.failed => c.error,
    ProgramStatus.inLms => c.primary,
    ProgramStatus.inProgress => Colors.orange.shade800,
    ProgramStatus.notTaken => c.outline,
  };
}
