int? _int(dynamic v) => v is num ? v.toInt() : null;
double? _double(dynamic v) => v is num ? v.toDouble() : null;
String? _string(dynamic v) => v is String && v.trim().isNotEmpty ? v : null;
DateTime? _date(dynamic v) => v is String ? DateTime.tryParse(v) : null;
List<Map<String, dynamic>> _maps(dynamic v) => v is List
    ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : const [];
Map<String, dynamic> _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : const {};
List<String> _strings(dynamic v) =>
    v is List ? v.whereType<String>().toList() : const [];

/// Typed view of GET /dev/teachers/{id}/courses/{id}/class-insights.
class ClassInsights {
  final DateTime? generatedAt;
  final bool isDemo;
  final String? dataNotice;
  final int weeks;
  final int studentCount, watchCount;
  final double? averageProgress, averageGrade;
  final List<BucketCount> progressDistribution;
  final WatchGroups groups;
  final List<String> criteria;
  final List<AttentionStudent> attention;
  final ClassTaskStatus tasks;
  final WeeklyTrend weekly;
  final List<LowCompletionActivity> lowActivities;
  final List<Intervention> interventions;
  final double? averageAttendance;

  /// Every enrolled student, most urgent first. Older backends only send
  /// [attention]; those students are used so drill-downs never come up empty.
  final List<InsightStudent> students;
  final Map<String, int> signalCounts;

  /// What the averages are taken over; null when an older backend omits them.
  final int? progressStudentCount, gradedStudentCount, trackedActivities;

  /// The course log records students opening individual activities.
  final bool activityViewTracking;

  /// Null when an older backend omits them; the screen then hides those sections.
  final ActivityHeatmap? heatmap;
  final SupportFollowUps? followUps;
  final WeeklyChange? weeklyChange;
  final List<ActionItem> actionItems;

  ClassInsights.fromJson(Map<String, dynamic> j)
    : weeklyChange = j['weekly_change'] is Map
          ? WeeklyChange.fromJson(_map(j['weekly_change']))
          : null,
      actionItems = _maps(j['action_items']).map(ActionItem.fromJson).toList(),
      heatmap = j['activity_heatmap'] is Map
          ? ActivityHeatmap.fromJson(_map(j['activity_heatmap']))
          : null,
      followUps = j['support_followups'] is Map
          ? SupportFollowUps.fromJson(_map(j['support_followups']))
          : null,
      averageAttendance = _double(_map(j['summary'])['average_attendance']),
      progressStudentCount = _int(_map(j['summary'])['progress_student_count']),
      gradedStudentCount = _int(_map(j['summary'])['graded_student_count']),
      trackedActivities = _int(_map(j['summary'])['tracked_activities']),
      activityViewTracking =
          _map(j['summary'])['activity_view_tracking'] == true,
      students = j['students'] is List
          ? _maps(j['students']).map(InsightStudent.fromJson).toList()
          : _maps(j['attention_students'])
                .map(
                  (m) => InsightStudent.fromAttention(
                    AttentionStudent.fromJson(m),
                  ),
                )
                .toList(),
      signalCounts = {
        for (final e in _map(j['signal_counts']).entries)
          if (_int(e.value) != null) e.key: _int(e.value)!,
      },
      generatedAt = _date(j['generated_at']),
      isDemo = j['data_mode'] != 'live',
      dataNotice = _string(j['data_notice']),
      weeks = _int(j['weeks']) ?? 8,
      studentCount = _int(_map(j['summary'])['student_count']) ?? 0,
      watchCount = _int(_map(j['summary'])['watch_count']) ?? 0,
      averageProgress = _double(_map(j['summary'])['average_progress']),
      averageGrade = _double(_map(j['summary'])['average_grade_percentage']),
      progressDistribution = _maps(j['progress_distribution'])
          .map(
            (m) => BucketCount(
              _string(m['label']) ?? '',
              _int(m['students']) ?? 0,
            ),
          )
          .toList(),
      groups = WatchGroups.fromJson(_map(j['watch_groups'])),
      criteria = _strings(j['watch_criteria']),
      attention = _maps(
        j['attention_students'],
      ).map(AttentionStudent.fromJson).toList(),
      tasks = ClassTaskStatus.fromJson(_map(j['task_status'])),
      weekly = WeeklyTrend.fromJson(_map(j['weekly_trend'])),
      lowActivities = _maps(
        j['low_completion_activities'],
      ).map(LowCompletionActivity.fromJson).toList(),
      interventions = _maps(
        j['suggested_interventions'],
      ).map(Intervention.fromJson).toList();
}

