/// One row of V2-N14 "Tuần của bạn".
class WeeklyRow {
  final String key, label;
  final int value, previous, trend;
  final int? total;
  const WeeklyRow({
    required this.key,
    required this.label,
    required this.value,
    required this.previous,
    required this.trend,
    this.total,
  });

  static int _i(Object? v) => v is num ? v.toInt() : 0;

  factory WeeklyRow.fromJson(Map<String, dynamic> j) => WeeklyRow(
    key: j['key']?.toString() ?? '',
    label: j['label']?.toString() ?? '',
    value: _i(j['value']),
    previous: _i(j['previous']),
    trend: _i(j['trend']),
    total: j['total'] is num ? (j['total'] as num).toInt() : null,
  );

  String get valueText => total != null ? '$value/$total' : '$value';
}

class WeeklyReport {
  final DateTime weekStart, weekEnd;
  final List<WeeklyRow> rows;
  final int? streakDays;
  const WeeklyReport(this.weekStart, this.weekEnd, this.rows, this.streakDays);

  factory WeeklyReport.fromJson(Map<String, dynamic> j) {
    final rows = j['rows'];
    if (rows is! List) throw const FormatException('Expected weekly rows');
    return WeeklyReport(
      DateTime.tryParse('${j['weekStart']}') ?? DateTime(1970),
      DateTime.tryParse('${j['weekEnd']}') ?? DateTime(1970),
      [
        for (final r in rows)
          if (r is Map<String, dynamic>) WeeklyRow.fromJson(r),
      ],
      j['streakDays'] is num ? (j['streakDays'] as num).toInt() : null,
    );
  }

  bool get isEmpty => rows.isEmpty && (streakDays ?? 0) == 0;
}
