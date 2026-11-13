import 'package:flutter/material.dart';
import '../../core/data_profile.dart';

import '../../models/student_course_detail.dart';
import '../../services/api_service.dart';
import '../../widgets/async_tab.dart';
import '../../widgets/learning_widgets.dart';

enum TaskFilter { all, pending, soon, overdue, done }

List<StudentTask> filterTasks(
  List<StudentTask> tasks,
  TaskFilter filter,
  DateTime now,
) => StudentTask.sorted(
  tasks
      .where(
        (t) => switch (filter) {
          TaskFilter.all => true,
          TaskFilter.pending => t.isPending,
          TaskFilter.soon => t.isDueSoon(now),
          TaskFilter.overdue => t.isOverdue(now),
          TaskFilter.done => t.isDone,
        },
      )
      .toList(),
  now,
);

class StudentTaskCenterScreen extends StatefulWidget {
  final ApiService api;
  final bool reminders;
  const StudentTaskCenterScreen({
    super.key,
    required this.api,
    this.reminders = false,
  });
  @override
  State<StudentTaskCenterScreen> createState() =>
      _StudentTaskCenterScreenState();
}

class _StudentTaskCenterScreenState extends State<StudentTaskCenterScreen> {
  TaskFilter _filter = TaskFilter.all;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.reminders ? 'Nhắc hạn học tập' : DataProfile.tasksTitle,
      ),
    ),
    body: AsyncTab<List<StudentTask>>(
      load: widget.api.getAllStudentTasks,
      children: (tasks) {
        final now = DateTime.now();
        final visible = widget.reminders
            ? StudentTask.sorted(
                tasks
                    .where((t) => t.isOverdue(now) || t.isDueSoon(now))
                    .toList(),
                now,
              )
            : filterTasks(tasks, _filter, now);

        final overdue = visible
            .where((t) => t.isOverdue(now) && !t.isDone)
            .toList();
        final today = visible.where((t) {
          if (t.isDone || t.deadline == null || t.isOverdue(now)) return false;
          final hours = t.deadline!.difference(now).inHours;
          return hours >= 0 && hours <= 24 && t.deadline!.day == now.day;
        }).toList();

        final next48h = visible.where((t) {
          if (t.isDone ||
              t.deadline == null ||
              t.isOverdue(now) ||
              today.contains(t)) {
            return false;
          }
          final hours = t.deadline!.difference(now).inHours;
          return hours >= 0 && hours <= 48;
        }).toList();

        final thisWeek = visible.where((t) {
          if (t.isDone ||
              t.deadline == null ||
              t.isOverdue(now) ||
              today.contains(t) ||
              next48h.contains(t)) {
            return false;
          }
          final days = t.deadline!.difference(now).inDays;
          return days >= 0 && days <= 7;
        }).toList();

        final later = visible.where((t) {
          if (t.isDone ||
              t.deadline == null ||
              t.isOverdue(now) ||
              today.contains(t) ||
              next48h.contains(t) ||
              thisWeek.contains(t)) {
            return false;
          }
          return true;
        }).toList();

        final done = visible.where((t) => t.isDone).toList();

        return [
          if (widget.reminders)
            const Text(
              'Tổng hợp từ hạn nộp trong các khóa học. Cập nhật khi tải lại.',
            ),
          if (!widget.reminders)
            LearningFilterBar(
              wrap: true,
              children: [
                for (final (filter, label) in [
                  (TaskFilter.all, 'Tất cả'),
                  (TaskFilter.pending, 'Chưa làm'),
                  (TaskFilter.soon, 'Sắp hạn'),
                  (TaskFilter.overdue, 'Quá hạn'),
                  (TaskFilter.done, 'Đã xong'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selectedColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            EmptyState(
              widget.reminders
                  ? 'Bạn chưa có việc sắp hạn hoặc quá hạn'
                  : !tasks.any((t) => t.isPending) &&
                        (_filter == TaskFilter.pending ||
                            _filter == TaskFilter.all)
                  ? 'Bạn đã hoàn thành tất cả việc cần làm'
                  : 'Không có việc trong bộ lọc này',
            ),

          if (_filter == TaskFilter.all ||
              _filter == TaskFilter.pending ||
              widget.reminders) ...[
            if (overdue.isNotEmpty) ...[
              SectionHeader('Quá hạn (${overdue.length})'),
              ...overdue.map(TaskCard.new),
            ],
            if (today.isNotEmpty) ...[
              SectionHeader('Hôm nay (${today.length})'),
              ...today.map(TaskCard.new),
            ],
            if (next48h.isNotEmpty) ...[
              SectionHeader('48 giờ tới (${next48h.length})'),
              ...next48h.map(TaskCard.new),
            ],
            if (thisWeek.isNotEmpty) ...[
              SectionHeader('Tuần này (${thisWeek.length})'),
              ...thisWeek.map(TaskCard.new),
            ],
            if (later.isNotEmpty) ...[
              SectionHeader('Sắp tới (${later.length})'),
              ...later.map(TaskCard.new),
            ],
          ] else ...[
            ...visible.map(TaskCard.new),
          ],

          if (_filter == TaskFilter.all && done.isNotEmpty) ...[
            SectionHeader('Đã hoàn thành (${done.length})'),
            ...done.map(TaskCard.new),
          ],
        ];
      },
    ),
  );
}