class BucketCount {
  final String label;
  final int count;
  const BucketCount(this.label, this.count);
}

class WatchGroups {
  final int onTrack, watch, needsSupport, unknown;
  WatchGroups.fromJson(Map<String, dynamic> j)
    : onTrack = _int(j['on_track']) ?? 0,
      watch = _int(j['watch']) ?? 0,
      needsSupport = _int(j['needs_support']) ?? 0,
      unknown = _int(j['unknown']) ?? 0;
  int get total => onTrack + watch + needsSupport + unknown;
}

class AttentionStudent {
  final int id;
  final String name, risk;
  final String? code, note;
  final double? progress;
  final int? overdue, inactiveDays;
  final List<String> reasons, actions;
  AttentionStudent.fromJson(Map<String, dynamic> j)
    : id = _int(j['userid']) ?? 0,
      name = _string(j['fullname']) ?? 'Sinh viên #${j['userid']}',
      code = _string(j['student_code']),
      risk = _string(j['risk_level']) ?? '',
      note = _string(j['note']),
      progress = _double(j['progress']),
      overdue = _int(j['overdue_tasks']),
      inactiveDays = _int(j['days_since_last_activity']),
      reasons = _strings(j['reasons']),
      actions = _strings(j['suggested_actions']);
}

/// Groups as computed by the backend from derived.student_risk_indicator.
enum WatchGroup {
  needsSupport('needs_support', 'Cần hỗ trợ'),
  watch('watch', 'Cần theo dõi'),
  onTrack('on_track', 'Đúng tiến độ'),
  unknown('unknown', 'Không rõ');

  final String key, label;
  const WatchGroup(this.key, this.label);

  static WatchGroup fromKey(String? key) => WatchGroup.values.firstWhere(
    (g) => g.key == key,
    orElse: () => WatchGroup.unknown,
  );

  static WatchGroup fromRisk(String? risk) => switch (risk?.toUpperCase()) {
    'HIGH' => WatchGroup.needsSupport,
    'MEDIUM' => WatchGroup.watch,
    'LOW' => WatchGroup.onTrack,
    _ => WatchGroup.unknown,
  };

  int count(WatchGroups g) => switch (this) {
    WatchGroup.needsSupport => g.needsSupport,
    WatchGroup.watch => g.watch,
    WatchGroup.onTrack => g.onTrack,
    WatchGroup.unknown => g.unknown,
  };
}

class StudentSignal {
  final String code, label;

  /// True when the signal is strong enough to be shown in red.
  final bool strong;
  const StudentSignal(this.code, this.label, {this.strong = false});
  StudentSignal.fromJson(Map<String, dynamic> j)
    : code = _string(j['code']) ?? '',
      label = _string(j['label']) ?? '',
      strong = j['strong'] == true;
}

/// Status keys of derived.unified_tasks.
enum TaskState {
  completed('completed'),
  pending('pending'),
  overdue('overdue');

  final String key;
  const TaskState(this.key);
}

/// One assignment or quiz of one student, as listed in a task-status sheet.
class StudentTaskItem {
  final int? sourceId;
  final String title;
  final bool isQuiz;
  final TaskState? state;
  final DateTime? due, submittedAt;

  /// Handed in, but after the due date.
  final bool late;

  /// Opened the activity on Moodle (only meaningful when the course logs activity views).
  final bool viewed;

