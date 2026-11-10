import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import 'teacher_home_screen.dart';
import 'teacher_courses_screen.dart';
import '../notifications_screen.dart';

class TeacherMainScreen extends StatefulWidget {
  final ApiService? apiService;
  const TeacherMainScreen({super.key, this.apiService});

  @override
  State<TeacherMainScreen> createState() => _TeacherMainScreenState();
}

class _TeacherMainScreenState extends State<TeacherMainScreen> {
  late final ApiService _api = widget.apiService ?? ApiService();
  int _index = 0;
  final _visited = <int>{0};

  void _select(int index) => setState(() {
    _index = index;
    _visited.add(index);
  });

  @override
  void dispose() {
    if (widget.apiService == null) _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _index,
      children: [
        TeacherHomeScreen(apiService: _api),
        if (_visited.contains(1))
          TeacherCoursesScreen(apiService: _api)
        else
          const SizedBox.shrink(),
        if (_visited.contains(2))
          NotificationsScreen(api: _api, teacher: true)
        else
          const SizedBox.shrink(),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: _select,
      height:
          64 +
          16 * (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(0.0, 1.0),
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Trang chủ',
        ),
        NavigationDestination(
          icon: Icon(Icons.school_outlined),
          selectedIcon: Icon(Icons.school),
          label: 'Khóa học',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_outlined),
          selectedIcon: Icon(Icons.notifications),
          label: 'Thông báo',
        ),
      ],
    ),
  );
}
