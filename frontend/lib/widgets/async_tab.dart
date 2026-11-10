import '../core/display_text.dart';

import 'package:flutter/material.dart';

/// Each tab owns its loading/error/refresh state; one failed API does not hide others.
class AsyncTab<T> extends StatefulWidget {
  final Future<T> Function() load;
  final List<Widget> Function(T data) children;
  final List<Widget> leading;

  const AsyncTab({
    super.key,
    required this.load,
    required this.children,
    this.leading = const [],
  });

  @override
  State<AsyncTab<T>> createState() => _AsyncTabState<T>();
}

class _AsyncTabState<T> extends State<AsyncTab<T>>
    with AutomaticKeepAliveClientMixin {
  late Future<T> _future;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<T> _load() async {
    try {
      return await widget.load();
    } catch (error, stack) {
      debugPrint('Course tab: $error\n$stack');
      rethrow;
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    try {
      await _future;
    } catch (_) {
      /* FutureBuilder displays the error. */
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) => RefreshIndicator(
        onRefresh: _refresh,
        child: CourseTabList(
          children: [
            ...widget.leading,
            if (snapshot.connectionState != ConnectionState.done)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (snapshot.hasError)
              CourseLoadError(onRetry: _refresh)
            else
              ...widget.children(snapshot.data as T),
          ],
        ),
      ),
    );
  }
}

class CourseTabList extends StatelessWidget {
  final List<Widget> children;
  const CourseTabList({super.key, required this.children});
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 900),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: children,
      ),
    ),
  );
}

class CourseLoadError extends StatelessWidget {
  final VoidCallback onRetry;
  const CourseLoadError({super.key, required this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        const Icon(Icons.cloud_off_outlined, size: 40),
        const SizedBox(height: 12),
        const Text('Không thể tải dữ liệu'),
        const Text('Vui lòng thử lại'),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Thử lại'),
        ),
      ],
    ),
  );
}

class DetailCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? trailing;
  final int? titleMaxLines;
  final VoidCallback? onTap;
  const DetailCard({
    super.key,
    required this.title,
    this.children = const [],
    this.trailing,
    this.titleMaxLines,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: titleMaxLines,
                    overflow: titleMaxLines == null
                        ? null
                        : TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ?trailing,
              ],
            ),
            if (children.isNotEmpty) const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    ),
  );
}

String detailValue(num? value, {String suffix = ''}) => suffix == '%'
    ? formatPercentageVi(value)
    : value == null
    ? 'Chưa có dữ liệu'
    : '${value is int ? value : vietnameseDecimal(value)}$suffix';

class DetailLine extends StatelessWidget {
  final String label;
  final String value;
  const DetailLine(this.label, this.value, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text('$label: $value'),
  );
}