  /// Has a grade in the Moodle gradebook.
  final bool graded;
  final double? gradePercentage;

  /// Reached the pass mark; null when the activity has no pass mark or no grade yet.
  final bool? passed;

  StudentTaskItem.fromJson(Map<String, dynamic> j)
    : viewed = j['viewed'] == true,
      graded = j['graded'] == true,
      gradePercentage = _double(j['grade_percentage']),
      passed = j['passed'] is bool ? j['passed'] as bool : null,
      sourceId = _int(j['source_id']),
      title = _string(j['title']) ?? 'Hoạt động',
      isQuiz = j['task_type'] == 'quiz',
      state = TaskState.values.where((s) => s.key == j['status']).firstOrNull,
      due = _epoch(j['due_time']),
      submittedAt = _epoch(j['submitted_at']),
      late = j['late'] == true;

  /// Same activity as a low-completion row: same type and same assign/quiz id.
  bool isActivity(String type, int id) =>
      sourceId == id && isQuiz == (type == 'quiz');

  static DateTime? _epoch(Object? v) => (_int(v) ?? 0) > 0
      ? DateTime.fromMillisecondsSinceEpoch(_int(v)! * 1000)
      : null;
}

/// One rule that added points to a student's watch score.
class ScorePoint {
  final int points;
  final String label;
  ScorePoint.fromJson(Map<String, dynamic> j)
    : points = _int(j['points']) ?? 0,
      label = _string(j['label']) ?? '';
}

/// One row of the class warning table: the numbers behind a student's group.
class InsightStudent {
  final int id;
  final String name;
  final String? code, classCode;
  final WatchGroup group;
  final int? riskScore;
  final double? progress, attendance, averageGrade;
  final int markedSessions, absentSessions;

  /// Null means the student has never opened the course (when [detailed]).
  final int? inactiveDays;
  final int completedTasks, totalTasks, overdue;
  final int gradedItems, completedActivities, totalActivities;
  final List<ScorePoint> scoreBreakdown;
  final List<StudentTaskItem> tasks;
  final List<StudentSignal> signals;
  final List<String> actions;

  /// The group rebuilt for 7 days ago; null when the backend does not send it.
  final WatchGroup? previousGroup;

  /// False when built from the older attention list, which lacks most numbers.
  final bool detailed;

  InsightStudent.fromJson(Map<String, dynamic> j)
    : previousGroup = j['previous_group'] is String
          ? WatchGroup.fromKey(j['previous_group'] as String)
          : null,
      id = _int(j['userid']) ?? 0,
      name = _string(j['fullname']) ?? 'Sinh viên #${j['userid']}',
      code = _string(j['student_code']),
      classCode = _string(j['class_code']),
      group = j['group'] is String
          ? WatchGroup.fromKey(j['group'] as String)
          : WatchGroup.fromRisk(_string(j['risk_level'])),
      riskScore = _int(j['risk_score']),
      progress = _double(j['progress']),
      attendance = _double(j['attendance']),
      averageGrade = _double(j['average_grade']),
      markedSessions = _int(j['marked_sessions']) ?? 0,
      absentSessions = _int(j['absent_sessions']) ?? 0,
      inactiveDays = _int(j['days_since_last_activity']),
      completedTasks = _int(j['completed_tasks']) ?? 0,
      totalTasks = _int(j['total_tasks']) ?? 0,
      overdue = _int(j['overdue_tasks']) ?? 0,
      gradedItems = _int(j['graded_items']) ?? 0,
      completedActivities = _int(j['completed_activities']) ?? 0,
      totalActivities = _int(j['total_tracked_activities']) ?? 0,
      scoreBreakdown = _maps(
        j['score_breakdown'],
      ).map(ScorePoint.fromJson).toList(),
      tasks = _maps(j['tasks']).map(StudentTaskItem.fromJson).toList(),
      signals = _maps(j['signals']).map(StudentSignal.fromJson).toList(),
      actions = _strings(j['suggested_actions']),
      detailed = true;

