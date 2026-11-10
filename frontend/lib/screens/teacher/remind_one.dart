import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/reminder_templates.dart';
import '../../core/support_csv.dart';
import '../../models/class_forecast.dart';
import '../../models/class_insights.dart';
import '../../models/teacher_monitoring.dart';
import '../../services/api_service.dart';
import 'teacher_analytics_widgets.dart';

/// V2-N8 adapters: the two teacher-side student models become the same reminder facts.
ReminderFacts factsFromInsight(InsightStudent s, {String? courseName}) =>
    ReminderFacts(
      name: s.name,
      courseName: courseName,
      overdueTitles: [
        for (final t in s.tasks)
          if (t.state == TaskState.overdue) t.title,
      ],
      overdueTotal: s.overdue,
      inactiveDays: s.inactiveDays,
      averageGrade: s.averageGrade,
    );

ReminderFacts factsFromMonitored(
  MonitoredStudent s, {
  String? courseName,
  DateTime? now,
}) {
  final at = now ?? DateTime.now();
  final overdue = [
    for (final t in s.tasks)
      if (t.isOverdue(at)) t.title,
  ];
  return ReminderFacts(
    name: s.name,
    courseName: courseName,
    overdueTitles: overdue,
    overdueTotal: s.overdue ?? overdue.length,
    inactiveDays: s.inactiveDays,
    averageGrade: s.averageGrade,
  );
}

/// Opens the composer for exactly one student, prefilled with the first matching template.
Future<bool> remindOne(
  BuildContext context, {
  required ApiService api,
  required int courseId,
  required int userId,
  required ReminderFacts facts,
}) {
  final templates = reminderTemplates(facts);
  final first = templates.first;
  return showReminderComposer(
    context,
    recipients: [facts.name],
    draft: ReminderDraft(first.title, first.message),
    templates: templates,
    send: (title, message) => api.sendReminders(
      courseId: courseId,
      studentIds: [userId],
      title: title,
      message: message,
    ),
  );
}

/// Rows for "Xuất danh sách cần hỗ trợ": students in the "Cần hỗ trợ"/"Cần theo dõi" groups,
/// highest monitoring score first. Pure, so it is unit tested.
List<SupportRow> supportRows(
  List<InsightStudent> students, {
  ClassForecast? forecast,
  List<Map<String, dynamic>> notes = const [],
}) {
  final band = {
    for (final f in forecast?.students ?? const <StudentPassForecast>[])
      f.userId: f.band.label,
  };
  final latest = <int, String>{};
  final at = <int, DateTime>{};
  for (final n in notes) {
    final id = n['student_id'];
    final text = n['note'];
    if (id is! num || text is! String) continue;
    final when = DateTime.tryParse('${n['created_at']}') ?? DateTime(0);
    if (!at.containsKey(id.toInt()) || when.isAfter(at[id.toInt()]!)) {
      at[id.toInt()] = when;
      latest[id.toInt()] = text;
    }
  }
  final flagged =
      students
          .where(
            (s) =>
                s.group == WatchGroup.needsSupport ||
                s.group == WatchGroup.watch,
          )
          .toList()
        ..sort((a, b) => (b.riskScore ?? 0).compareTo(a.riskScore ?? 0));
  return [
    for (final s in flagged)
      SupportRow(
        studentCode: s.code,
        name: s.name,
        riskScore: s.riskScore,
        reasons: [for (final g in s.signals) g.label],
        forecast: band[s.id],
        latestNote: latest[s.id],
      ),
  ];
}

typedef ShareCsv = Future<void> Function(List<int> bytes, String fileName);

Future<void> _shareWithSystem(List<int> bytes, String fileName) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          Uint8List.fromList(bytes),
          mimeType: 'text/csv',
          name: fileName,
        ),
      ],
      fileNameOverrides: [fileName],
      subject: fileName,
    ),
  );
}

/// Builds the CSV (insights + N4 forecast + latest notes) and opens the share sheet.
/// Forecast and notes are optional: if either fails, its column stays empty.
Future<int> exportSupportList({
  required ApiService api,
  required int courseId,
  required List<InsightStudent> students,
  ShareCsv share = _shareWithSystem,
  DateTime? now,
}) async {
  ClassForecast? forecast;
  var notes = const <Map<String, dynamic>>[];
  try {
    forecast = await api.getClassForecast(courseId: courseId);
  } catch (e) {
    debugPrint('Support export forecast: $e');
  }
  try {
    notes = await api.getCourseNotes(courseId);
  } catch (e) {
    debugPrint('Support export notes: $e');
  }
  final rows = supportRows(students, forecast: forecast, notes: notes);
  final d = now ?? DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  await share(
    supportCsvBytes(rows),
    'can-ho-tro-khoa-$courseId-${d.year}${two(d.month)}${two(d.day)}.csv',
  );
  return rows.length;
}
