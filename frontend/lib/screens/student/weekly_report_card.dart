import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/weekly_report.dart';
import '../../services/api_service.dart';

typedef SharePng = Future<void> Function(Uint8List png, String fileName);

Future<void> _sharePng(Uint8List png, String fileName) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(png, mimeType: 'image/png', name: fileName)],
      fileNameOverrides: [fileName],
    ),
  );
}

/// V2-N14 weekly card: only rows with real data; "Chia sẻ" captures the card as a PNG.
class WeeklyReportCard extends StatefulWidget {
  final ApiService api;
  final SharePng share;
  const WeeklyReportCard({
    super.key,
    required this.api,
    this.share = _sharePng,
  });

  @override
  State<WeeklyReportCard> createState() => _WeeklyReportCardState();
}

class _WeeklyReportCardState extends State<WeeklyReportCard> {
  final _boundary = GlobalKey();
  late final Future<WeeklyReport?> _future = _load();

  Future<WeeklyReport?> _load() async {
    try {
      return await widget.api.getWeeklyReport();
    } catch (e) {
      debugPrint('Weekly report: $e');
      return null;
    }
  }

  Future<void> _share(WeeklyReport r) async {
    try {
      final boundary =
          _boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) throw StateError('no png');
      String two(int v) => v.toString().padLeft(2, '0');
      await widget.share(
        bytes.buffer.asUint8List(),
        'tuan-cua-ban-${r.weekStart.year}${two(r.weekStart.month)}${two(r.weekStart.day)}.png',
      );
    } catch (e) {
      debugPrint('Weekly share: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tạo được ảnh để chia sẻ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<WeeklyReport?>(
    future: _future,
    builder: (context, snap) {
      final r = snap.data;
      if (r == null || r.isEmpty) return const SizedBox.shrink();
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      return Card(
        key: const Key('weekly-report-card'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RepaintBoundary(
              key: _boundary,
              child: Container(
                color: scheme.surfaceContainerLow,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tuần của bạn', style: theme.textTheme.titleMedium),
                    Text(
                      '${r.weekStart.day}/${r.weekStart.month} – ${r.weekEnd.day}/${r.weekEnd.month}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    for (final row in r.rows)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(child: Text(row.label)),
                            Text(
                              row.valueText,
                              key: Key('weekly-${row.key}'),
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              row.trend > 0
                                  ? Icons.arrow_upward
                                  : row.trend < 0
                                  ? Icons.arrow_downward
                                  : Icons.remove,
                              size: 16,
                              color: row.trend > 0
                                  ? const Color(0xFF2E7D32)
                                  : row.trend < 0
                                  ? scheme.error
                                  : scheme.outline,
                              semanticLabel: row.trend > 0
                                  ? 'Tăng so với tuần trước'
                                  : row.trend < 0
                                  ? 'Giảm so với tuần trước'
                                  : 'Như tuần trước',
                            ),
                            SizedBox(
                              width: 52,
                              child: Text(
                                'trước ${row.previous}',
                                textAlign: TextAlign.right,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if ((r.streakDays ?? 0) > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Chuỗi ${r.streakDays} ngày học liên tiếp',
                          key: const Key('weekly-streak'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const Key('weekly-share'),
                onPressed: () => _share(r),
                icon: const Icon(Icons.share_outlined),
                label: const Text('Chia sẻ'),
              ),
            ),
          ],
        ),
      );
    },
  );
}