  InsightStudent.fromAttention(AttentionStudent a)
    : previousGroup = null,
      id = a.id,
      name = a.name,
      code = a.code,
      classCode = null,
      group = WatchGroup.fromRisk(a.risk),
      riskScore = null,
      progress = a.progress,
      attendance = null,
      averageGrade = null,
      markedSessions = 0,
      absentSessions = 0,
      inactiveDays = a.inactiveDays,
      completedTasks = 0,
      totalTasks = 0,
      overdue = a.overdue ?? 0,
      gradedItems = 0,
      completedActivities = 0,
      totalActivities = 0,
      scoreBreakdown = const [],
      tasks = const [],
      signals = [for (final r in a.reasons) StudentSignal('', r)],
      actions = a.actions,
      detailed = false;

  /// Assigned work that is neither done nor past due.
  int get notYetDue =>
      (totalTasks - completedTasks - overdue).clamp(0, totalTasks);

  /// How many of this student's tasks are in [state], from the per-task list when present.
  int countIn(TaskState state) => tasks.isNotEmpty
      ? tasks.where((t) => t.state == state).length
      : switch (state) {
          TaskState.completed => completedTasks,
          TaskState.pending => notYetDue,
          TaskState.overdue => overdue,
        };

  bool hasSignal(String code) => signals.any(
    (s) => s.code == code || (code == 'INACTIVE' && s.code == 'NEVER_ACCESSED'),
  );

  /// Same rule as signal_counts on the backend (absence counts from 20%).
  bool matchesCriterion(String code) => code == 'ABSENCE'
      ? signals.any((s) => s.code == 'ABSENCE' && s.strong)
      : hasSignal(code);
}

/// Student × week activity matrix (activity_heatmap).
class ActivityHeatmap {
  final List<DateTime> weeks;
  final int maxEvents, droppedCount, neverActiveCount, dropOffWeeks;
  final List<HeatmapRow> rows;
  ActivityHeatmap.fromJson(Map<String, dynamic> j)
    : weeks = [
        for (final w in (j['weeks'] as List? ?? const []))
          if (_date(w) != null) _date(w)!,
      ],
      maxEvents = _int(j['max_events']) ?? 0,
      droppedCount = _int(j['dropped_count']) ?? 0,
      neverActiveCount = _int(j['never_active_count']) ?? 0,
      dropOffWeeks = _int(j['drop_off_weeks']) ?? 2,
      rows = _maps(j['rows']).map(HeatmapRow.fromJson).toList();
}

enum HeatStatus { dropped, neverActive, active }

class HeatmapRow {
  final int id;
  final String name;
  final String? code;
  final WatchGroup group;
  final List<int> events;
  final int total;
  final HeatStatus status;
  final DateTime? lastActiveWeek, droppedSince;
  HeatmapRow.fromJson(Map<String, dynamic> j)
    : id = _int(j['userid']) ?? 0,
      name = _string(j['fullname']) ?? 'Sinh viên #${j['userid']}',
      code = _string(j['student_code']),
      group = WatchGroup.fromKey(_string(j['group'])),
      events = [
        for (final e in (j['weekly_events'] as List? ?? const [])) _int(e) ?? 0,
      ],
      total = _int(j['total_events']) ?? 0,
      status = switch (j['status']) {
        'dropped' => HeatStatus.dropped,
        'never_active' => HeatStatus.neverActive,
        _ => HeatStatus.active,
      },
      lastActiveWeek = _date(j['last_active_week']),
      droppedSince = _date(j['dropped_since']);
}

enum FollowUpOutcome { returned, noChange, waiting }

