import 'package:flutter/material.dart';

import '../../models/teacher_course.dart';
import '../../services/api_service.dart';
import '../../widgets/async_tab.dart';
import '../../widgets/learning_widgets.dart';
import 'teacher_course_detail_screen.dart';

class TeacherCoursesScreen extends StatefulWidget {
  final ApiService? apiService;
  const TeacherCoursesScreen({super.key, this.apiService});
  @override
  State<TeacherCoursesScreen> createState() => _TeacherCoursesScreenState();
}

class _TeacherCoursesScreenState extends State<TeacherCoursesScreen> {
  late final ApiService _api = widget.apiService ?? ApiService();
  @override
  void dispose() {
    if (widget.apiService == null) _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Khóa học giảng dạy'),
      automaticallyImplyLeading: false,
    ),
    body: SafeArea(
      child: AsyncTab<List<TeacherCourse>>(
        load: () => _api.getTeacherCourses(),
        children: (courses) => courses.isEmpty
            ? [
                const EmptyState(
                  'Bạn chưa được phân công',
                  subtitle: 'Hiện chưa có khóa học nào hiển thị ở đây.',
                  icon: Icons.folder_open_rounded,
                ),
              ]
            : [
                for (final course in courses)
                  TeacherCourseCard(
                    course: course,
                    onTap: () => _openCourse(course),
                  ),
              ],
      ),
    ),
  );

  void _openCourse(TeacherCourse course) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => TeacherCourseDetailScreen(
        course: course,
        apiService: widget.apiService,
      ),
    ),
  );
}
