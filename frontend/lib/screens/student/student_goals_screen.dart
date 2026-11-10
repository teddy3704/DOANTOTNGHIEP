import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';

import '../../models/learning_goal.dart';
import '../../models/student_course.dart';
import '../../services/api_service.dart';

class StudentGoalsScreen extends StatefulWidget {
  final ApiService api;
  const StudentGoalsScreen({super.key, required this.api});

  @override
  State<StudentGoalsScreen> createState() => _StudentGoalsScreenState();
}

class _StudentGoalsScreenState extends State<StudentGoalsScreen> {
  late Future<List<LearningGoal>> _goalsFuture;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  void _loadGoals() {
    setState(() {
      _goalsFuture = widget.api.getStudentGoals();
    });
  }

  Future<void> _cancelGoal(LearningGoal goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy mục tiêu'),
        content: Text('Bạn có chắc chắn muốn hủy mục tiêu "${goal.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hủy mục tiêu'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await widget.api.cancelStudentGoal(goal.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy mục tiêu thành công')),
        );
        _loadGoals();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          _CreateGoalDialog(api: widget.api, onCreated: _loadGoals),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mục tiêu học tập')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<LearningGoal>>(
        future: _goalsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Lỗi: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: _loadGoals,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final goals = snapshot.data;
          if (goals == null || goals.isEmpty) {
            return const Center(child: Text('Chưa có mục tiêu học tập nào.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadGoals();
              await _goalsFuture;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];
                return _GoalCard(goal: goal, onCancel: () => _cancelGoal(goal));
              },
            ),
          );
        },
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final LearningGoal goal;
  final VoidCallback onCancel;

  const _GoalCard({required this.goal, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (goal.status) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'expired':
      case 'cancelled':
        statusColor = context.muted;
        break;
      default:
        statusColor = Theme.of(context).colorScheme.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    goal.statusLabel,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: statusColor,
                  padding: EdgeInsets.zero,
                ),
                if (goal.isActive)
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    onPressed: onCancel,
                    tooltip: 'Hủy mục tiêu',
                  ),
              ],
            ),
            if (goal.courseName != null) ...[
              const SizedBox(height: 4),
              Text(
                'Khóa học: ${goal.courseName}',
                style: TextStyle(
                  color: context.muted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (goal.progressPercent != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hiện tại: ${goal.current?.toStringAsFixed(1) ?? 0} ${goal.unit}',
                  ),
                  Text('${goal.progressPercent?.toStringAsFixed(1)}%'),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (goal.progressPercent! / 100).clamp(0.0, 1.0),
                backgroundColor: context.hairline,
                color: goal.achieved
                    ? Colors.green
                    : Theme.of(context).colorScheme.primary,
                minHeight: 8,
              ),
            ] else ...[
              Text(
                'Chưa có dữ liệu tiến độ',
                style: TextStyle(color: context.muted),
              ),
            ],
            if (goal.attentionLabel != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    goal.attentionLabel!,
                    style: const TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ],
              ),
            ],
            if (goal.basis != null) ...[
              const SizedBox(height: 12),
              Text(
                goal.basis!,
                style: TextStyle(color: context.muted, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CreateGoalDialog extends StatefulWidget {
  final ApiService api;
  final VoidCallback onCreated;

  const _CreateGoalDialog({required this.api, required this.onCreated});

  @override
  State<_CreateGoalDialog> createState() => _CreateGoalDialogState();
}

class _CreateGoalDialogState extends State<_CreateGoalDialog> {
  GoalType _selectedType = GoalType.completionPercentage;
  final _targetController = TextEditingController(text: '100');
  DateTime? _endDate;
  bool _isLoading = false;
  List<StudentCourse>? _courses;
  int? _selectedCourseId;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final courses = await widget.api.getStudentCourses();
      if (mounted) setState(() => _courses = courses);
    } catch (e) {
      // ignore
    }
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final target = double.tryParse(_targetController.text.trim());
    if (target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mục tiêu hợp lệ')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.api.createStudentGoal({
        'goal_type': _selectedType.apiValue,
        'target_value': target,
        'course_id': _selectedCourseId,
        'end_date': _endDate?.toIso8601String().split('T')[0],
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo mục tiêu thành công')),
        );
        widget.onCreated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm mục tiêu mới'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Loại mục tiêu'),
            DropdownButton<GoalType>(
              isExpanded: true,
              value: _selectedType,
              items: GoalType.values.map((type) {
                return DropdownMenuItem(value: type, child: Text(type.label));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedType = val);
              },
            ),
            const SizedBox(height: 16),
            const Text('Khóa học (tùy chọn)'),
            if (_courses == null)
              const LinearProgressIndicator()
            else
              DropdownButton<int?>(
                isExpanded: true,
                value: _selectedCourseId,
                hint: const Text('Tất cả khóa học'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Tất cả khóa học'),
                  ),
                  ..._courses!.map(
                    (c) => DropdownMenuItem<int?>(
                      value: c.courseId,
                      child: Text(
                        c.courseName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (val) => setState(() => _selectedCourseId = val),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _targetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Giá trị mục tiêu (${_selectedType.unit})',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Hạn chót: '),
                TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) setState(() => _endDate = date);
                  },
                  child: Text(
                    _endDate == null
                        ? 'Chọn ngày'
                        : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                  ),
                ),
                if (_endDate != null)
                  IconButton(
                    tooltip: 'Xóa ngày kết thúc',
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () => setState(() => _endDate = null),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _create,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Tạo mới'),
        ),
      ],
    );
  }
}