/// Did students come back after a teacher's support note (support_followups)?
class SupportFollowUps {
  final int windowDays, total, returned, noChange, waiting;
  final double? returnRate, averageDaysToReturn, averageBefore, averageAfter;
  final List<FollowUp> items;
  SupportFollowUps.fromJson(Map<String, dynamic> j)
    : windowDays = _int(j['window_days']) ?? 7,
      total = _int(j['total']) ?? 0,
      returned = _int(j['returned']) ?? 0,
      noChange = _int(j['no_change']) ?? 0,
      waiting = _int(j['waiting']) ?? 0,
      returnRate = _double(j['return_rate']),
      averageDaysToReturn = _double(j['average_days_to_return']),
      averageBefore = _double(j['average_events_before']),
      averageAfter = _double(j['average_events_after']),
      items = _maps(j['items']).map(FollowUp.fromJson).toList();
}

class FollowUp {
  final int id, studentId, daysSince, eventsBefore, eventsAfter;
  final String name;
  final String? code, note;
  final DateTime? notedAt;
  final FollowUpOutcome outcome;
  final int? daysToReturn;

  /// Sent from the app's "Nhắc" button rather than written as a note.
  final bool isReminder;

  FollowUp.fromJson(Map<String, dynamic> j)
    : isReminder = j['kind'] == 'reminder',
      id = _int(j['id']) ?? 0,
      studentId = _int(j['student_id']) ?? 0,
      name = _string(j['fullname']) ?? 'Sinh viên #${j['student_id']}',
      code = _string(j['student_code']),
      note = _string(j['note']),
      notedAt = _date(j['noted_at'])?.toLocal(),
      daysSince = _int(j['days_since']) ?? 0,
      eventsBefore = _int(j['events_before']) ?? 0,
      eventsAfter = _int(j['events_after']) ?? 0,
      outcome = switch (j['outcome']) {
        'RETURNED' => FollowUpOutcome.returned,
        'NO_CHANGE' => FollowUpOutcome.noChange,
        _ => FollowUpOutcome.waiting,
      },
      daysToReturn = _int(j['days_to_return']);
}

enum ActionKind { remind, contact, review }

/// The assignment/quiz an action item is about.
class ActionActivity {
  final int? sourceId, courseModuleId;
  final String title, type;
  final DateTime? due;
  final String? moodlePath;
  ActionActivity.fromJson(Map<String, dynamic> j)
    : sourceId = _int(j['source_id']),
      courseModuleId = _int(j['coursemoduleid']),
      title = _string(j['title']) ?? 'Hoạt động',
      type = _string(j['task_type']) ?? 'assignment',
      due = (_int(j['due_time']) ?? 0) > 0
          ? DateTime.fromMillisecondsSinceEpoch(_int(j['due_time'])! * 1000)
          : null,
      moodlePath = _string(j['moodle_path']);
}

/// One line of "Việc cần làm tuần này". The app writes the wording from [code].
class ActionItem {
  final String code;
  final ActionKind action;
  final List<int> studentIds;
  final ActionActivity? activity;
  final int? days;
  final double? lateRate, missingRate;
  ActionItem.fromJson(Map<String, dynamic> j)
    : code = _string(j['code']) ?? '',
      action = switch (j['action']) {
        'REMIND' => ActionKind.remind,
        'REVIEW' => ActionKind.review,
        _ => ActionKind.contact,
      },
      studentIds = [
        for (final v in (j['student_ids'] as List? ?? const [])) ?_int(v),
      ],
      activity = j['activity'] is Map
          ? ActionActivity.fromJson(_map(j['activity']))
          : null,
      days = _int(j['days']),
      lateRate = _double(j['late_rate']),
      missingRate = _double(j['missing_rate']);
}

/// A student whose group differs from the one rebuilt for a week ago.
class GroupMove {
  final int id;
  final String name;
  final WatchGroup from, to;
  GroupMove.fromJson(Map<String, dynamic> j)
    : id = _int(j['userid']) ?? 0,
      name = _string(j['fullname']) ?? 'Sinh viên #${j['userid']}',
      from = WatchGroup.fromKey(_string(j['from'])),
      to = WatchGroup.fromKey(_string(j['to']));
}

/// Class numbers now versus rebuilt for 7 days ago (weekly_change).
class WeeklyChange {
  final DateTime? asOf;
  final Map<WatchGroup, int> before, now;
  final double? progressBefore, progressNow;
  final int overdueBefore, overdueNow;
  final List<GroupMove> worsened, improved;

