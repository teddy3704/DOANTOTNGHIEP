import 'remind_one.dart';
import '../../core/display_text.dart';
import '../../core/date_time_text.dart';

import 'package:flutter/material.dart';

import '../../models/teacher_monitoring.dart';
import '../../models/student_course_detail.dart';
import '../../services/api_service.dart';
import '../../widgets/async_tab.dart';
import '../../widgets/learning_widgets.dart';
import '../../widgets/moodle_button.dart';
import 'student_overview_details.dart';

class TeacherStudentsTab extends StatefulWidget {
  final ApiService api;
  final int courseId;
  final String initialFilter;
  final int filterRequestId;
  const TeacherStudentsTab({
    super.key,
    required this.api,
    required this.courseId,
    this.initialFilter = 'all',
    this.filterRequestId = 0,
  });
  @override
  State<TeacherStudentsTab> createState() => _TeacherStudentsTabState();
}

class _TeacherStudentsTabState extends State<TeacherStudentsTab> {
  late String _filter = widget.initialFilter;
  String _query = '';
  String? _cohort;
  final _search = TextEditingController();
  final _filters = ScrollController();
  final _filterKeys = {
    for (final value in ['all', 'support', 'overdue', 'low', 'HIGH'])
      value: GlobalKey(),
  };
  bool _revealFilter = true;
  @override
  void dispose() {
    _search.dispose();
    _filters.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TeacherStudentsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter ||
        oldWidget.filterRequestId != widget.filterRequestId) {
      _filter = widget.initialFilter;
      _query = '';
      _cohort = null;
      _search.clear();
      _revealFilter = true;
    }
  }

  @override
  Widget build(BuildContext context) => AsyncTab<List<MonitoredStudent>>(
    load: () => widget.api.getTeacherStudents(widget.courseId),
    children: (students) {
      if (_revealFilter) {
        _revealFilter = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final target = _filterKeys[_filter]?.currentContext
              ?.findRenderObject();
          if (mounted && _filters.hasClients && target != null) {
            _filters.position.ensureVisible(target, alignment: .5);
          }
        });
      }
      final cohorts =
          students.map((s) => s.cohortCode).whereType<String>().toSet().toList()
            ..sort();
      final selectedCohort = cohorts.contains(_cohort) ? _cohort : null;
      final hasAttentionFlag = students.any((s) => s.needsAttention != null);
      final filtered = students
          .where(
            (s) =>
                ('${s.name} ${s.studentCode ?? ''} ${s.email ?? ''}')
                    .toLowerCase()
                    .contains(_query.trim().toLowerCase()) &&
                (selectedCohort == null || s.cohortCode == selectedCohort) &&
                switch (_filter) {
                  'support' => s.needsSupport,
                  'overdue' => (s.overdue ?? 0) > 0,
                  'low' => s.progress != null && s.progress! < 40,
                  'HIGH' => s.risk?.toUpperCase() == 'HIGH',
                  _ => true,
                },
          )
          .toList();
      return [
        TextField(
          controller: _search,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Tìm theo tên, MSSV hoặc email',
            hintMaxLines: 2,
            hintStyle: Theme.of(context).textTheme.bodySmall,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 12),
        LearningFilterBar(
          controller: _filters,
          wrap: true,
          children: [
            for (final (value, label) in [
              ('all', 'Tất cả'),
              ('support', hasAttentionFlag ? 'Cần theo dõi' : 'Có nguy cơ'),
              ('overdue', 'Quá hạn'),
              ('low', 'Tiến độ thấp'),
              ('HIGH', 'Nguy cơ cao'),
            ])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  key: _filterKeys[value],
                  label: Text(label),
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  selected: _filter == value,
                  onSelected: (_) => setState(() {
                    _filter = value;
                    _revealFilter = true;
                  }),
                ),
              ),
          ],
        ),
        if (cohorts.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Khóa tuyển', style: Theme.of(context).textTheme.labelLarge),
          LearningFilterBar(
            key: const ValueKey('cohort_filters'),
            wrap: true,
            children: [
              for (final code in <String?>[null, ...cohorts])
                ChoiceChip(
                  label: Text(code ?? 'Tất cả'),
                  selected: selectedCohort == code,
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  onSelected: (_) => setState(() => _cohort = code),
                ),
            ],
          ),
        ],
        if (_filter == 'support')
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              hasAttentionFlag
                  ? 'Sinh viên được đánh dấu cần theo dõi trong dữ liệu khóa học.'
                  : 'Sinh viên có mức nguy cơ cao hoặc trung bình trong dữ liệu khóa học.',
            ),
          ),
        if (filtered.isEmpty)
          EmptyState(
            _filter == 'support'
                ? 'Không có sinh viên cần theo dõi'
                : _filter == 'HIGH'
                ? 'Không có sinh viên nguy cơ cao'
                : 'Không có sinh viên phù hợp',
          ),
        for (final student in filtered)
          StudentMonitoringCard(
            student: student,
            onOpen: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentMonitoringDetailScreen(
                  api: widget.api,
                  courseId: widget.courseId,
                  userId: student.id,
                  name: student.name,
                ),
              ),
            ),
          ),
      ];
    },
  );
}

