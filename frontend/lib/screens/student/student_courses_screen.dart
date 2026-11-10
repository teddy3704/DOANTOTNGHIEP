import 'package:flutter/material.dart';

import '../../models/student_course.dart';
import '../../services/api_service.dart';
import '../../widgets/async_tab.dart';
import '../../widgets/learning_widgets.dart';
import 'student_course_detail_screen.dart';

class StudentCoursesScreen extends StatefulWidget {
  final ApiService? apiService;
  const StudentCoursesScreen({super.key, this.apiService});

  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen> {
  late final ApiService _apiService = widget.apiService ?? ApiService();

  @override
  void dispose() {
    if (widget.apiService == null) _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Khóa học')),
      body: AsyncTab<List<StudentCourse>>(
        load: _apiService.getStudentCourses,
        children: (courses) {
          if (courses.isEmpty) {
            return [
              const EmptyState(
                'Bạn chưa có khóa học',
                subtitle: 'Hiện tại bạn chưa được ghi danh vào khóa học nào.',
                icon: Icons.folder_open_rounded,
              ),
            ];
          }
          return courses
              .map(
                (course) => CourseProgressCard(
                  course: course,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentCourseDetailScreen(
                          course: course,
                          apiService: _apiService,
                        ),
                      ),
                    );
                  },
                ),
              )
              .toList();
        },
      ),
    );
  }
}
