/// Typed view of GET /dev/students/{id}/insights. Absent values stay null so the UI can say
/// "Chưa có dữ liệu" instead of showing a made-up zero.
int? _int(dynamic v) => v is num ? v.toInt() : null;
double? _double(dynamic v) => v is num ? v.toDouble() : null;
String? _string(dynamic v) => v is String && v.trim().isNotEmpty ? v : null;
DateTime? _date(dynamic v) => v is String ? DateTime.tryParse(v) : null;
List<Map<String, dynamic>> _maps(dynamic v) => v is List
    ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : const [];
Map<String, dynamic> _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : const {};

class StudentInsights {
  final DateTime? generatedAt;
  final bool isDemo;
  final String? dataNotice;
  final int rangeDays;
  final DateTime? rangeStart, rangeEnd;
  final InsightsSummary summary;
  final TaskStatusSummary taskStatus;
  final List<CourseProgressItem> courses;
  final List<DeadlineItem> deadlines;
  final ActivityHeatmap heatmap;
  final StreakInfo streak;
  final ProgressTimeline timeline;
  final List<InsightSuggestion> suggestions;

  StudentInsights.fromJson(Map<String, dynamic> json)
    : generatedAt = _date(json['generated_at']),
      isDemo = json['data_mode'] != 'live',
      dataNotice = _string(json['data_notice']),
      rangeDays = _int(json['range_days']) ?? 56,
      rangeStart = _date(json['range_start']),
      rangeEnd = _date(json['range_end']),
      summary = InsightsSummary.fromJson(_map(json['summary'])),
      taskStatus = TaskStatusSummary.fromJson(_map(json['task_status'])),
      courses = _maps(
        json['course_progress'],
      ).map(CourseProgressItem.fromJson).toList(),
      deadlines = _maps(
        json['upcoming_deadlines'],
      ).map(DeadlineItem.fromJson).toList(),
      heatmap = ActivityHeatmap.fromJson(_map(json['activity_heatmap'])),
      streak = StreakInfo.fromJson(_map(json['streak'])),
      timeline = ProgressTimeline.fromJson(_map(json['progress_timeline'])),
      suggestions = _maps(
        json['suggestions'],
      ).map(InsightSuggestion.fromJson).toList();
}

class InsightsSummary {
  final int? courseCount, activeGoals, achievedGoals, dueSoonGoals, activeDays;
  final double? averageProgress;
  InsightsSummary.fromJson(Map<String, dynamic> j)
    : courseCount = _int(j['course_count']),
      activeGoals = _int(j['active_goals']),
      achievedGoals = _int(j['achieved_goals']),
      dueSoonGoals = _int(j['due_soon_goals']),
      activeDays = _int(j['active_days_in_range']),
      averageProgress = _double(j['average_progress']);
}

class TaskStatusSummary {
  final int total, completed, pending, dueSoon, overdue, dueSoonHours;
  TaskStatusSummary.fromJson(Map<String, dynamic> j)
    : total = _int(j['total']) ?? 0,
      completed = _int(j['completed']) ?? 0,
      pending = _int(j['pending']) ?? 0,
      dueSoon = _int(j['due_soon']) ?? 0,
      overdue = _int(j['overdue']) ?? 0,
      dueSoonHours = _int(j['due_soon_hours']) ?? 48;
}

class CourseProgressItem {
  final int? courseId;
  final String name;
  final double? progress;
  final int? completed, total, overdue, inactiveDays;
  CourseProgressItem.fromJson(Map<String, dynamic> j)
    : courseId = _int(j['course_id']),
      name = _string(j['course_name']) ?? 'Khóa học',
      progress = _double(j['progress_percentage']),
      completed = _int(j['completed_activities']),
      total = _int(j['total_tracked_activities']),
      overdue = _int(j['overdue_tasks']),
      inactiveDays = _int(j['days_since_last_activity']);
}

class DeadlineItem {
  final String title, type;
  final String? courseName, moodlePath;
  final int? courseId, courseModuleId, hoursLeft;
  final DateTime? due;
  DeadlineItem.fromJson(Map<String, dynamic> j)
    : title = _string(j['title']) ?? 'Việc cần làm',
      type = _string(j['task_type']) ?? '',
      courseName = _string(j['course_name']),
      courseId = _int(j['course_id']),
      courseModuleId = _int(j['coursemoduleid']),
      moodlePath = _string(j['moodle_path']),
      hoursLeft = _int(j['hours_left']),
      due = (_int(j['due_time']) ?? 0) > 0
          ? DateTime.fromMillisecondsSinceEpoch(_int(j['due_time'])! * 1000)
          : null;
}

class HeatmapDay {
  final DateTime date;
  final int events;
  const HeatmapDay(this.date, this.events);
}

class ActivityHeatmap {
  final List<HeatmapDay> days;
  final int totalEvents, activeDays, maxEvents;
  final bool hasData;
  ActivityHeatmap.fromJson(Map<String, dynamic> j)
    : days = [
        for (final d in _maps(j['days']))
          if (_date(d['date']) != null)
            HeatmapDay(_date(d['date'])!, _int(d['events']) ?? 0),
      ],
      totalEvents = _int(j['total_events']) ?? 0,
      activeDays = _int(j['active_days']) ?? 0,
      maxEvents = _int(j['max_events']) ?? 0,
      hasData = j['has_data'] == true;
}

class StreakInfo {
  final int currentDays, longestDays;
  final DateTime? lastActive;
  final String? note;
  StreakInfo.fromJson(Map<String, dynamic> j)
    : currentDays = _int(j['current_days']) ?? 0,
      longestDays = _int(j['longest_days']) ?? 0,
      lastActive = _date(j['last_active_date']),
      note = _string(j['note']);
}

class ProgressPoint {
  final DateTime weekStart;
  final int completedInWeek;
  final double? cumulativePercent;
  const ProgressPoint(
    this.weekStart,
    this.completedInWeek,
    this.cumulativePercent,
  );
}

class ProgressTimeline {
  final bool available;
  final int totalTracked, totalCompleted, recent7d, previous7d;
  final String direction;
  final List<ProgressPoint> points;
  final String? note;
  ProgressTimeline.fromJson(Map<String, dynamic> j)
    : available = j['available'] == true,
      totalTracked = _int(j['total_tracked_activities']) ?? 0,
      totalCompleted = _int(j['total_completed_activities']) ?? 0,
      recent7d = _int(_map(j['trend'])['recent_7d']) ?? 0,
      previous7d = _int(_map(j['trend'])['previous_7d']) ?? 0,
      direction = _string(_map(j['trend'])['direction']) ?? 'insufficient',
      note = _string(j['note']),
      points = [
        for (final p in _maps(j['points']))
          if (_date(p['week_start']) != null)
            ProgressPoint(
              _date(p['week_start'])!,
              _int(p['completed_in_week']) ?? 0,
              _double(p['cumulative_percent']),
            ),
      ];
}

class InsightSuggestion {
  final String code, severity, title, reason, actionType;
  final int? actionCourseId;
  final DateTime? createdAt;
  InsightSuggestion.fromJson(Map<String, dynamic> j)
    : code = _string(j['code']) ?? '',
      severity = _string(j['severity']) ?? 'info',
      title = _string(j['title']) ?? '',
      reason = _string(j['reason']) ?? '',
      actionType = _string(_map(j['action'])['type']) ?? 'none',
      actionCourseId = _int(_map(j['action'])['course_id']),
      createdAt = _date(j['created_at']);
}