  WeeklyChange.fromJson(Map<String, dynamic> j)
    : asOf = _date(j['as_of'])?.toLocal(),
      before = _groupCounts(_map(j['previous'])),
      now = _groupCounts(_map(j['current'])),
      progressBefore = _double(_map(j['previous'])['average_progress']),
      progressNow = _double(_map(j['current'])['average_progress']),
      overdueBefore = _int(_map(j['previous'])['overdue_students']) ?? 0,
      overdueNow = _int(_map(j['current'])['overdue_students']) ?? 0,
      worsened = _maps(j['worsened']).map(GroupMove.fromJson).toList(),
      improved = _maps(j['improved']).map(GroupMove.fromJson).toList();

  static Map<WatchGroup, int> _groupCounts(Map<String, dynamic> m) => {
    WatchGroup.needsSupport: _int(m['needs_support']) ?? 0,
    WatchGroup.watch: _int(m['watch']) ?? 0,
    WatchGroup.onTrack: _int(m['on_track']) ?? 0,
  };

  /// Change in "Cần chú ý" (needs support + watch) since last week.
  int get watchDelta =>
      (now[WatchGroup.needsSupport]! + now[WatchGroup.watch]!) -
      (before[WatchGroup.needsSupport]! + before[WatchGroup.watch]!);
}

class ClassTaskStatus {
  final int total, completed, pending, overdue;
  ClassTaskStatus.fromJson(Map<String, dynamic> j)
    : total = _int(j['total']) ?? 0,
      completed = _int(j['completed']) ?? 0,
      pending = _int(j['pending']) ?? 0,
      overdue = _int(j['overdue']) ?? 0;
}

class WeekPoint {
  final DateTime weekStart;
  final int activeStudents, events, completed;
  const WeekPoint(
    this.weekStart,
    this.activeStudents,
    this.events,
    this.completed,
  );
}

class WeeklyTrend {
  final int studentCount;
  final bool engagementAvailable, completionAvailable;
  final List<WeekPoint> points;
  WeeklyTrend.fromJson(Map<String, dynamic> j)
    : studentCount = _int(j['student_count']) ?? 0,
      engagementAvailable = j['engagement_available'] == true,
      completionAvailable = j['completion_available'] == true,
      points = [
        for (final p in _maps(j['points']))
          if (_date(p['week_start']) != null)
            WeekPoint(
              _date(p['week_start'])!,
              _int(p['active_students']) ?? 0,
              _int(p['events']) ?? 0,
              _int(p['completed_activities']) ?? 0,
            ),
      ];
}

class LowCompletionActivity {
  final String title, type;
  final bool duePassed;
  final int studentCount, doneCount;
  final double? rate;
  final String? note, moodlePath;
  final int? courseModuleId, sourceId;
  final DateTime? due;
  LowCompletionActivity.fromJson(Map<String, dynamic> j)
    : sourceId = _int(j['source_id']),
      title = _string(j['title']) ?? 'Hoạt động',
      type = _string(j['task_type']) ?? '',
      duePassed = j['due_passed'] == true,
      studentCount = _int(j['student_count']) ?? 0,
      doneCount = _int(j['done_count']) ?? 0,
      rate = _double(j['completion_rate']),
      note = _string(j['note']),
      moodlePath = _string(j['moodle_path']),
      courseModuleId = _int(j['coursemoduleid']),
      due = (_int(j['due_time']) ?? 0) > 0
          ? DateTime.fromMillisecondsSinceEpoch(_int(j['due_time'])! * 1000)
          : null;
}

class Intervention {
  final String code, title, reason;
  final DateTime? createdAt;
  Intervention.fromJson(Map<String, dynamic> j)
    : code = _string(j['code']) ?? '',
      title = _string(j['title']) ?? '',
      reason = _string(j['reason']) ?? '',
      createdAt = _date(j['created_at']);
}
