import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Left axis for count charts: whole numbers only, on one line, with room
/// for the widest label at the current text size (fl_chart's default 22 px
/// wrapped "104.4" onto two lines).
AxisTitles countAxisTitles(BuildContext context, double maxY) {
  final style = TextStyle(fontSize: 10, color: context.muted);
  final digits = maxY.ceil().abs().toString().length;
  final width = MediaQuery.textScalerOf(context).scale(10) * 0.62 * digits + 8;
  return AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      reservedSize: width,
      getTitlesWidget: (value, meta) {
        if (value != value.roundToDouble()) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Text(
            '${value.toInt()}',
            style: style,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            textAlign: TextAlign.right,
          ),
        );
      },
    ),
  );
}