class StudentMonitoringCard extends StatelessWidget {
  final MonitoredStudent student;
  final VoidCallback onOpen;
  const StudentMonitoringCard({
    super.key,
    required this.student,
    required this.onOpen,
  });
  @override
  Widget build(BuildContext context) => DetailCard(
    title: student.name,
    onTap: onOpen,
    trailing: const Icon(Icons.chevron_right, size: 20),
    children: [
      if (student.identityLabel != null)
        Text(
          student.identityLabel!,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      if (student.academicLabel != null)
        Text(
          student.academicLabel!,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      if (student.majorName != null)
        Text(student.majorName!, style: Theme.of(context).textTheme.bodySmall),
      Text('Tiến độ: ${detailValue(student.progress, suffix: '%')}'),
      if (student.progress != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: LinearProgressIndicator(
            value: (student.progress! / 100).clamp(0, 1),
          ),
        ),
      Wrap(
        spacing: 12,
        runSpacing: 4,
        children: [
          Text(
            '${detailValue(student.pending)} việc chưa hoàn thành',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            '${detailValue(student.overdue)} việc quá hạn',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: (student.overdue ?? 0) > 0
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
          ),
        ],
      ),
      if (student.attendance != null)
        Text('Chuyên cần: ${detailValue(student.attendance, suffix: '%')}'),
      Text(student.activityLabel, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 4),
      if (student.riskReasons.isEmpty && student.supportBasisLabel != null)
        Text(
          student.supportBasisLabel!,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      Wrap(
        children: [
          StatusChip(
            student.riskLabel,
            danger: student.risk?.toUpperCase() == 'HIGH',
            warning: student.risk?.toUpperCase() == 'MEDIUM',
          ),
        ],
      ),
    ],
  );
}

class StudentMonitoringDetailScreen extends StatelessWidget {
  final ApiService api;
  final int courseId, userId;
  final String name;
  const StudentMonitoringDetailScreen({
    super.key,
    required this.api,
    required this.courseId,
    required this.userId,
    required this.name,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(name)),
    body: AsyncTab<MonitoredStudent>(
      load: () => api.getMonitoredStudent(courseId, userId),
      children: (s) => [
        DetailCard(
          title: s.name,
          children: [
            if (s.studentCode != null)
              Text('MSSV: ${s.studentCode}')
            else if (!s.hasAcademicProfile && s.email != null)
              Text(s.email!),
            if (s.academicLabel != null)
              Text(
                s.academicLabel!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 8),
            Wrap(
              children: [
                StatusChip(
                  s.riskLabel,
                  danger: s.risk?.toUpperCase() == 'HIGH',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) => FilledButton.tonalIcon(
                key: const Key('remind-one'),
                onPressed: () => remindOne(
                  context,
                  api: api,
                  courseId: courseId,
                  userId: userId,
                  facts: factsFromMonitored(s),
                ),
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Nhắc riêng'),
              ),
            ),
          ],
        ),
        if (s.hasAcademicProfile)
          DetailCard(
            title: 'Thông tin học vụ',
            children: [
              DetailLine('MSSV', s.studentCode ?? 'Chưa có dữ liệu'),
              DetailLine('Khóa tuyển', s.cohortCode ?? 'Chưa có dữ liệu'),
              DetailLine('Lớp', s.classCode ?? 'Chưa có dữ liệu'),
              DetailLine('Ngành', s.majorName ?? 'Chưa có dữ liệu'),
              if (s.email != null) DetailLine('Email', s.email!),
            ],
          ),
        DetailCard(
          title: 'Lý do cần theo dõi',
          children: [
            if (s.riskReasons.isEmpty) ...[
              if (s.supportBasisLabel != null) Text(s.supportBasisLabel!),
              Text(
                s.riskExplanationFallback,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            for (final reason in s.riskReasons) MonitoringReasonRow(reason),
          ],
        ),
        const SectionHeader('Tổng quan'),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Nhấn vào từng ô để xem cách tính và chi tiết.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        StudentOverviewDetails(student: s),
        const SectionHeader('Việc cần làm trong khóa học'),
        if (s.tasks.isEmpty)
          const EmptyState('Sinh viên chưa có việc cần làm trong khóa học'),
        ...StudentTask.sorted(
          s.tasks,
          DateTime.now(),
        ).map((t) => TaskCard(t, actionOverride: 'Mở trên LMS để quản lý')),
      ],
    ),
  );
}

class TeacherActivitiesTab extends StatelessWidget {
  final ApiService api;
  final int courseId;
  final String type;
  const TeacherActivitiesTab({
    super.key,
    required this.api,
    required this.courseId,
    required this.type,
  });
  @override
  Widget build(BuildContext context) => AsyncTab<List<MonitoredActivity>>(
    load: () => api.getTeacherActivities(courseId, type),
    children: (activities) => [
      if (activities.isEmpty)
        EmptyState(
          type == 'assignment'
              ? 'Khóa học chưa có bài tập'
              : 'Khóa học chưa có bài kiểm tra',
        ),
      for (final activity in activities)
        DetailCard(
          title: DemoDisplayNames.activity(activity.title),
          children: [
            DetailLine(
              type == 'assignment' ? 'Hạn nộp' : 'Đóng lúc',
              formatDeadline(activity.deadline),
            ),
            if (activity.deadline != null)
              Builder(
                builder: (context) {
                  final state = activityDeadlineState(
                    activity.deadline,
                    quiz: type == 'quiz',
                  );
                  return state == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Wrap(
                            children: [
                              StatusChip(
                                state,
                                warning: state == 'Sắp đến hạn',
                              ),
                            ],
                          ),
                        );
                },
              ),
            CompactMetrics({
              type == 'assignment' ? 'Đã nộp' : 'Đã hoàn tất':
                  '${detailValue(activity.done)} / ${detailValue(activity.total)}',
              type == 'assignment' ? 'Chưa nộp' : 'Chưa hoàn tất': detailValue(
                activity.notDone,
              ),
              if (activity.needsGrading != null)
                'Cần chấm': detailValue(activity.needsGrading),
              if (activity.notAttempted != null)
                'Chưa bắt đầu': detailValue(activity.notAttempted),
              if (activity.inProgress != null)
                'Đang làm': detailValue(activity.inProgress),
            }, inline: true),
            if (activity.done != null &&
                activity.total != null &&
                activity.total! > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(
                  value: (activity.done! / activity.total!).clamp(0, 1),
                ),
              ),
            if ((activity.unknown ?? 0) > 0)
              DetailLine(
                'Chưa xác định trạng thái',
                '${activity.unknown} sinh viên',
              ),
            if ((activity.needsGrading ?? 0) > 0)
              Text(
                'Cần chấm: đã nộp và chưa có điểm hoạt động.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (activity.average != null)
              DetailLine(
                type == 'quiz'
                    ? 'Trung bình các điểm đã ghi nhận'
                    : 'Trung bình các hoạt động đã chấm',
                detailValue(activity.average, suffix: '%'),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ActivityStudentsScreen(
                        api: api,
                        courseId: courseId,
                        activity: activity,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.people_outline),
                  label: const Text('Xem sinh viên'),
                ),
                MoodleButton(
                  path: activity.moodlePath,
                  courseModuleId: activity.courseModuleId,
                  label: 'Mở trên LMS để quản lý',
                  compact: true,
                ),
              ],
            ),
          ],
        ),
    ],
  );
}

class ActivityStudentsScreen extends StatelessWidget {
  final ApiService api;
  final int courseId;
  final MonitoredActivity activity;
  const ActivityStudentsScreen({
    super.key,
    required this.api,
    required this.courseId,
    required this.activity,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(DemoDisplayNames.activity(activity.title))),
    body: AsyncTab<List<ActivityStudent>>(
      load: () => api.getActivityStudents(courseId, activity),
      children: (students) => [
        MoodleButton(
          path: activity.moodlePath,
          courseModuleId: activity.courseModuleId,
          label: 'Mở trên LMS để quản lý',
        ),
        if (students.isEmpty)
          const EmptyState('Chưa có sinh viên trong hoạt động này'),
        if (students.isNotEmpty &&
            students.every(
              (s) =>
                  s.groupLabel(activity.type) ==
                  (activity.type == 'assignment' ? 'Đã nộp' : 'Đã hoàn tất'),
            ))
          EmptyState(
            activity.type == 'assignment'
                ? 'Tất cả sinh viên đã nộp'
                : 'Tất cả sinh viên đã hoàn tất',
          ),
        for (final group
            in (activity.type == 'assignment'
                ? ['Đã nộp', 'Chưa nộp', 'Chưa có trạng thái']
                : [
                    'Đã hoàn tất',
                    'Đang làm',
                    'Chưa bắt đầu',
                    'Chưa hoàn tất',
                    'Chưa có trạng thái',
                  ])) ...[
          if (students.any((s) => s.groupLabel(activity.type) == group))
            SectionHeader(
              '$group (${students.where((s) => s.groupLabel(activity.type) == group).length})',
            ),
          for (final row in students.where(
            (s) => s.groupLabel(activity.type) == group,
          ))
            DetailCard(
              title: row.student.name,
              children: [
                Wrap(children: [StatusChip(row.status)]),
                if (row.student.identityLabel != null)
                  Text(row.student.identityLabel!),
                DetailLine(
                  'Điểm hoạt động',
                  row.gradePercentage != null
                      ? formatPercentageVi(row.gradePercentage)
                      : row.grade == null
                      ? 'Chưa chấm'
                      : row.grade == 0
                      ? formatPercentageVi(0)
                      : detailValue(row.grade),
                ),
                if (row.grade != null || row.gradePercentage != null)
                  const Wrap(children: [StatusChip('Đã chấm')]),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentMonitoringDetailScreen(
                        api: api,
                        courseId: courseId,
                        userId: row.student.id,
                        name: row.student.name,
                      ),
                    ),
                  ),
                  child: const Text('Xem chi tiết'),
                ),
              ],
            ),
        ],
      ],
    ),
  );
}
