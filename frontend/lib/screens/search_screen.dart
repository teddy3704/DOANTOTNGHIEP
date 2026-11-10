import 'dart:async';

import 'package:flutter/material.dart';

import '../models/search_hit.dart';
import '../models/student_course.dart';
import '../models/teacher_course.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../widgets/learning_widgets.dart';
import '../widgets/moodle_button.dart';
import 'student/student_course_detail_screen.dart';
import 'teacher/teacher_course_detail_screen.dart';
import 'teacher/teacher_monitoring_screens.dart';

const searchGroupLabels = {
  'course': 'Khóa học',
  'task': 'Việc cần làm',
  'activity': 'Hoạt động, tài liệu',
  'flashcard': 'Thẻ ghi nhớ',
  'student': 'Sinh viên',
  'assignment': 'Bài tập',
  'quiz': 'Bài kiểm tra',
};

/// V2-N13 quick search for the student or the teacher (accent-insensitive, done by the server).
class SearchScreen extends StatefulWidget {
  final ApiService api;
  final bool teacher;
  final Duration debounce;
  const SearchScreen({
    super.key,
    required this.api,
    this.teacher = false,
    this.debounce = const Duration(milliseconds: 300),
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _timer;
  List<SearchHit>? _hits;
  Object? _error;
  bool _loading = false;
  int _seq = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String q) {
    _timer?.cancel();
    if (q.trim().length < 2) {
      setState(() {
        _hits = null;
        _error = null;
        _loading = false;
      });
      return;
    }
    _timer = Timer(widget.debounce, () => _run(q.trim()));
  }

  Future<void> _run(String q) async {
    final seq = ++_seq;
    setState(() => _loading = true);
    try {
      final hits = await widget.api.search(q, teacher: widget.teacher);
      if (!mounted || seq != _seq) return;
      setState(() {
        _hits = hits;
        _error = null;
      });
    } catch (e) {
      if (mounted && seq == _seq) setState(() => _error = e);
    } finally {
      if (mounted && seq == _seq) setState(() => _loading = false);
    }
  }

  void _open(SearchHit h) {
    final course = h.courseId;
    Widget? page;
    if (widget.teacher &&
        h.type == 'student' &&
        h.userId != null &&
        course != null) {
      page = StudentMonitoringDetailScreen(
        api: widget.api,
        courseId: course,
        userId: h.userId!,
        name: h.title,
      );
    } else if (widget.teacher && course != null) {
      page = TeacherCourseDetailScreen(
        course: TeacherCourse(
          courseId: course,
          courseName: h.type == 'course' ? h.title : (h.subtitle ?? 'Khóa học'),
        ),
        apiService: widget.api,
        initialTab: switch (h.type) {
          'assignment' => 2,
          'quiz' => 3,
          _ => 0,
        },
      );
    } else if (!widget.teacher && course != null) {
      page = StudentCourseDetailScreen(
        course: StudentCourse(
          courseId: course,
          courseName: h.type == 'course'
              ? h.title
              : (h.subtitle?.split(' · ').first ?? 'Khóa học'),
        ),
        apiService: widget.api,
      );
    }
    if (page != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => page!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hits = _hits;
    final groups = <String, List<SearchHit>>{};
    for (final h in hits ?? const <SearchHit>[]) {
      groups.putIfAbsent(h.type, () => []).add(h);
    }
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          key: const Key('search-field'),
          controller: _controller,
          autofocus: true,
          maxLength: 100,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: widget.teacher
                ? 'Tìm khóa học, sinh viên, MSSV, bài…'
                : 'Tìm khóa học, bài, tài liệu, thẻ…',
            border: InputBorder.none,
            counterText: '',
          ),
          onChanged: _changed,
          onSubmitted: (q) {
            _timer?.cancel();
            if (q.trim().length >= 2) _run(q.trim());
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            EmptyState(apiErrorMessage(_error!), icon: Icons.cloud_off)
          else if (hits != null && hits.isEmpty)
            const EmptyState('Không tìm thấy kết quả', icon: Icons.search_off),
          for (final g in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                searchGroupLabels[g.key] ?? g.key,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            for (final h in g.value)
              ListTile(
                key: Key('search-hit-${h.type}-${h.title}'),
                title: Text(h.title),
                subtitle: h.subtitle == null ? null : Text(h.subtitle!),
                onTap: () => _open(h),
                trailing: h.moodlePath != null && h.courseModuleId != null
                    ? MoodleButton(
                        path: h.moodlePath,
                        courseModuleId: h.courseModuleId,
                        compact: true,
                      )
                    : null,
              ),
          ],
        ],
      ),
    );
  }
}
