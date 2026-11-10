/// V2-N8: CSV of students who need support (RFC 4180, UTF-8 with BOM so Excel shows Vietnamese).
library;

import 'dart:convert';

class SupportRow {
  final String? studentCode;
  final String name;
  final int? riskScore;
  final List<String> reasons;
  final String? forecast;
  final String? latestNote;
  const SupportRow({
    required this.name,
    this.studentCode,
    this.riskScore,
    this.reasons = const [],
    this.forecast,
    this.latestNote,
  });
}

const supportCsvHeader = [
  'MSSV',
  'Họ tên',
  'Điểm theo dõi',
  'Lý do',
  'Dự báo qua môn',
  'Ghi chú gần nhất',
];

/// Quotes a field when needed and neutralises spreadsheet formulas (=, +, -, @ at the start).
String csvField(String? v) {
  var s = v ?? '';
  if (s.isNotEmpty && '=+-@\t\r'.contains(s[0])) s = "'$s";
  if (s.contains(RegExp(r'[",\r\n]'))) return '"${s.replaceAll('"', '""')}"';
  return s;
}

String supportCsv(List<SupportRow> rows) {
  final lines = [supportCsvHeader.map(csvField).join(',')];
  for (final r in rows) {
    lines.add(
      [
        r.studentCode,
        r.name,
        r.riskScore?.toString(),
        r.reasons.join('; '),
        r.forecast,
        r.latestNote,
      ].map(csvField).join(','),
    );
  }
  return '${lines.join('\r\n')}\r\n';
}

/// Bytes to write/share: BOM + UTF-8.
List<int> supportCsvBytes(List<SupportRow> rows) => [
  0xEF,
  0xBB,
  0xBF,
  ...utf8.encode(supportCsv(rows)),
];
